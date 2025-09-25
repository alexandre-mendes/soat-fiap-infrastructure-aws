# 📊 Guia de Armazenamento - Grafana e Prometheus no EKS

## 🎯 **Onde fica o armazenamento?**

### **❌ Configuração Anterior (Temporária)**
```yaml
volumes:
- name: prometheus-storage-volume
  emptyDir: {}  # Dados perdidos ao reiniciar
- name: grafana-pv  
  emptyDir: {}  # Dashboards perdidos ao reiniciar
```

### **✅ Nova Configuração (Persistente)**
```yaml
volumes:
- name: prometheus-storage-volume
  persistentVolumeClaim:
    claimName: prometheus-pvc  # EBS Volume 20GB
- name: grafana-pv
  persistentVolumeClaim:
    claimName: grafana-pvc     # EBS Volume 10GB
```

## 🛠️ **Como funciona o armazenamento persistente**

### **1. PersistentVolumeClaim (PVC)**
- Solicita armazenamento ao cluster
- Define tamanho e tipo de acesso
- Kubernetes provisiona automaticamente

### **2. EBS Volumes (AWS)**
- Volumes de disco anexados aos worker nodes
- **Persistem** mesmo quando pods reiniciam
- **Backup automático** via snapshots AWS
- **Performance** SSD (gp2)

### **3. Mapeamento de Diretórios**

| Serviço    | Diretório no Container | Volume EBS | Dados Armazenados |
|------------|------------------------|------------|-------------------|
| Prometheus | `/prometheus/`         | 20GB       | Métricas, índices, WAL |
| Grafana    | `/var/lib/grafana`     | 10GB       | Dashboards, usuários, configs |

## 💰 **Custos do Armazenamento**

### **EBS gp2 Pricing (us-east-1)**
- **Prometheus**: 20GB × $0.10/GB-mês = **$2.00/mês**
- **Grafana**: 10GB × $0.10/GB-mês = **$1.00/mês**
- **Total**: **$3.00/mês** (~$0.10/dia)

### **Comparação de Custos**
```
📊 Armazenamento EBS:   $3.00/mês
☁️  Instâncias EC2:     ~$130/mês (2x t3.medium)
🎛️  EKS Control Plane:  $73/mês

💡 Armazenamento = apenas 2% do custo total
```

## 🔧 **Vantagens do Armazenamento Persistente**

### **✅ Para Prometheus:**
- **Métricas históricas** preservadas (até 200h de retenção)
- **Continuidade** de alertas e análises
- **Performance** melhor em consultas históricas
- **Backup** automático via snapshots EBS

### **✅ Para Grafana:**
- **Dashboards customizados** não são perdidos
- **Configurações de usuário** preservadas
- **Data sources** mantêm configuração
- **Alerting rules** persistem

## 🚀 **Alternativas de Armazenamento**

### **Opção 1: EBS (Atual)**
```yaml
storageClassName: gp2
accessModes: [ReadWriteOnce]
```
- ✅ **Simples** e automático
- ✅ **Backup** nativo AWS
- ❌ **Limitado** a uma AZ

### **Opção 2: EFS (Para multi-AZ)**
```yaml
storageClassName: efs
accessModes: [ReadWriteMany]
```
- ✅ **Multi-AZ** disponibilidade
- ✅ **Compartilhamento** entre pods
- ❌ **Mais caro** (~$0.30/GB-mês)
- ❌ **Performance** menor que EBS

### **Opção 3: S3 (Para dados históricos)**
```yaml
# Configuração no Prometheus
- '--storage.tsdb.path=/prometheus/'
- '--storage.tsdb.retention.time=48h'  # Retenção local curta
```
- ✅ **Custo baixo** para long-term storage
- ✅ **Durabilidade** 99.999999999%
- ❌ **Complexidade** adicional
- ❌ **Latência** maior para queries

## 📋 **Checklist de Deploy**

- [ ] 1. Criar namespace monitoring
- [ ] 2. Aplicar PVCs (07-persistent-volumes.yaml)
- [ ] 3. Aguardar volumes serem bound
- [ ] 4. Deploy Prometheus com volume persistente
- [ ] 5. Deploy Grafana com volume persistente
- [ ] 6. Verificar pods em execução
- [ ] 7. Testar acesso aos dados após restart

## 🔍 **Como verificar o armazenamento**

```bash
# Verificar PVCs
kubectl get pvc -n monitoring

# Verificar volumes EBS
kubectl get pv

# Ver uso de espaço dentro dos pods
kubectl exec -n monitoring deployment/prometheus -- df -h /prometheus
kubectl exec -n monitoring deployment/grafana -- df -h /var/lib/grafana

# Listar volumes EBS na AWS
aws ec2 describe-volumes --filters "Name=tag:kubernetes.io/created-for/pvc/name,Values=prometheus-pvc"
```

## 💡 **Dicas de Produção**

1. **Snapshots regulares** dos volumes EBS
2. **Monitorar uso** de espaço em disco
3. **Configurar alertas** para espaço baixo
4. **Considerar retention** adequada para métricas
5. **Backup** dos dashboards Grafana via API

---

**🎯 Resultado Final:**
- Dados persistem entre restarts de pods
- Métricas históricas preservadas
- Dashboards customizados salvos
- Custo adicional mínimo ($3/mês)
- Deploy mais robusto para produção
