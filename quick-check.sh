#!/bin/bash

# Script rápido para verificar recursos básicos AWS
# Foco nos recursos mais comuns que geram custo
# Uso: ./quick-check.sh

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}⚡ Quick AWS Resource Check${NC}"
echo "============================"

# Verificar credenciais
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI não configurado${NC}"
    exit 1
fi

FOUND=false

# S3 Buckets
echo -n -e "${YELLOW}🪣 S3 Buckets: ${NC}"
if aws s3 ls 2>/dev/null | grep -q .; then
    echo -e "${RED}ENCONTRADOS${NC}"
    aws s3 ls
    FOUND=true
else
    echo -e "${GREEN}OK${NC}"
fi

# EC2 Instances
echo -n -e "${YELLOW}☁️  EC2 Instances: ${NC}"
INSTANCES=$(aws ec2 describe-instances --query 'Reservations[*].Instances[?State.Name!=`terminated`].InstanceId' --output text 2>/dev/null)
if [ ! -z "$INSTANCES" ]; then
    echo -e "${RED}ENCONTRADAS${NC}"
    aws ec2 describe-instances --query 'Reservations[*].Instances[?State.Name!=`terminated`].[InstanceId,State.Name,InstanceType]' --output table
    FOUND=true
else
    echo -e "${GREEN}OK${NC}"
fi

# SQS Queues
echo -n -e "${YELLOW}📨 SQS Queues: ${NC}"
if aws sqs list-queues 2>/dev/null | grep -q QueueUrls; then
    echo -e "${RED}ENCONTRADAS${NC}"
    aws sqs list-queues --output table
    FOUND=true
else
    echo -e "${GREEN}OK${NC}"
fi

# DynamoDB Tables
echo -n -e "${YELLOW}📊 DynamoDB Tables: ${NC}"
if aws dynamodb list-tables 2>/dev/null | grep -q TableNames; then
    echo -e "${RED}ENCONTRADAS${NC}"
    aws dynamodb list-tables --output table
    FOUND=true
else
    echo -e "${GREEN}OK${NC}"
fi

# RDS Instances
echo -n -e "${YELLOW}🗄️  RDS Databases: ${NC}"
if aws rds describe-db-instances --query 'DBInstances[0].DBInstanceIdentifier' --output text 2>/dev/null | grep -v None; then
    echo -e "${RED}ENCONTRADAS${NC}"
    aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]' --output table
    FOUND=true
else
    echo -e "${GREEN}OK${NC}"
fi

# Load Balancers
echo -n -e "${YELLOW}⚖️  Load Balancers: ${NC}"
if aws elbv2 describe-load-balancers --query 'LoadBalancers[0].LoadBalancerName' --output text 2>/dev/null | grep -v None; then
    echo -e "${RED}ENCONTRADOS${NC}"
    aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,State.Code]' --output table
    FOUND=true
else
    echo -e "${GREEN}OK${NC}"
fi

# EKS Clusters
echo -n -e "${YELLOW}☸️  EKS Clusters: ${NC}"
if aws eks list-clusters --query 'clusters[0]' --output text 2>/dev/null | grep -v None; then
    echo -e "${RED}ENCONTRADOS${NC}"
    aws eks list-clusters --output table
    FOUND=true
else
    echo -e "${GREEN}OK${NC}"
fi

echo ""
if [ "$FOUND" = true ]; then
    echo -e "${RED}⚠️  RECURSOS ENCONTRADOS! Execute ./destroy.sh${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Conta limpa! Nenhum recurso encontrado${NC}"
    exit 0
fi
