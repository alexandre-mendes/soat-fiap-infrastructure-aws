# 🎬 SOAT FIAP Infrastructure AWS

Este projeto provisiona toda a infraestrutura necessária para o sistema de processamento de vídeos do FIAP X, utilizando recursos gerenciados na AWS e automação via Terraform.

## 📚 Visão Geral

O sistema é composto por microsserviços que permitem o upload, processamento, acompanhamento e download de vídeos e frames. A arquitetura é escalável, resiliente e utiliza boas práticas de mensageria, monitoramento e CI/CD.

## 🚀 Recursos Criados na AWS

- **Amazon API Gateway**: Ponto único de entrada para as APIs dos microsserviços, realizando roteamento das requisições.
- **Amazon EKS (Kubernetes)**: Orquestração dos microsserviços, Prometheus e Grafana, com escalabilidade automática.
- **Amazon SQS**: Fila de mensagens para orquestrar o processamento assíncrono dos vídeos.
- **Amazon S3**: Armazenamento dos vídeos originais e arquivos zipados dos frames extraídos.
- **Amazon DynamoDB**: Banco NoSQL para persistência de dados dos usuários e status dos vídeos.
- **Prometheus & Grafana**: Coleta e visualização de métricas dos microsserviços e infraestrutura.
- **GitHub Actions**: Pipeline de CI/CD para build, testes, análise de qualidade e deploy automatizado.

## 🧩 Estrutura do Projeto

- `api-gateway/` - Infraestrutura do API Gateway
- `eks/` - Cluster EKS e recursos Kubernetes
- `dynamo/` - Tabelas DynamoDB
- `s3/` - Buckets S3
- `sqs/` - Filas SQS
- `k8s-monitoring/` - Configuração de Prometheus e Grafana
- `doc/` - Diagramas e imagens da arquitetura

## ⚡ Como usar

1. Configure suas credenciais AWS.
2. Ajuste os arquivos de variáveis conforme necessário.
3. Execute os scripts Terraform em cada módulo para provisionar os recursos.
4. Realize o deploy dos microsserviços no EKS.

## 📊 Monitoramento

O sistema conta com monitoramento em tempo real via Prometheus e Grafana, além de logs centralizados no CloudWatch.
---

> Para detalhes completos da arquitetura, consulte o arquivo `ARQUITETURA.md`.
