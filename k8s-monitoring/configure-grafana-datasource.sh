#!/bin/bash

echo "🔧 Configurando Prometheus como datasource no Grafana..."

# Obter o IP interno do Prometheus
PROMETHEUS_SERVICE=$(kubectl get svc prometheus-service -o jsonpath='{.spec.clusterIP}')
echo "📡 Prometheus Service IP: $PROMETHEUS_SERVICE"

# Configurar datasource via API
kubectl exec deployment/grafana -- curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YWRtaW46YWRtaW4xMjM=" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://'$PROMETHEUS_SERVICE':8080",
    "access": "proxy",
    "isDefault": true,
    "basicAuth": false
  }' \
  http://localhost:3000/api/datasources

echo -e "\n✅ Datasource configurado!"

# Verificar se foi criado
echo "🔍 Verificando datasources disponíveis:"
kubectl exec deployment/grafana -- curl -s -X GET \
  -H "Authorization: Basic YWRtaW46YWRtaW4xMjM=" \
  http://localhost:3000/api/datasources | grep -o '"name":"[^"]*"' || echo "❌ Erro ao verificar"