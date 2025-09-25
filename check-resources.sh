#!/bin/bash

# Script para verificar recursos AWS criados na conta
# Especialmente útil para AWS Academy para evitar deixar recursos ativos
# # 16. Route53 H# 18. IAM Roles# 20. Key Pairs
check_and_display "Key Pairs" "🔐" \
    "aws ec2 describe-key-pairs --query 'KeyPairs[*].[KeyName,KeyType,CreateTime]' --output table" \
    "Key Pairs indicam possível uso de EC2"

# 21. Elastic Container Registrymizadas
check_and_display "IAM Roles Customizadas" "🔑" \
    "aws iam list-roles --query 'Roles[?!starts_with(RoleName, \`AWS\`) && !starts_with(RoleName, \`OrganizationAccountAccessRole\`) && !starts_with(RoleName, \`LabRole\`)].[RoleName,CreateDate]' --output table" \
    "Roles customizadas indicam recursos criados"

# 19. Security Groups CustomizadosZones
check_and_display "Route53 Hosted Zones" "🌍" \
    "aws route53 list-hosted-zones --query 'HostedZones[*].[Name,Id,ResourceRecordSetCount]' --output table" \
    "Hosted Zones cobram US$ 0.50/mês cada"

# 17. CloudWatch Alarms/check-resources.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 AWS Resource Checker - AWS Academy Safe${NC}"
echo "================================================"

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI não está configurado ou credenciais inválidas${NC}"
    echo -e "${YELLOW}💡 Carregue as credenciais AWS Academy:${NC}"
    echo "source aws-credentials.sh"
    exit 1
fi

# Mostrar informações da conta
ACCOUNT_INFO=$(aws sts get-caller-identity)
ACCOUNT_ID=$(echo $ACCOUNT_INFO | jq -r '.Account')
USER_ID=$(echo $ACCOUNT_INFO | jq -r '.UserId')

echo -e "${GREEN}✅ Credenciais AWS verificadas${NC}"
echo -e "${CYAN}🏢 Account ID: ${ACCOUNT_ID}${NC}"
echo -e "${CYAN}👤 User: ${USER_ID}${NC}"
echo ""

RESOURCES_FOUND=false

# Função para verificar se comando retornou resultados
check_and_display() {
    local service_name="$1"
    local icon="$2"
    local command="$3"
    local description="$4"
    
    echo -e "${YELLOW}${icon} ${service_name}:${NC}"
    
    # Executar comando e capturar output
    local output
    if output=$(eval "$command" 2>/dev/null); then
        if [ ! -z "$output" ] && [ "$output" != "None" ] && [[ ! "$output" =~ ^[[:space:]]*$ ]]; then
            echo -e "${RED}⚠️  RECURSOS ENCONTRADOS!${NC}"
            echo "$output"
            RESOURCES_FOUND=true
        else
            echo -e "${GREEN}✅ Nenhum recurso encontrado${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Erro ao verificar ou sem permissão${NC}"
    fi
    echo ""
}

echo -e "${BLUE}🔍 Verificando recursos por serviço...${NC}"
echo "========================================"

# 1. S3 Buckets
check_and_display "S3 Buckets" "🪣" \
    "aws s3 ls" \
    "Buckets S3 podem gerar custos por armazenamento"

# 2. EC2 Instances
check_and_display "EC2 Instances" "☁️" \
    "aws ec2 describe-instances --query 'Reservations[*].Instances[?State.Name!=\`terminated\`].[InstanceId,State.Name,InstanceType,PublicIpAddress]' --output table" \
    "Instâncias EC2 são os recursos mais caros"

# 3. RDS Databases
check_and_display "RDS Databases" "🗄️" \
    "aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,DBInstanceClass]' --output table" \
    "Bancos RDS podem ser muito caros"

# 4. EBS Volumes
check_and_display "EBS Volumes" "💾" \
    "aws ec2 describe-volumes --query 'Volumes[?State!=\`deleting\`].[VolumeId,State,Size,VolumeType]' --output table" \
    "Volumes EBS cobram por GB armazenado"

# 5. Elastic IPs
check_and_display "Elastic IPs" "🌐" \
    "aws ec2 describe-addresses --query 'Addresses[*].[PublicIp,AllocationId,AssociationId]' --output table" \
    "Elastic IPs não associados geram custo"

# 6. Load Balancers (ALB/NLB)
check_and_display "Load Balancers" "⚖️" \
    "aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,State.Code,Type]' --output table" \
    "Load Balancers cobram por hora"

# 7. NAT Gateways
check_and_display "NAT Gateways" "🌉" \
    "aws ec2 describe-nat-gateways --query 'NatGateways[?State!=\`deleted\`].[NatGatewayId,State,VpcId]' --output table" \
    "NAT Gateways são caros (cobram por hora + tráfego)"

