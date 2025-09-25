# SQS Video Processing FIFO Queues

Este módulo Terraform cria filas SQS FIFO para processamento de vídeo na AWS.

## Recursos Criados

- **video-processing-queue.fifo**: Fila FIFO principal para tarefas de processamento de vídeo
- **video-results-queue.fifo**: Fila FIFO para resultados do processamento de vídeo

## Características das Filas FIFO

- **Ordem Garantida**: Mensagens são processadas na ordem exata que foram enviadas
- **Deduplicação**: Evita mensagens duplicadas automaticamente
- **Content-Based Deduplication**: Habilitada para identificar duplicatas pelo conteúdo
- **Alta Throughput**: Até 3.000 mensagens por segundo com batching

## Configuração

### Variáveis

- `environment`: Nome do ambiente (dev, staging, prod). Padrão: "dev"
- `tags`: Tags adicionais para aplicar aos recursos. Padrão: {}

### Exemplo de Uso

```hcl
module "sqs_queues" {
  source = "./sqs"
  
  environment = "production"
  
  tags = {
    Project = "video-processing"
    Team    = "backend"
  }
}
```

## Configurações das Filas FIFO

- **Tipo**: FIFO (First-In-First-Out)
- **Retenção de mensagens**: 14 dias
- **Timeout de visibilidade**: 5 minutos
- **Tamanho máximo da mensagem**: 256 KB
- **Deduplicação**: Content-based habilitada
- **Throughput**: Até 3.000 mensagens/segundo

## Como Usar

### ⚠️ **PREREQUISITE: Execute o módulo S3 primeiro**

```bash
# 1. Criar infraestrutura S3 (uma vez só)
cd ../s3
source ../aws-credentials.sh
terraform init
terraform apply

# 2. Obter o nome do bucket criado
terraform output terraform_state_bucket_name
# Output: terraform-state-video-processing-a1b2c3d4

# 3. Atualizar backend.tf com o nome do bucket
cd ../sqs
# Editar backend.tf e substituir o bucket name
```

### 🚀 **Uso Normal (SQS)**

```bash
cd sqs/
source ../aws-credentials.sh
terraform init    # Backend S3 sempre habilitado
terraform plan
terraform apply
```

### Uso Normal

1. Execute `terraform plan` para revisar as mudanças
2. Execute `terraform apply` para criar os recursos

### Estrutura de Arquivos

- `main.tf`: Recursos principais das filas SQS FIFO
- `variables.tf`: Variáveis configuráveis
- `outputs.tf`: Saídas do módulo
- `backend.tf`: Configuração do backend S3 (sempre habilitado)
- `bootstrap.tf.backup`: Arquivo de bootstrap antigo (não usado)

## Outputs

- URLs e ARNs das filas FIFO principais
- Nomes das filas para referência

## Vantagens das Filas FIFO

- **Ordem Preservada**: Ideal para processamento sequencial de vídeos
- **Sem Duplicatas**: Evita reprocessamento desnecessário
- **Consistência**: Garante que os resultados sejam processados na ordem correta
- **Reliability**: Alta disponibilidade e durabilidade das mensagens
