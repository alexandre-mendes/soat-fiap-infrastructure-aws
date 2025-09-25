#!/bin/bash

# Script para diagnosticar problemas no deploy do monitoring
# Uso: ./diagnose-monitoring.sh

set +e  # Não para em erros para fazer diagnóstico completo

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔍 Diagnóstico do Ambiente de Monitoramento${NC}"
echo "============================================="

# 1. Verificar credenciais AWS
echo -e "${YELLOW}1️⃣ Verificando credenciais AWS...${NC}"
if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo -e "${GREEN}✅ Credenciais AWS válidas - Account: ${ACCOUNT_ID}${NC}"
    AWS_OK=true
else
    echo -e "${RED}❌ Credenciais AWS inválidas ou expiradas${NC}"
    echo -e "${YELLOW}💡 Solução: source aws-credentials.sh${NC}"
    AWS_OK=false
fi

echo ""

# 2. Verificar se cluster EKS existe
echo -e "${YELLOW}2️⃣ Verificando cluster EKS...${NC}"
if [ "$AWS_OK" = true ]; then
    if aws eks describe-cluster --name soat-cluster &> /dev/null; then
        CLUSTER_STATUS=$(aws eks describe-cluster --name soat-cluster --query cluster.status --output text)
        echo -e "${GREEN}✅ Cluster EKS existe - Status: ${CLUSTER_STATUS}${NC}"
        EKS_EXISTS=true
    else
        echo -e "${RED}❌ Cluster EKS 'soat-cluster' não encontrado${NC}"
        echo -e "${YELLOW}💡 Solução: ./deploy.sh${NC}"
        EKS_EXISTS=false
    fi
else
    echo -e "${YELLOW}⚠️  Não foi possível verificar EKS (credenciais inválidas)${NC}"
    EKS_EXISTS=false
fi

echo ""

# 3. Verificar configuração kubectl
echo -e "${YELLOW}3️⃣ Verificando configuração kubectl...${NC}"
if kubectl version --client &> /dev/null; then
    echo -e "${GREEN}✅ kubectl instalado${NC}"
    
    if kubectl get nodes &> /dev/null; then
        NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
        echo -e "${GREEN}✅ kubectl configurado - ${NODE_COUNT} nodes disponíveis${NC}"
        KUBECTL_OK=true
    else
        echo -e "${RED}❌ kubectl não consegue conectar ao cluster${NC}"
        if [ "$EKS_EXISTS" = true ]; then
            echo -e "${YELLOW}💡 Solução: aws eks update-kubeconfig --region us-east-1 --name soat-cluster${NC}"
        fi
        KUBECTL_OK=false
    fi
else
    echo -e "${RED}❌ kubectl não está instalado${NC}"
    KUBECTL_OK=false
fi

echo ""

# 4. Verificar namespace monitoring
echo -e "${YELLOW}4️⃣ Verificando namespace monitoring...${NC}"
if [ "$KUBECTL_OK" = true ]; then
    if kubectl get namespace monitoring &> /dev/null; then
        echo -e "${GREEN}✅ Namespace monitoring existe${NC}"
        NAMESPACE_EXISTS=true
    else
        echo -e "${YELLOW}⚠️  Namespace monitoring não existe${NC}"
        echo -e "${YELLOW}💡 Será criado no próximo deploy${NC}"
        NAMESPACE_EXISTS=false
    fi
else
    echo -e "${YELLOW}⚠️  Não foi possível verificar namespace (kubectl não configurado)${NC}"
    NAMESPACE_EXISTS=false
fi

echo ""

# 5. Verificar recursos do monitoring se namespace existir
if [ "$NAMESPACE_EXISTS" = true ]; then
    echo -e "${YELLOW}5️⃣ Verificando recursos do monitoring...${NC}"
    
    # PVCs
    PVC_COUNT=$(kubectl get pvc -n monitoring --no-headers 2>/dev/null | wc -l)
    if [ $PVC_COUNT -gt 0 ]; then
        echo -e "${GREEN}✅ ${PVC_COUNT} PVC(s) encontrado(s):${NC}"
        kubectl get pvc -n monitoring 2>/dev/null
    else
        echo -e "${YELLOW}⚠️  Nenhum PVC encontrado${NC}"
    fi
    
    echo ""
    
    # Pods
    POD_COUNT=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | wc -l)
    if [ $POD_COUNT -gt 0 ]; then
        echo -e "${GREEN}✅ ${POD_COUNT} Pod(s) encontrado(s):${NC}"
        kubectl get pods -n monitoring 2>/dev/null
    else
        echo -e "${YELLOW}⚠️  Nenhum pod encontrado${NC}"
    fi
else
    echo -e "${YELLOW}5️⃣ Pulando verificação de recursos (namespace não existe)${NC}"
fi

echo ""

# 6. Verificar arquivos de manifesto
echo -e "${YELLOW}6️⃣ Verificando arquivos de manifesto...${NC}"
MANIFEST_DIR="/home/alexandre/Área de Trabalho/hacka/infra-aws/k8s-monitoring"

