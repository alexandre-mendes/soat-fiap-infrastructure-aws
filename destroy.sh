#!/bin/bash

# Script para destruir toda a infraestrutura
# Executa destroy do SQS primeiro, depois remove S3 manualmente
# Uso: ./destroy.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🗑️  Destroy da Infraestrutura Video Processing${NC}"
echo "================================================"

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI não está configurado ou credenciais inválidas${NC}"
    echo -e "${YELLOW}💡 Carregue as credenciais AWS Academy:${NC}"
    echo "source aws-credentials.sh"
    exit 1
fi

echo -e "${GREEN}✅ Credenciais AWS verificadas${NC}"

# Confirmação
echo -e "${YELLOW}⚠️  ATENÇÃO: Isso irá destruir TODA a infraestrutura!${NC}"
echo "Recursos que serão removidos:"
echo "• EKS Cluster (se existir)"
echo "• SQS Queues (video-processing-queue.fifo, video-results-queue.fifo)"
echo "• S3 Buckets (terraform-state-video-processing, video-processing-storage)"
echo "• DynamoDB Table (terraform-state-lock)"
echo ""
read -p "Tem certeza que deseja continuar? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}✋ Operação cancelada${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}🗑️  FASE 1: Destroying EKS Infrastructure...${NC}"
echo "=============================================="

# Verificar se existe EKS para destruir
if [ -d "eks" ] && [ -d "eks/.terraform" ]; then
    echo -e "${YELLOW}🔧 Destruindo EKS Cluster...${NC}"
    cd eks/
    terraform destroy -auto-approve
    echo -e "${GREEN}✅ EKS Infrastructure destroyed!${NC}"
    cd ../
else
    echo -e "${YELLOW}⚠️  EKS não encontrado ou não inicializado, pulando...${NC}"
fi

echo ""
echo -e "${YELLOW}🗑️  FASE 2: Destroying SQS Infrastructure...${NC}"
echo "=============================================="

cd sqs/

# Verificar se existe terraform state
if [ -d ".terraform" ]; then
    echo -e "${YELLOW}🔧 Destruindo SQS...${NC}"
    terraform destroy -auto-approve
    echo -e "${GREEN}✅ SQS Infrastructure destroyed!${NC}"
else
    echo -e "${YELLOW}⚠️  Terraform SQS não inicializado, pulando...${NC}"
fi

echo ""
echo -e "${YELLOW}🗑️  FASE 3: Removing S3 Buckets Manually...${NC}"
echo "=============================================="

cd ../

# Função para esvaziar e deletar bucket S3
delete_s3_bucket() {
    local bucket_name=$1
    echo -e "${YELLOW}🪣 Processando bucket: ${bucket_name}${NC}"
    
    # Verificar se bucket existe
    if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        echo -e "${YELLOW}📤 Esvaziando bucket ${bucket_name}...${NC}"
        
        # Remover todas as versões dos objetos
        aws s3api list-object-versions --bucket "$bucket_name" \
            --query 'Versions[].{Key:Key,VersionId:VersionId}' \
            --output text | while read key version; do
                if [ ! -z "$key" ] && [ ! -z "$version" ]; then
                    aws s3api delete-object --bucket "$bucket_name" --key "$key" --version-id "$version" >/dev/null
                fi
            done
        
        # Remover delete markers
        aws s3api list-object-versions --bucket "$bucket_name" \
            --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' \
            --output text | while read key version; do
                if [ ! -z "$key" ] && [ ! -z "$version" ]; then
                    aws s3api delete-object --bucket "$bucket_name" --key "$key" --version-id "$version" >/dev/null
                fi
            done
        
        # Deletar bucket
        echo -e "${YELLOW}🗑️  Deletando bucket ${bucket_name}...${NC}"
        aws s3api delete-bucket --bucket "$bucket_name"
        echo -e "${GREEN}✅ Bucket ${bucket_name} deletado!${NC}"
    else
        echo -e "${YELLOW}⚠️  Bucket ${bucket_name} não existe, pulando...${NC}"
    fi
}

# Obter nomes reais dos buckets a partir dos outputs do módulo S3
echo -e "${YELLOW}🔍 Obtendo nomes reais dos recursos do módulo S3...${NC}"
cd s3/

