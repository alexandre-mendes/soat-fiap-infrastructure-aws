#!/bin/bash

echo "🎯 Criando queries úteis para monitoramento SOAT..."

# Função para executar query no Prometheus
query_prometheus() {
    local query="$1"
    local description="$2"
    echo "📊 $description"
    kubectl exec deployment/prometheus -- wget -qO- "http://localhost:9090/api/v1/query?query=$query" | grep -o '"value":\[[^]]*\]' | head -3
    echo ""
}

echo "=== QUERIES DISPONÍVEIS PARA GRAFANA ==="
echo ""

# 1. Total de requisições HTTP
echo "🔸 Total de requisições HTTP:"
echo "Query: sum(http_requests_total{job=\"soat-fiap-user-app\"})"
query_prometheus "sum(http_requests_total{job=\"soat-fiap-user-app\"})" "Total requests"

# 2. Taxa de requisições por minuto
echo "🔸 Taxa de requisições por minuto:"
echo "Query: rate(http_requests_total{job=\"soat-fiap-user-app\"}[1m]) * 60"

# 3. Requisições por status code
echo "🔸 Requisições por status code:"
echo "Query: sum(http_requests_total{job=\"soat-fiap-user-app\"}) by (status_code)"
query_prometheus "sum(http_requests_total{job=\"soat-fiap-user-app\"})%20by%20(status_code)" "By status code"

# 4. Requisições por rota
echo "🔸 Requisições por rota:"
echo "Query: sum(http_requests_total{job=\"soat-fiap-user-app\"}) by (route)"
query_prometheus "sum(http_requests_total{job=\"soat-fiap-user-app\"})%20by%20(route)" "By route"

# 5. Percentual de erro (status 4xx e 5xx)
echo "🔸 Taxa de erro (%):"
echo "Query: (sum(rate(http_requests_total{job=\"soat-fiap-user-app\",status_code=~\"4..|5..\"}[5m])) / sum(rate(http_requests_total{job=\"soat-fiap-user-app\"}[5m]))) * 100"

echo "=== INSTRUÇÕES PARA USO NO GRAFANA ==="
echo ""
echo "1. Acesse: http://3.208.73.113:32000"
echo "2. Login: admin / admin123"
echo "3. Vá em Dashboards > Browse"
echo "4. Clique em 'SOAT FIAP User Application Metrics'"
echo "5. Ou crie novos painéis usando as queries acima"
echo ""
echo "📈 Métricas disponíveis:"
echo "  - http_requests_total: Contador total de requisições HTTP"
echo "  - Labels: job, instance, method, route, status_code"
echo ""