# Video Processing Infrastructure

Infraestrutura completa para processamento de vídeo usando Terraform na AWS.

## 📁 Estrutura do Projeto

```
infra-aws/
├── aws-credentials.sh    # Credenciais AWS Academy
├── deploy.sh            # 🚀 Deploy completo (S3 → SQS)
├── destroy.sh           # 🗑️ Destroy completo (SQS → S3)
├── check-resources.sh   # 🔍 Verificação completa de recursos AWS
├── quick-check.sh       # ⚡ Verificação rápida de recursos AWS
├── s3/                  # Módulo S3 (buckets + DynamoDB)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
└── sqs/                 # Módulo SQS (filas FIFO)
    ├── main.tf
    ├── backend.tf       # Backend S3 sempre habilitado
    ├── variables.tf
    ├── outputs.tf
    └── README.md
```

## 🚀 Como Usar

### Deploy Completo (Recomendado)

```bash
# 1. Carregar credenciais AWS Academy
source aws-credentials.sh

# 2. Deploy tudo automaticamente
./deploy.sh
```

### Deploy Manual (Passo a Passo)

```bash
# 1. Deploy S3 Infrastructure
cd s3/
terraform init
terraform apply

# 2. Deploy SQS Infrastructure  
cd ../sqs/
terraform init
terraform apply
```

### Destroy Completo

```bash
# Destrói tudo na ordem correta
./destroy.sh
```

### ⚡ Verificação de Recursos AWS Academy

Para garantir que não esqueceu nenhum recurso criado (importante para AWS Academy):

```bash
# Verificação completa (20+ serviços AWS)
./check-resources.sh

# Verificação rápida (recursos principais)  
./quick-check.sh
```

**💰 Por que verificar?**
- AWS Academy tem limites de crédito
- Recursos esquecidos podem consumir créditos
- Alguns recursos (EC2, RDS, NAT Gateway) são caros
- Load balancers cobram por hora mesmo sem uso

## 📦 Recursos Criados

### 🏗️ **S3 Module:**
- `terraform-state-video-processing` - Bucket para Terraform state (configurável)
- `video-processing-storage` - Bucket para arquivos de vídeo (configurável)
- `terraform-state-lock` - Tabela DynamoDB para state locking (configurável)

### 🎯 **SQS Module:**
- `video-processing-queue.fifo` - Fila para tarefas de processamento
- `video-results-queue.fifo` - Fila para resultados do processamento

## ⚙️ Configuração Personalizada

### Nomes Personalizados dos Recursos

Você pode personalizar os nomes dos recursos S3:

```bash
# Método 1: Variáveis na linha de comando
cd s3/
terraform apply \
  -var="terraform_state_bucket_name=meu-projeto-terraform-state" \
  -var="video_processing_bucket_name=meu-projeto-video-storage" \
  -var="dynamodb_table_name=meu-projeto-state-lock"

# Método 2: Arquivo terraform.tfvars
cat > s3/terraform.tfvars << EOF
terraform_state_bucket_name = "meu-projeto-terraform-state"
video_processing_bucket_name = "meu-projeto-video-storage"
dynamodb_table_name = "meu-projeto-state-lock"
EOF

terraform apply
```

**⚠️ IMPORTANTE:** Se você personalizar os nomes, também deve atualizar o `sqs/backend.tf` com os nomes correspondentes.

## ⚡ Scripts Automáticos

### `./deploy.sh`
- ✅ Verifica credenciais AWS
- ✅ Deploy S3 infrastructure primeiro
- ✅ Deploy SQS infrastructure depois
- ✅ Configura backend S3 automaticamente
- ✅ Mostra todos os outputs

### `./destroy.sh`
- ✅ Confirmação interativa
- ✅ Destroy SQS infrastructure primeiro
- ✅ Remove S3 buckets manualmente (incluindo versões)
- ✅ Remove DynamoDB table
- ✅ Limpa arquivos .terraform locais
- ✅ Oferece verificação final de recursos

### `./check-resources.sh`
- 🔍 Verifica 20+ serviços AWS
- 💰 Identifica recursos que geram custo
- 📊 Output detalhado de todos os recursos
- ⚠️ Alerta sobre recursos caros (EC2, RDS, etc.)
- ✅ Confirma se a conta está limpa

### `./quick-check.sh`
- ⚡ Verificação rápida dos principais recursos
- 🎯 Foco em S3, EC2, SQS, DynamoDB, RDS
- ✅ Ideal para check rápido antes de fechar AWS Academy

## 🔧 Requisitos

- AWS CLI configurado
- Terraform instalado
- Credenciais AWS Academy válidas

## 💡 Workflow Recomendado

```bash
# Setup inicial
source aws-credentials.sh
./deploy.sh

# Trabalho normal
cd sqs/
terraform plan
terraform apply

# Limpeza final
./destroy.sh
```

## 🏷️ Tags Padrão

Todos os recursos são criados com tags:
- `Environment`: dev (configurável)
- `Name`: Nome do recurso
- `Purpose`: Descrição da finalidade

## 🔒 Segurança

- ✅ S3 buckets com acesso público bloqueado
- ✅ Criptografia AES256 habilitada
- ✅ Versionamento habilitado para backup
- ✅ State locking com DynamoDB

## 📝 Logs

Os scripts mostram logs coloridos para fácil acompanhamento:
- 🔵 Informações
- 🟡 Avisos
- 🟢 Sucessos
- 🔴 Erros