if [ -d "$MANIFEST_DIR" ]; then
    echo -e "${GREEN}✅ Diretório k8s-monitoring encontrado${NC}"
    
    REQUIRED_FILES=(
        "00-namespace.yaml"
        "07-local-storage.yaml"
        "01-prometheus-config.yaml"
        "02-prometheus-rbac.yaml"
        "03-prometheus-deployment.yaml"
        "04-grafana-datasource-config.yaml"
        "05-grafana-deployment.yaml"
        "06-node-exporter.yaml"
        "08-create-dirs.yaml"
    )
    
    MISSING_FILES=()
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$MANIFEST_DIR/$file" ]; then
            echo -e "${GREEN}  ✅ $file${NC}"
        else
            echo -e "${RED}  ❌ $file${NC}"
            MISSING_FILES+=("$file")
        fi
    done
    
    if [ ${#MISSING_FILES[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ Todos os manifestos estão presentes${NC}"
        MANIFESTS_OK=true
    else
        echo -e "${RED}❌ ${#MISSING_FILES[@]} arquivo(s) ausente(s)${NC}"
        MANIFESTS_OK=false
    fi
else
    echo -e "${RED}❌ Diretório k8s-monitoring não encontrado${NC}"
    MANIFESTS_OK=false
fi

echo ""

# 7. Verificar configuração de security group (se possível)
echo -e "${YELLOW}7️⃣ Verificando acesso externo...${NC}"
if [ "$AWS_OK" = true ]; then
    WORKER_SG=$(aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].SecurityGroups[0].GroupId' --output text 2>/dev/null | head -1)
    
    if [ ! -z "$WORKER_SG" ] && [ "$WORKER_SG" != "None" ]; then
        echo -e "${GREEN}✅ Security Group encontrado: $WORKER_SG${NC}"
        
        # Verificar regras para as portas do monitoramento
        HAS_30000=$(aws ec2 describe-security-groups --group-ids "$WORKER_SG" --query 'SecurityGroups[0].IpPermissions[?FromPort==`30000`]' --output text 2>/dev/null)
        HAS_32000=$(aws ec2 describe-security-groups --group-ids "$WORKER_SG" --query 'SecurityGroups[0].IpPermissions[?FromPort==`32000`]' --output text 2>/dev/null)
        
        if [ ! -z "$HAS_30000" ]; then
            echo -e "  ${GREEN}✅ Porta 30000 (Prometheus) liberada${NC}"
        else
            echo -e "  ${YELLOW}⚠️  Porta 30000 (Prometheus) não liberada${NC}"
        fi
        
        if [ ! -z "$HAS_32000" ]; then
            echo -e "  ${GREEN}✅ Porta 32000 (Grafana) liberada${NC}"
        else
            echo -e "  ${YELLOW}⚠️  Porta 32000 (Grafana) não liberada${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Security Group dos worker nodes não detectado${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Credenciais AWS necessárias para verificar security groups${NC}"
fi

echo ""
echo -e "${BLUE}📋 RESUMO DO DIAGNÓSTICO${NC}"
echo "========================"

if [ "$AWS_OK" = true ]; then
    echo -e "${GREEN}✅ Credenciais AWS${NC}"
else
    echo -e "${RED}❌ Credenciais AWS${NC}"
fi

if [ "$EKS_EXISTS" = true ]; then
    echo -e "${GREEN}✅ Cluster EKS${NC}"
else
    echo -e "${RED}❌ Cluster EKS${NC}"
fi

if [ "$KUBECTL_OK" = true ]; then
    echo -e "${GREEN}✅ kubectl${NC}"
else
    echo -e "${RED}❌ kubectl${NC}"
fi

if [ "$MANIFESTS_OK" = true ]; then
    echo -e "${GREEN}✅ Manifestos${NC}"
else
    echo -e "${RED}❌ Manifestos${NC}"
fi

echo ""
echo -e "${BLUE}🛠️  PLANO DE CORREÇÃO${NC}"
echo "===================="

if [ "$AWS_OK" = false ]; then
    echo -e "${YELLOW}1. Carregar credenciais AWS Academy:${NC}"
    echo "   source aws-credentials.sh"
    echo ""
fi

if [ "$EKS_EXISTS" = false ] && [ "$AWS_OK" = true ]; then
    echo -e "${YELLOW}2. Criar cluster EKS:${NC}"
    echo "   ./deploy.sh"
    echo ""
fi

if [ "$KUBECTL_OK" = false ] && [ "$EKS_EXISTS" = true ]; then
    echo -e "${YELLOW}3. Configurar kubectl:${NC}"
    echo "   aws eks update-kubeconfig --region us-east-1 --name soat-cluster"
    echo ""
fi

if [ "$MANIFESTS_OK" = true ] && [ "$KUBECTL_OK" = true ]; then
    echo -e "${YELLOW}4. Deploy do monitoring:${NC}"
    echo "   ./deploy-monitoring.sh"
    echo ""
fi

# Verificar se tudo está pronto
if [ "$AWS_OK" = true ] && [ "$EKS_EXISTS" = true ] && [ "$KUBECTL_OK" = true ] && [ "$MANIFESTS_OK" = true ]; then
    echo -e "${GREEN}🎉 Tudo pronto para deploy do monitoring!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Correções necessárias antes do deploy${NC}"
    exit 1
fi
