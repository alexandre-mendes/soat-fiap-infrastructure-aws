#!/bin/bash

echo "🎯 CONFIGURAÇÃO COMPLETA DO GRAFANA PARA SOAT"
echo "=============================================="

# Obter URLs
GRAFANA_URL=$(kubectl get nodes -o wide | head -2 | tail -1 | awk '{print "http://"$7":32000"}')
PROMETHEUS_URL=$(kubectl get nodes -o wide | head -2 | tail -1 | awk '{print "http://"$7":30000"}')

echo "🌐 URLs de Acesso:"
echo "   Grafana:    $GRAFANA_URL"
echo "   Prometheus: $PROMETHEUS_URL"
echo "   Login:      admin / admin123"
echo ""

# Verificar status dos serviços
echo "📊 Status dos Serviços:"
kubectl get pods -l app=grafana --no-headers | awk '{print "   Grafana:    " $3}'
kubectl get pods -l app=prometheus --no-headers | awk '{print "   Prometheus: " $3}'
echo ""

# Verificar datasource
echo "🔧 Verificando Datasource:"
DS_CHECK=$(kubectl exec deployment/grafana -- curl -s -X GET -H "Authorization: Basic YWRtaW46YWRtaW4xMjM=" http://localhost:3000/api/datasources | grep -o '"name":"Prometheus"' | wc -l)
if [ "$DS_CHECK" -gt 0 ]; then
    echo "   ✅ Prometheus datasource configurado"
else
    echo "   ❌ Prometheus datasource não encontrado"
fi

# Verificar dashboard
echo "📈 Verificando Dashboard:"
DB_CHECK=$(kubectl exec deployment/grafana -- curl -s -X GET -H "Authorization: Basic YWRtaW46YWRtaW4xMjM=" http://localhost:3000/api/search | grep -o '"title":"SOAT FIAP User Application Metrics"' | wc -l)
if [ "$DB_CHECK" -gt 0 ]; then
    echo "   ✅ Dashboard SOAT configurado"
else
    echo "   ❌ Dashboard SOAT não encontrado"
fi

# Métricas disponíveis
echo ""
echo "📊 MÉTRICAS SOAT DISPONÍVEIS NO GRAFANA:"
echo "========================================"
echo ""
echo "🔸 Métricas Principais:"
echo "   - http_requests_total{job=\"soat-fiap-user-app\"}"
echo "   - Contador total de requisições HTTP"
echo ""
echo "🔸 Labels Disponíveis:"
echo "   - job: soat-fiap-user-app"
echo "   - instance: soat-fiap-user-application-ms:80"
echo "   - method: GET, POST, PUT, DELETE"
echo "   - route: /health, /metrics, /api/..."
echo "   - status_code: 200, 404, 500, etc."
echo ""
echo "🔸 Queries Úteis para Painéis:"
echo ""
echo "1️⃣ Total de Requisições:"
echo "   sum(http_requests_total{job=\"soat-fiap-user-app\"})"
echo ""
echo "2️⃣ Taxa por Minuto:"
echo "   rate(http_requests_total{job=\"soat-fiap-user-app\"}[1m]) * 60"
echo ""
echo "3️⃣ Por Status Code:"
echo "   sum(http_requests_total{job=\"soat-fiap-user-app\"}) by (status_code)"
echo ""
echo "4️⃣ Por Rota:"
echo "   sum(http_requests_total{job=\"soat-fiap-user-app\"}) by (route)"
echo ""
echo "5️⃣ Taxa de Erro (%):"
echo "   (sum(rate(http_requests_total{job=\"soat-fiap-user-app\",status_code=~\"4..|5..\"}[5m])) / sum(rate(http_requests_total{job=\"soat-fiap-user-app\"}[5m]))) * 100"
echo ""
echo "6️⃣ Top Rotas Mais Acessadas:"
echo "   topk(5, sum(http_requests_total{job=\"soat-fiap-user-app\"}) by (route))"
echo ""
echo "🎯 PRÓXIMOS PASSOS:"
echo "=================="
echo "1. Acesse o Grafana: $GRAFANA_URL"
echo "2. Faça login com: admin / admin123"
echo "3. Navegue para: Dashboards > Browse"
echo "4. Clique em: 'SOAT FIAP User Application Metrics'"
echo "5. Customize os painéis conforme necessário"
echo ""
echo "✅ Configuração do Grafana para SOAT concluída!"