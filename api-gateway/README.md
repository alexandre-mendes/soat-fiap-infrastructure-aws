# 🌐 API Gateway SOAT FIAP

AWS API Gateway V2 (HTTP API) que integra microserviços EKS com endpoints RESTful.

## 🚀 Quick Start

```bash
# Deploy
./deploy.sh

# Destroy (cuidado!)
./destroy.sh
```

## 📊 Outputs

```bash
# URL principal
terraform output api_gateway_url

# Todos os endpoints
terraform output
```

## 🎯 URL Final

**Endpoint base:** `https://npe6dadkeb.execute-api.us-east-1.amazonaws.com`

**Principais endpoints:**
- Login: `/api/auth/login`
- Users: `/api/users`
- Process Manager: `/api/process-manager`
- Health: `/health`

## 🏗️ Arquitetura

- **Backend S3**: State em `s3://terraform-state-video-processing/api-gateway/`
- **Lock DynamoDB**: `terraform-state-lock`
- **Integração EKS**: HTTP_PROXY para Load Balancers
- **CORS**: Habilitado para frontend

## ⚙️ Configuração

Edite `terraform.tfvars` para personalizar domínio, CORS, throttling, etc.

**Estado:** ✅ Produção - URL fixa para frontend