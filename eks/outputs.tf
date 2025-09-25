# Outputs para o módulo EKS

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.eks-cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.eks-cluster.endpoint
}

output "cluster_security_group_id" {
  description = "ID do Security Group do cluster"
  value       = aws_security_group.sg.id
}

output "cluster_arn" {
  description = "ARN do cluster EKS"
  value       = aws_eks_cluster.eks-cluster.arn
}

output "cluster_certificate_authority_data" {
  description = "Dados do certificado de autoridade do cluster"
  value       = aws_eks_cluster.eks-cluster.certificate_authority[0].data
}

output "cluster_version" {
  description = "Versão do Kubernetes do cluster"
  value       = aws_eks_cluster.eks-cluster.version
}

output "node_group_arn" {
  description = "ARN do Node Group"
  value       = aws_eks_node_group.eks-node.arn
}

output "node_group_status" {
  description = "Status do Node Group"
  value       = aws_eks_node_group.eks-node.status
}

# Comandos para configurar kubectl
output "kubectl_config_command" {
  description = "Comando para configurar kubectl"
  value       = "aws eks update-kubeconfig --region ${var.regionDefault} --name ${aws_eks_cluster.eks-cluster.name}"
}

# Informações de conectividade
output "vpc_id" {
  description = "ID da VPC usada"
  value       = data.aws_vpc.vpc.id
}

output "subnet_ids" {
  description = "IDs das subnets usadas"
  value       = [for subnet in data.aws_subnet.subnet : subnet.id if subnet.availability_zone != "${var.regionDefault}e"]
}
