#!/bin/bash

# Script para limpar recursos do monitoramento em caso de erro
# Uso: ./cleanup-monitoring.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧹 Limpeza dos Recursos de Monitoramento${NC}"
echo "========================================"

# Verificar se kubectl está funcionando
if ! kubectl get nodes &> /dev/null; then
    echo -e "${RED}❌ kubectl não está configurado${NC}"
    echo -e "${YELLOW}💡 Configure: aws eks update-kubeconfig --region us-east-1 --name soat-cluster${NC}"
    exit 1
fi

# Verificar se recursos existem no namespace default
echo -e "${YELLOW}🔍 Recursos encontrados no namespace default:${NC}"
kubectl get all -l app=prometheus || echo "Nenhum recurso Prometheus encontrado"
kubectl get all -l app=grafana || echo "Nenhum recurso Grafana encontrado"
kubectl get all -l app=node-exporter || echo "Nenhum recurso Node Exporter encontrado"

echo ""
read -p "Tem certeza que deseja remover TODOS os recursos de monitoramento? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}✋ Operação cancelada${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}🗑️  Removendo deployments e services...${NC}"
kubectl delete deployment prometheus grafana 2>/dev/null || echo "Nenhum deployment para remover"
kubectl delete service prometheus-service grafana node-exporter 2>/dev/null || echo "Nenhum service para remover"
kubectl delete daemonset node-exporter 2>/dev/null || echo "Nenhum daemonset para remover"

echo -e "${YELLOW}🗑️  Removendo configmaps...${NC}"
kubectl delete configmap prometheus-config grafana-datasources 2>/dev/null || echo "Nenhum configmap para remover"

echo -e "${YELLOW}🗑️  Removendo RBAC...${NC}"
kubectl delete clusterrolebinding prometheus 2>/dev/null || echo "ClusterRoleBinding prometheus não existe"
kubectl delete clusterrole prometheus 2>/dev/null || echo "ClusterRole prometheus não existe"
kubectl delete serviceaccount prometheus 2>/dev/null || echo "ServiceAccount prometheus não existe"

echo -e "${YELLOW}🗑️  Removendo PVCs...${NC}"
kubectl delete pvc prometheus-storage grafana-storage 2>/dev/null || echo "Nenhum PVC para remover"

echo -e "${YELLOW}🗑️  Removendo PVs locais...${NC}"
kubectl delete pv prometheus-local-pv grafana-local-pv 2>/dev/null || echo "Nenhum PV local para remover"

echo ""
echo -e "${GREEN}✅ Limpeza concluída!${NC}"
echo ""
echo -e "${YELLOW}💡 Para fazer novo deploy:${NC}"
echo "./deploy-monitoring.sh"

echo ""
echo -e "${BLUE}📋 Verificação final - recursos no namespace default:${NC}"
kubectl get pods,svc,pvc -l app=prometheus || echo "✅ Nenhum recurso Prometheus encontrado"
kubectl get pods,svc,pvc -l app=grafana || echo "✅ Nenhum recurso Grafana encontrado"