# Verificar se existe terraform state no S3
if [ -d ".terraform" ]; then
    TERRAFORM_STATE_BUCKET=$(terraform output -raw terraform_state_bucket_name 2>/dev/null || echo "terraform-state-video-processing")
    VIDEO_PROCESSING_BUCKET=$(terraform output -raw video_processing_bucket_name 2>/dev/null || echo "video-processing-storage")
    DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name 2>/dev/null || echo "terraform-state-lock")
else
    # Usar valores padrão se não conseguir obter outputs
    TERRAFORM_STATE_BUCKET="terraform-state-video-processing"
    VIDEO_PROCESSING_BUCKET="video-processing-storage"
    DYNAMODB_TABLE="terraform-state-lock"
fi

echo -e "${BLUE}📋 Recursos identificados:${NC}"
echo "• S3 State Bucket: ${TERRAFORM_STATE_BUCKET}"
echo "• S3 Video Bucket: ${VIDEO_PROCESSING_BUCKET}" 
echo "• DynamoDB Table: ${DYNAMODB_TABLE}"

cd ../

# Deletar buckets S3 usando nomes reais
delete_s3_bucket "$TERRAFORM_STATE_BUCKET"
delete_s3_bucket "$VIDEO_PROCESSING_BUCKET"

echo ""
echo -e "${YELLOW}🗑️  FASE 4: Removing DynamoDB Table...${NC}"
echo "======================================"

# Deletar tabela DynamoDB usando nome real
TABLE_NAME="$DYNAMODB_TABLE"
if aws dynamodb describe-table --table-name "$TABLE_NAME" &>/dev/null; then
    echo -e "${YELLOW}🗄️  Deletando tabela DynamoDB ${TABLE_NAME}...${NC}"
    aws dynamodb delete-table --table-name "$TABLE_NAME" >/dev/null
    echo -e "${GREEN}✅ Tabela ${TABLE_NAME} deletada!${NC}"
else
    echo -e "${YELLOW}⚠️  Tabela ${TABLE_NAME} não existe, pulando...${NC}"
fi

echo ""
echo -e "${YELLOW}🧹 FASE 5: Limpeza Local...${NC}"
echo "=========================="

# Limpar arquivos locais do terraform
echo -e "${YELLOW}🧹 Removendo arquivos .terraform locais...${NC}"
rm -rf s3/.terraform s3/.terraform.lock.hcl s3/terraform.tfstate*
rm -rf sqs/.terraform sqs/.terraform.lock.hcl sqs/terraform.tfstate*
rm -rf eks/.terraform eks/.terraform.lock.hcl eks/terraform.tfstate*

echo -e "${GREEN}✅ Arquivos locais limpos!${NC}"

echo ""
echo -e "${GREEN}🎉 DESTROY COMPLETO!${NC}"
echo "===================="
echo -e "${GREEN}✅ EKS Cluster removido${NC}"
echo -e "${GREEN}✅ SQS Queues removidas${NC}"
echo -e "${GREEN}✅ S3 Buckets removidos (incluindo versões)${NC}"
echo -e "${GREEN}✅ DynamoDB Table removida${NC}"
echo -e "${GREEN}✅ Arquivos locais limpos${NC}"

echo ""
echo -e "${BLUE}� Verificação final de recursos...${NC}"
echo ""
read -p "Deseja executar verificação completa de recursos? (Y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}🔍 Executando verificação final...${NC}"
    if [ -f "./check-resources.sh" ]; then
        ./check-resources.sh
    else
        echo -e "${YELLOW}⚠️  Script check-resources.sh não encontrado${NC}"
        echo -e "${BLUE}💡 Verificação manual recomendada:${NC}"
        echo "• aws s3 ls"
        echo "• aws sqs list-queues"
        echo "• aws dynamodb list-tables"
        echo "• aws ec2 describe-instances"
    fi
else
    echo -e "${BLUE}💡 Para verificar recursos: ./check-resources.sh${NC}"
fi

echo ""
echo -e "${BLUE}�💡 Para fazer novo deploy: ./deploy.sh${NC}"
