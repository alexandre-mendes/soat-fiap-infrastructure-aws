# 📊 Monitoramento EKS - Prometheus + Grafana

Este projeto implementa uma stack completa de monitoramento para clusters Amazon EKS usando Prometheus, Grafana e Node Exporter.

## 🎯 **Visão Geral**

O stack inclui:
- **Prometheus**: Coleta e armazena métricas
- **Grafana**: Visualização e dashboards  
- **Node Exporter**: Métricas dos worker nodes
- **Storage Local**: Solução compatível com AWS Academy

## 🚀 **Setup Rápido**

```bash
# 1. Navegar para o diretório
cd k8s-monitoring

# 2. Executar setup automático
./quick-setup.sh
```

## 📋 **Pré-requisitos**

- ✅ AWS CLI configurado
- ✅ kubectl instalado
- ✅ Cluster EKS ativo (soat-cluster)
- ✅ Credenciais AWS Academy válidas

## 🛠️ **Scripts Disponíveis**

### **Setup e Deploy**
- `quick-setup.sh` - Setup completo automatizado
- `deploy-monitoring.sh` - Deploy do stack de monitoramento
- `diagnose-monitoring.sh` - Diagnóstico completo do ambiente

### **Manutenção**
- `cleanup-monitoring.sh` - Remove todos os recursos
- `check-ebs.sh` - Verifica volumes de storage

## 📁 **Estrutura dos Arquivos**

### **Manifestos Kubernetes**
- `00-namespace.yaml` - Namespace monitoring
- `08-local-storage.yaml` - Volumes persistentes locais
- `01-prometheus-config.yaml` - Configuração do Prometheus
- `02-prometheus-rbac.yaml` - Permissões RBAC
- `03-prometheus-deployment.yaml` - Deploy do Prometheus
- `04-grafana-datasource-config.yaml` - DataSource do Grafana
- `05-grafana-deployment.yaml` - Deploy do Grafana
- `06-node-exporter.yaml` - DaemonSet Node Exporter
- `09-create-dirs.yaml` - Criação de diretórios (temporário)

### **Arquivos de Referência**
- `07-persistent-volumes-ebs-reference.yaml` - PVCs EBS (não funciona no AWS Academy)

## 🌐 **Acesso às Interfaces**

Após o deploy, acesse via NodePort:

**📊 Grafana**
- URL: `http://<node-ip>:32000`
- User: `admin`
- Password: `admin123`

**🔍 Prometheus**  
- URL: `http://<node-ip>:30000`

> **IPs dos Nodes**: Execute `kubectl get nodes -o wide` para obter os External IPs

## ⚙️ **Configurações Importantes**

### **Storage**
- Usa volumes locais (`/tmp/prometheus-data`, `/tmp/grafana-data`)
- Compatível com AWS Academy (não requer IAM especial)
- Dados persistem enquanto os nodes existirem

### **Security Groups**
- O script de deploy configura automaticamente:
  - Porta 30000 (Prometheus)
  - Porta 32000 (Grafana)

### **Métricas Coletadas**
- Métricas dos containers (cAdvisor)
- Métricas do sistema (Node Exporter)
- Métricas do cluster (API Server, CoreDNS)
- Métricas das aplicações (pods anotados)

## 🔧 **Troubleshooting**

### **Problema: Pods Pending**
```bash
# Verificar PVCs
kubectl get pvc -n monitoring

# Verificar eventos
kubectl describe pod <pod-name> -n monitoring
```

### **Problema: Sem acesso externo**
```bash
# Verificar security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Adicionar regras manualmente
aws ec2 authorize-security-group-ingress --group-id <sg-id> --protocol tcp --port 30000-32000 --cidr 0.0.0.0/0
```

### **Problema: Credenciais expiradas**
```bash
# Recarregar credenciais
cd ../
source aws-credentials.sh

# Reconfigurar kubectl
aws eks update-kubeconfig --region us-east-1 --name soat-cluster
```

## 📚 **Comandos Úteis**

```bash
# Verificar pods
kubectl get pods -n monitoring -o wide

# Ver logs
kubectl logs -f deployment/prometheus -n monitoring
kubectl logs -f deployment/grafana -n monitoring

# Acessar pod
kubectl exec -it <pod-name> -n monitoring -- /bin/sh

# Verificar métricas
curl http://<node-ip>:30000/api/v1/targets

# Port forward (alternativa)
kubectl port-forward -n monitoring deployment/grafana 3000:3000
```

## 🎨 **Personalização**

### **Adicionar Dashboards no Grafana**
1. Acesse Grafana (admin/admin123)
2. Import dashboard via ID ou JSON
3. Configure datasource como "Prometheus"

### **Modificar Configuração do Prometheus**
Edite `01-prometheus-config.yaml` e execute:
```bash
kubectl apply -f 01-prometheus-config.yaml
kubectl rollout restart deployment/prometheus -n monitoring
```

## 🚨 **Limitações AWS Academy**

- ❌ EBS CSI driver sem permissões IAM
- ❌ Load Balancers limitados
- ✅ NodePort funciona perfeitamente
- ✅ Volumes locais como alternativa

## 🧹 **Limpeza**

Para remover completamente o stack:
```bash
./cleanup-monitoring.sh
```

## 📞 **Suporte**

Para problemas ou dúvidas:
1. Execute `./diagnose-monitoring.sh`
2. Verifique logs dos pods
3. Confirme security groups
4. Valide credenciais AWS

---

**Desenvolvido para AWS Academy - FIAP 2024** 🎓