# 8. VPCs Custom (não default)
check_and_display "VPCs Customizadas" "🏗️" \
    "aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==\`false\`].[VpcId,State,CidrBlock]' --output table" \
    "VPCs customizadas podem ter recursos associados"

# 9. SQS Queues
check_and_display "SQS Queues" "📨" \
    "aws sqs list-queues --output table" \
    "SQS cobra por requisições (geralmente barato)"

# 10. DynamoDB Tables
check_and_display "DynamoDB Tables" "📊" \
    "aws dynamodb list-tables --output table" \
    "DynamoDB cobra por capacidade provisionada"

# 11. Lambda Functions
check_and_display "Lambda Functions" "⚡" \
    "aws lambda list-functions --query 'Functions[*].[FunctionName,Runtime,LastModified]' --output table" \
    "Lambda cobra por execução (geralmente barato)"

# 12. CloudFormation Stacks
check_and_display "CloudFormation Stacks" "📚" \
    "aws cloudformation list-stacks --query 'StackSummaries[?StackStatus!=\`DELETE_COMPLETE\`].[StackName,StackStatus,CreationTime]' --output table" \
    "Stacks podem conter múltiplos recursos"

# 13. Auto Scaling Groups
check_and_display "Auto Scaling Groups" "📈" \
    "aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].[AutoScalingGroupName,MinSize,MaxSize,DesiredCapacity]' --output table" \
    "ASGs podem criar instâncias EC2 automaticamente"

# 14. ECS Clusters
check_and_display "ECS Clusters" "🐳" \
    "aws ecs list-clusters --output table" \
    "ECS pode ter instâncias EC2 ou Fargate em execução"

# 15. EKS Clusters  
check_and_display "EKS Clusters" "☸️" \
    "aws eks list-clusters --output table" \
    "EKS clusters são caros (instâncias EC2 para workers)"

# 16. Route53 Hosted Zones
check_and_display "Route53 Hosted Zones" "🌍" \
    "aws route53 list-hosted-zones --query 'HostedZones[*].[Name,Id,ResourceRecordSetCount]' --output table" \
    "Hosted Zones cobram US$ 0.50/mês cada"

# 17. CloudWatch Alarms
check_and_display "CloudWatch Alarms" "⏰" \
    "aws cloudwatch describe-alarms --query 'MetricAlarms[*].[AlarmName,StateValue,MetricName]' --output table" \
    "Alarms customizados podem gerar custos"

# 18. IAM Roles Customizadas
check_and_display "IAM Roles Customizadas" "🔑" \
    "aws iam list-roles --query 'Roles[?!starts_with(RoleName, \`AWS\`) && !starts_with(RoleName, \`OrganizationAccountAccessRole\`) && !starts_with(RoleName, \`LabRole\`)].[RoleName,CreateDate]' --output table" \
    "Roles customizadas indicam recursos criados"

# 19. Security Groups Customizados
check_and_display "Security Groups Customizados" "🛡️" \
    "aws ec2 describe-security-groups --query 'SecurityGroups[?GroupName!=\`default\`].[GroupId,GroupName,Description]' --output table" \
    "Security Groups indicam recursos de rede"

# 20. Key Pairs
check_and_display "Key Pairs" "🔐" \
    "aws ec2 describe-key-pairs --query 'KeyPairs[*].[KeyName,KeyType,CreateTime]' --output table" \
    "Key Pairs indicam possível uso de EC2"

# 21. Elastic Container Registry
check_and_display "ECR Repositories" "📦" \
    "aws ecr describe-repositories --query 'repositories[*].[repositoryName,createdAt,repositoryUri]' --output table" \
    "ECR cobra por armazenamento de imagens"

echo -e "${BLUE}📋 RESUMO DA VERIFICAÇÃO${NC}"
echo "========================="

if [ "$RESOURCES_FOUND" = true ]; then
    echo -e "${RED}⚠️  ATENÇÃO: Recursos foram encontrados na sua conta!${NC}"
    echo -e "${YELLOW}💰 Alguns recursos podem estar gerando custos${NC}"
    echo -e "${YELLOW}🧹 Considere executar: ./destroy.sh${NC}"
    echo -e "${YELLOW}📊 Monitore o AWS Billing Dashboard${NC}"
    echo ""
    echo -e "${CYAN}💡 Recursos mais caros para ficar de olho:${NC}"
    echo "• EC2 Instances (especialmente tipos maiores)"
    echo "• EKS Clusters (instâncias EC2 para worker nodes)"
    echo "• RDS Databases"
    echo "• NAT Gateways"
    echo "• Load Balancers"
    echo "• Elastic IPs não associados"
    echo "• EBS Volumes grandes"
    exit 1
else
    echo -e "${GREEN}✅ PERFEITO! Nenhum recurso encontrado${NC}"
    echo -e "${GREEN}💰 Sua conta está limpa - sem custos extras${NC}"
    echo -e "${GREEN}🎉 Seguro para fechar o AWS Academy${NC}"
    exit 0
fi
