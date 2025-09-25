#!/bin/bash

# Script para configurar o backend S3 do Terraform
# Uso: ./setup_backend.sh

set -e

echo "🚀 Configurando backend S3 para Terraform..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI não está configurado ou credenciais inválidas${NC}"
    echo "Configure suas credenciais AWS primeiro:"
    echo "aws configure"
    exit 1
fi

echo -e "${GREEN}✅ Credenciais AWS verificadas${NC}"

# Passo 1: Inicializar Terraform
echo -e "${YELLOW}📦 Inicializando Terraform...${NC}"
terraform init

# Passo 2: Criar bucket S3 e tabela DynamoDB
echo -e "${YELLOW}🪣 Criando bucket S3 e tabela DynamoDB...${NC}"
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_state_lock -auto-approve

# Passo 3: Habilitar backend S3
echo -e "${YELLOW}🔄 Habilitando backend S3...${NC}"
# Descomenta a configuração do backend
sed -i 's/^# terraform {/terraform {/' backend.tf
sed -i 's/^#   backend/  backend/' backend.tf
sed -i 's/^#     bucket/    bucket/' backend.tf
sed -i 's/^#     key/    key/' backend.tf
sed -i 's/^#     region/    region/' backend.tf
sed -i 's/^#     encrypt/    encrypt/' backend.tf
sed -i 's/^#     dynamodb_table/    dynamodb_table/' backend.tf
sed -i 's/^#   }/  }/' backend.tf
sed -i 's/^# }/}/' backend.tf

# Passo 4: Migrar state para S3
echo -e "${YELLOW}📤 Migrando state para S3...${NC}"
echo "yes" | terraform init -migrate-state

# Passo 5: Limpeza (opcional)
echo -e "${YELLOW}🧹 Removendo arquivo bootstrap...${NC}"
if [ -f "bootstrap.tf" ]; then
    mv bootstrap.tf bootstrap.tf.bak
    echo -e "${GREEN}✅ bootstrap.tf movido para bootstrap.tf.bak${NC}"
fi

echo -e "${GREEN}🎉 Backend S3 configurado com sucesso!${NC}"
echo -e "${GREEN}📍 State salvo em: s3://terraform-state-video-processing/sqs/terraform.tfstate${NC}"
echo -e "${GREEN}🔒 Lock table: terraform-state-lock${NC}"

# Verificar configuração
echo -e "${YELLOW}🔍 Verificando configuração...${NC}"
terraform plan

echo -e "${GREEN}✅ Configuração concluída! Agora você pode usar 'terraform apply' normalmente.${NC}"
