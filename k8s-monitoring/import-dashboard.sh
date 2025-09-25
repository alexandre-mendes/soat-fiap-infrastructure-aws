#!/bin/bash

echo "📊 Importando dashboard SOAT para o Grafana..."

# Importar o dashboard via API
kubectl exec deployment/grafana -- curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YWRtaW46YWRtaW4xMjM=" \
  -d "$(cat soat-dashboard.json)" \
  http://localhost:3000/api/dashboards/db

echo -e "\n✅ Dashboard SOAT importado com sucesso!"

# Listar dashboards disponíveis
echo "📋 Dashboards disponíveis:"
kubectl exec deployment/grafana -- curl -s -X GET \
  -H "Authorization: Basic YWRtaW46YWRtaW4xMjM=" \
  http://localhost:3000/api/search | grep -o '"title":"[^"]*"' | head -5