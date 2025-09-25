#!/bin/bash

echo "🗑️  DESTRUINDO API GATEWAY SOAT FIAP"
echo "===================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Verificar se estamos no diretório correto
if [ ! -f "main.tf" ]; then
    error "Arquivo main.tf não encontrado. Execute o script do diretório api-gateway/"
    exit 1
fi

log "Verificando recursos existentes..."

# Verificar se há recursos criados
if [ ! -f "terraform.tfstate" ]; then
    warning "Nenhum state do Terraform encontrado. Recursos podem não existir."
else
    log "State do Terraform encontrado. Listando recursos..."
    terraform show -json | jq -r '.values.root_module.resources[].address' 2>/dev/null || echo "  (Não foi possível listar recursos)"
fi

echo ""
warning "⚠️  ATENÇÃO: Esta ação irá DESTRUIR os seguintes recursos na AWS:"
echo ""
echo "  🗑️  API Gateway: soat-fiap-api-gateway"
echo "  🗑️  Integrações HTTP_PROXY"
echo "  🗑️  Rotas configuradas"
echo "  🗑️  Stage de deployment"
echo "  🗑️  CloudWatch Log Group"
echo ""
warning "💰 Isso pode interromper serviços em produção!"
echo ""

# Pergunta de confirmação
read -p "Tem certeza que deseja DESTRUIR todos os recursos? (yes/NO): " -r
echo ""

if [[ ! "$REPLY" == "yes" ]]; then
    log "Operação cancelada pelo usuário. Nenhum recurso foi destruído."
    exit 0
fi

log "Iniciando destruição dos recursos..."

# Executar terraform destroy
terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo ""
    success "✅ Todos os recursos foram destruídos com sucesso!"
    echo ""
    log "Recursos removidos:"
    echo "  ✅ API Gateway excluído"
    echo "  ✅ Integrações removidas"
    echo "  ✅ Rotas excluídas"
    echo "  ✅ CloudWatch Logs removidos"
    echo ""
    log "💡 Os microserviços no EKS continuam funcionando normalmente."
    log "💡 Você pode recriar o API Gateway executando './deploy.sh'"
else
    echo ""
    error "❌ Erro durante a destruição dos recursos!"
    echo ""
    log "Possíveis soluções:"
    echo "  1. Verifique as credenciais AWS"
    echo "  2. Execute 'terraform destroy' manualmente"
    echo "  3. Verifique o console da AWS para recursos restantes"
fi

echo ""
log "Script de destruição concluído."