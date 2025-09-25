# S3 Infrastructure Module

Este módulo Terraform cria a infraestrutura S3 necessária para o projeto de processamento de vídeo, incluindo buckets para Terraform state e armazenamento de vídeos.

## Recursos Criados

### 🔒 **Backend Infrastructure:**
- **S3 Bucket**: Para armazenar Terraform state
- **DynamoDB Table**: Para state locking
- **Encryption**: AES256 habilitada
- **Versioning**: Habilitado para backup
- **Public Access**: Bloqueado

### 🎬 **Video Processing:**
- **S3 Bucket**: Para armazenar arquivos de vídeo
- **Encryption**: AES256 habilitada
- **Versioning**: Habilitado

## Características

- **Nomes fixos**: Nomes simples e previsíveis
- **Segurança**: Criptografia e acesso público bloqueado
- **Backup**: Versionamento habilitado
- **Cost-effective**: DynamoDB pay-per-request

## Como Usar

### 1. Primeira Execução (Criar S3)
```bash
cd s3/
terraform init
terraform apply
```

### 2. Personalizar Nomes (Opcional)
```bash
# Usando variáveis customizadas
terraform apply \
  -var="terraform_state_bucket_name=my-custom-terraform-state" \
  -var="video_processing_bucket_name=my-custom-video-storage" \
  -var="dynamodb_table_name=my-custom-state-lock"

# Ou criar arquivo terraform.tfvars
echo 'terraform_state_bucket_name = "my-custom-terraform-state"' > terraform.tfvars
echo 'video_processing_bucket_name = "my-custom-video-storage"' >> terraform.tfvars
echo 'dynamodb_table_name = "my-custom-state-lock"' >> terraform.tfvars
terraform apply
```

### 3. Obter o Nome do Bucket
```bash
terraform output terraform_state_bucket_name
# terraform-state-video-processing (ou nome personalizado)
```

## Estrutura do Projeto

```
infra-aws/
├── s3/           # 👈 Módulo S3 (execute PRIMEIRO)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
└── sqs/          # Módulo SQS (execute DEPOIS)
    ├── main.tf
    ├── backend.tf  # Configure com output do S3
    └── ...
```

## Workflow Recomendado

1. **Deploy S3**: `cd s3 && terraform apply`
2. **Get bucket name**: `terraform output terraform_state_bucket_name`
3. **Update SQS backend**: Usar o nome do bucket no `sqs/backend.tf`
4. **Deploy SQS**: `cd ../sqs && terraform init && terraform apply`

## Outputs

- `terraform_state_bucket_name`: Nome do bucket para Terraform state
- `dynamodb_table_name`: Nome da tabela DynamoDB
- `video_processing_bucket_name`: Nome do bucket para vídeos
- `backend_config`: Configuração formatada para backend

## Limpeza

```bash
terraform destroy
```

**Importante**: Execute este comando apenas quando não houver states de outros módulos no bucket!
