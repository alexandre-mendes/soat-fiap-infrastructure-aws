#!/bin/bash

echo "🌐 DEPLOY DO API GATEWAY SOAT FIAP"
echo "=================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar se estamos no diretório correto
if [ ! -f "main.tf" ]; then
    error "Arquivo main.tf não encontrado. Execute o script do diretório api-gateway/"
    exit 1
fi

log "Verificando pré-requisitos..."

# Verificar se kubectl está funcionando
if ! kubectl cluster-info &> /dev/null; then
    error "Kubernetes cluster não acessível. Verifique sua configuração do kubectl."
    exit 1
fi

# Verificar se os serviços SOAT estão rodando
log "Verificando serviços SOAT no EKS..."

USER_MS=$(kubectl get service soat-fiap-user-application-ms --no-headers 2>/dev/null | wc -l)
PROCESS_MS=$(kubectl get service soat-fiap-process-manager-application-ms --no-headers 2>/dev/null | wc -l)

if [ "$USER_MS" -eq 0 ]; then
    error "Serviço soat-fiap-user-application-ms não encontrado no EKS"
    exit 1
fi

if [ "$PROCESS_MS" -eq 0 ]; then
    error "Serviço soat-fiap-process-manager-application-ms não encontrado no EKS"
    exit 1
fi

success "Serviços SOAT encontrados no EKS ✓"

# Mostrar informações dos serviços
log "Informações dos serviços:"
kubectl get services | grep soat | while read line; do
    echo "  📋 $line"
done

# Verificar credenciais AWS
log "Verificando credenciais AWS..."
if ! aws sts get-caller-identity &> /dev/null; then
    error "Credenciais AWS não configuradas ou inválidas"
    exit 1
fi

success "Credenciais AWS válidas ✓"

# Inicializar Terraform se necessário
if [ ! -d ".terraform" ]; then
    log "Inicializando Terraform..."
    terraform init
    if [ $? -ne 0 ]; then
        error "Falha na inicialização do Terraform"
        exit 1
    fi
fi

# Executar terraform plan
log "Executando terraform plan..."
terraform plan -out=tfplan
if [ $? -ne 0 ]; then
    error "Falha no terraform plan"
    exit 1
fi

# Perguntar confirmação
echo ""
warning "⚠️  ATENÇÃO: Isso irá criar recursos na AWS que podem gerar custos."
read -p "Deseja prosseguir com o deploy? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Deploy cancelado pelo usuário"
    exit 0
fi

# Aplicar terraform
log "Aplicando configuração do Terraform..."
terraform apply tfplan
if [ $? -ne 0 ]; then
    error "Falha no terraform apply"
    exit 1
fi

# Obter outputs
log "Obtendo informações do API Gateway criado..."
echo ""
success "🎉 API Gateway criado com sucesso!"
echo ""

echo "📋 INFORMAÇÕES DO API GATEWAY:"
echo "=============================="
echo ""

API_URL=$(terraform output -raw api_gateway_url 2>/dev/null)
if [ ! -z "$API_URL" ]; then
    echo "🌐 URL Principal: $API_URL"
else
    echo "❌ Não foi possível obter a URL do API Gateway"
fi

echo ""
echo "📡 ENDPOINTS DISPONÍVEIS:"
echo "========================"
terraform output user_ms_endpoint 2>/dev/null && echo "   └── Microserviço de Usuários"
terraform output process_manager_ms_endpoint 2>/dev/null && echo "   └── Microserviço de Processos"
terraform output user_health_endpoint 2>/dev/null && echo "   └── Health Check - Usuários"
terraform output process_health_endpoint 2>/dev/null && echo "   └── Health Check - Processos"

echo ""
echo "🔍 TESTES RÁPIDOS:"
echo "=================="
if [ ! -z "$API_URL" ]; then
    echo "# Testar health checks:"
    echo "curl $API_URL/health/users"
    echo "curl $API_URL/health/process"
    echo ""
    echo "# Testar APIs:"
    echo "curl $API_URL/api/users"
    echo "curl $API_URL/api/process"
fi

echo ""
echo "📊 MONITORAMENTO:"
echo "================"
echo "CloudWatch Logs: /aws/apigateway/soat-fiap-api"
echo "AWS Console: https://console.aws.amazon.com/apigateway/"

echo ""
success "✅ Deploy do API Gateway concluído com sucesso!"
warning "💡 Lembre-se: Os recursos criados na AWS podem gerar custos."

# Limpar arquivo de plan
rm -f tfplan