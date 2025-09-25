#!/bin/bash

# Script para fazer deploy do stack de monitoramento (Prometheus + Grafana)
# Uso: ./deploy-monitoring.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}📊 Deploy do Stack de Monitoramento${NC}"
echo "===================================="

# Verificar se kubectl está funcionando
if ! kubectl get nodes &> /dev/null; then
    echo -e "${RED}❌ kubectl não está configurado ou cluster não está acessível${NC}"
    echo -e "${YELLOW}💡 Possíveis soluções:${NC}"
    echo "1. Carregar credenciais: source aws-credentials.sh"
    echo "2. Configurar kubectl: aws eks update-kubeconfig --region us-east-1 --name soat-cluster"
    echo "3. Criar cluster: ./deploy.sh"
    echo ""
    echo -e "${BLUE}🔍 Execute ./diagnose-monitoring.sh para diagnóstico completo${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Cluster EKS acessível${NC}"

# Mostrar informações do cluster
echo -e "${CYAN}📋 Informações do cluster:${NC}"
kubectl get nodes

echo ""
echo -e "${YELLOW}🚀 Aplicando manifestos de monitoramento...${NC}"

# Aplicar manifestos na ordem correta
echo -e "${YELLOW}1️⃣ Configurando Prometheus...${NC}"
kubectl apply -f 01-prometheus-config.yaml
kubectl apply -f 02-prometheus-rbac.yaml

# Auto-detectar nodes e criar PVs dinamicamente
echo -e "${CYAN}🔍 Detectando nodes disponíveis...${NC}"
CURRENT_NODES=($(kubectl get nodes --no-headers -o custom-columns=":metadata.name"))

