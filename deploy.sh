#!/bin/bash

# Script para deploy completo da infraestrutura
# Executa S3 primeiro, depois SQS
# Uso: ./deploy.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploy da Infraestrutura Video Processing${NC}"
echo "=========================================="

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI não está configurado ou credenciais inválidas${NC}"
    echo -e "${YELLOW}💡 Carregue as credenciais AWS Academy:${NC}"
    echo "source aws-credentials.sh"
    exit 1
fi

echo -e "${GREEN}✅ Credenciais AWS verificadas${NC}"
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo -e "${BLUE}🏢 Account ID: ${AWS_ACCOUNT}${NC}"

echo ""
echo -e "${YELLOW}📦 FASE 1: Deploying S3 Infrastructure...${NC}"
echo "============================================"

cd s3/

# Inicializar Terraform S3
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}🔧 Inicializando Terraform S3...${NC}"
    terraform init
fi

# Planejar S3
echo -e "${YELLOW}📋 Planejando mudanças S3...${NC}"
terraform plan

# Aplicar S3
echo -e "${YELLOW}🏗️ Aplicando S3...${NC}"
terraform apply -auto-approve

echo -e "${GREEN}✅ S3 Infrastructure deployed!${NC}"

# Obter outputs do S3
echo -e "${BLUE}📤 Outputs do S3:${NC}"
terraform output

echo ""
echo -e "${YELLOW}📦 FASE 2: Deploying SQS Infrastructure...${NC}"
echo "============================================"

cd ../sqs/

# Inicializar Terraform SQS (com backend S3)
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}🔧 Inicializando Terraform SQS com backend S3...${NC}"
    terraform init
else
    echo -e "${YELLOW}🔄 Reinicializando Terraform SQS...${NC}"
    terraform init -reconfigure
fi

# Planejar SQS
echo -e "${YELLOW}📋 Planejando mudanças SQS...${NC}"
terraform plan

# Aplicar SQS
echo -e "${YELLOW}🏗️ Aplicando SQS...${NC}"
terraform apply -auto-approve

echo -e "${GREEN}✅ SQS Infrastructure deployed!${NC}"

# Obter outputs do SQS
echo -e "${BLUE}📤 Outputs do SQS:${NC}"
terraform output

echo ""
echo -e "${YELLOW}📦 FASE 3: Deploying EKS Infrastructure...${NC}"
echo "============================================"

cd ../

# Verificar se existe o diretório eks
if [ ! -d "eks" ]; then
    echo -e "${YELLOW}⚠️  Diretório eks/ não encontrado, pulando deploy EKS...${NC}"
    EKS_DEPLOYED=false
else
    # Perguntar se deseja fazer deploy do EKS
    echo ""
    read -p "Deseja fazer deploy do cluster EKS? (Y/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cd eks/
        
        echo -e "${YELLOW}🔧 Inicializando Terraform EKS...${NC}"
        terraform init
        
        echo -e "${YELLOW}📋 Planejando mudanças EKS...${NC}"
        terraform plan
        
        echo ""
        read -p "Confirma o deploy do EKS? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}🏗️ Aplicando EKS (isso pode demorar 10-15 min)...${NC}"
            terraform apply -auto-approve
            
            echo -e "${GREEN}✅ EKS Infrastructure deployed!${NC}"
            echo -e "${CYAN}📤 Outputs do EKS:${NC}"
            terraform output
            
            # Instruções kubectl
            echo ""
            echo -e "${BLUE}🔧 Para configurar kubectl:${NC}"
            CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "soat-cluster")
            echo -e "${CYAN}aws eks update-kubeconfig --region us-east-1 --name ${CLUSTER_NAME}${NC}"
            
            EKS_DEPLOYED=true
        else
            echo -e "${BLUE}✋ Deploy EKS cancelado${NC}"
            EKS_DEPLOYED=false
        fi
        
        cd ../
    else
        echo -e "${BLUE}✋ Deploy EKS pulado${NC}"
        EKS_DEPLOYED=false
    fi
fi

echo ""
echo -e "${GREEN}🎉 DEPLOY COMPLETO!${NC}"
echo "===================="
echo -e "${GREEN}✅ S3 Buckets criados${NC}"
echo -e "${GREEN}✅ DynamoDB Table criada${NC}"
echo -e "${GREEN}✅ SQS FIFO Queues criadas${NC}"
if [ "$EKS_DEPLOYED" = true ]; then
    echo -e "${GREEN}✅ EKS Cluster criado${NC}"
fi
echo -e "${GREEN}✅ Terraform State salvo no S3${NC}"

echo ""
echo -e "${BLUE}🔗 Recursos Criados:${NC}"
echo "• S3: terraform-state-video-processing"
echo "• S3: video-processing-storage" 
echo "• DynamoDB: terraform-state-lock"
echo "• SQS: video-processing-queue.fifo"
echo "• SQS: video-results-queue.fifo"
if [ "$EKS_DEPLOYED" = true ]; then
    echo "• EKS: soat-cluster"
    echo "• Node Group: fiap (t3.medium, 1-2 nodes)"
fi

echo ""
if [ "$EKS_DEPLOYED" = true ]; then
    echo -e "${BLUE}🚀 Próximos passos com EKS:${NC}"
    echo "1. Configure kubectl: aws eks update-kubeconfig --region us-east-1 --name soat-cluster"
    echo "2. Teste conectividade: kubectl get nodes"
    echo "3. Deploy aplicações: kubectl apply -f seus-manifestos.yaml"
    echo ""
fi
echo -e "${YELLOW}💡 Para destruir tudo: ./destroy.sh${NC}"