if [ ${#CURRENT_NODES[@]} -lt 2 ]; then
    echo -e "${RED}❌ Precisa de pelo menos 2 nodes para o setup${NC}"
    exit 1
fi

NODE1=${CURRENT_NODES[0]}
NODE2=${CURRENT_NODES[1]}

echo -e "${CYAN}� Nodes detectados:${NC}"
echo "  - Prometheus: $NODE1"
echo "  - Grafana: $NODE2"

# Criar diretórios nos worker nodes de forma simplificada
echo -e "${YELLOW}📁 Criando diretórios de storage nos nodes...${NC}"

for node in $NODE1 $NODE2; do
    echo -e "${CYAN}📁 Criando diretórios no node: $node${NC}"
    
    # Criar pod temporário para cada node
    kubectl run temp-dir-$node-$(date +%s | tail -c 6) \
        --image=busybox:1.35 \
        --rm -i --restart=Never \
        --overrides='{"spec":{"nodeName":"'$node'","hostPID":true,"containers":[{"name":"temp","image":"busybox:1.35","command":["/bin/sh","-c","mkdir -p /host/tmp/prometheus-data /host/tmp/grafana-data && chmod 777 /host/tmp/prometheus-data /host/tmp/grafana-data && echo Done"],"securityContext":{"privileged":true},"volumeMounts":[{"name":"host","mountPath":"/host"}]}],"volumes":[{"name":"host","hostPath":{"path":"/"}}]}}' \
        -- sleep 1 2>/dev/null || echo -e "${YELLOW}⚠️ Diretório pode já existir no $node${NC}"
done

echo -e "${GREEN}✅ Diretórios criados/verificados${NC}"

# Remover PVs antigos se existirem
kubectl delete pv prometheus-local-pv grafana-local-pv 2>/dev/null || true

# Criar PVs dinamicamente com nodes atuais
echo -e "${YELLOW}�️  Criando PVs com nodes atuais...${NC}"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus-local-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /tmp/prometheus-data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - $NODE1
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: grafana-local-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /tmp/grafana-data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - $NODE2
EOF

# Aplicar PVCs
echo -e "${YELLOW}📦 Criando PVCs...${NC}"
kubectl apply -f 07-local-storage.yaml

echo -e "${YELLOW}⏳ PVCs criados (binding será feito quando pods iniciarem)${NC}"
kubectl get pvc

echo -e "${GREEN}✅ PVCs criados com sucesso${NC}"

echo -e "${YELLOW}3️⃣ Finalizando deploy do Prometheus...${NC}"
kubectl apply -f 03-prometheus-deployment.yaml

echo -e "${YELLOW}4️⃣ Configurando Grafana...${NC}"
kubectl apply -f 04-grafana-datasource-config.yaml
kubectl apply -f 05-grafana-deployment.yaml

echo -e "${YELLOW}5️⃣ Configurando Node Exporter...${NC}"
kubectl apply -f 06-node-exporter.yaml

echo ""
echo -e "${GREEN}✅ Stack de monitoramento deployado!${NC}"

echo ""
echo -e "${YELLOW}🔧 Configurando acesso externo...${NC}"

# Obter security group dos worker nodes
WORKER_SG=$(aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].SecurityGroups[0].GroupId' --output text | head -1)

if [ ! -z "$WORKER_SG" ]; then
    echo -e "${CYAN}📋 Security Group dos worker nodes: $WORKER_SG${NC}"
    
    # Verificar e adicionar regra para Prometheus (porta 30000)
    if ! aws ec2 describe-security-groups --group-ids "$WORKER_SG" --query 'SecurityGroups[0].IpPermissions[?FromPort==`30000`]' --output text | grep -q 30000; then
        echo -e "${YELLOW}🔧 Adicionando regra para Prometheus (porta 30000)...${NC}"
        aws ec2 authorize-security-group-ingress --group-id "$WORKER_SG" --protocol tcp --port 30000 --cidr 0.0.0.0/0 &> /dev/null || echo -e "${YELLOW}⚠️  Regra já existe${NC}"
    else
        echo -e "${GREEN}✅ Regra para Prometheus já existe${NC}"
    fi
    
    # Verificar e adicionar regra para Grafana (porta 32000)
    if ! aws ec2 describe-security-groups --group-ids "$WORKER_SG" --query 'SecurityGroups[0].IpPermissions[?FromPort==`32000`]' --output text | grep -q 32000; then
        echo -e "${YELLOW}🔧 Adicionando regra para Grafana (porta 32000)...${NC}"
        aws ec2 authorize-security-group-ingress --group-id "$WORKER_SG" --protocol tcp --port 32000 --cidr 0.0.0.0/0 &> /dev/null || echo -e "${YELLOW}⚠️  Regra já existe${NC}"
    else
        echo -e "${GREEN}✅ Regra para Grafana já existe${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Não foi possível detectar o security group automaticamente${NC}"
    echo -e "${YELLOW}💡 Configure manualmente se necessário:${NC}"
    echo "aws ec2 authorize-security-group-ingress --group-id <SG-ID> --protocol tcp --port 30000-32000 --cidr 0.0.0.0/0"
fi

echo ""
echo -e "${YELLOW}⏳ Aguardando pods ficarem prontos...${NC}"
kubectl wait --for=condition=ready pod -l app=prometheus --timeout=300s
kubectl wait --for=condition=ready pod -l app=grafana --timeout=300s

echo ""
echo -e "${GREEN}🎉 DEPLOY COMPLETO!${NC}"
echo "==================="

# Mostrar status dos pods
echo -e "${CYAN}📋 Status dos pods:${NC}"
kubectl get pods -o wide

echo ""
echo -e "${CYAN}📋 Services disponíveis:${NC}"
kubectl get services

echo ""
echo -e "${BLUE}🌐 Acesso às interfaces:${NC}"
echo ""

# Obter IPs externos dos worker nodes
NODE_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}')
if [ -z "$NODE_IPS" ]; then
    NODE_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
fi

echo -e "${GREEN}🔍 Prometheus:${NC}"
for ip in $NODE_IPS; do
    echo "  http://$ip:30000"
done

echo ""
echo -e "${GREEN}📊 Grafana:${NC}"
for ip in $NODE_IPS; do
    echo "  http://$ip:32000"
done
echo -e "${YELLOW}  User: admin${NC}"
echo -e "${YELLOW}  Password: admin123${NC}"

echo ""
echo -e "${BLUE}💡 Comandos úteis:${NC}"
echo "• Ver logs do Prometheus: kubectl logs -f deployment/prometheus -n monitoring"
echo "• Ver logs do Grafana: kubectl logs -f deployment/grafana -n monitoring"
echo "• Ver pods: kubectl get pods -n monitoring"
echo "• Acessar pod: kubectl exec -it <pod-name> -n monitoring -- /bin/sh"

echo ""
echo -e "${GREEN}🚀 Stack de monitoramento pronto para uso!${NC}"
