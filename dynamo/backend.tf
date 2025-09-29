# Terraform Backend Configuration for S3
# 
# PREREQUISITE: Execute o módulo S3 primeiro para criar o bucket e DynamoDB:
# cd ../s3
# terraform init && terraform apply
#
# Os nomes dos recursos são definidos nas variáveis do módulo S3:
# - Bucket: terraform-state-video-processing (default)
# - DynamoDB: terraform-state-lock (default)

terraform {
  backend "s3" {
    bucket         = "terraform-state-video-processing"  # Deve corresponder à variável terraform_state_bucket_name do S3
    key            = "dynamo/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"              # Deve corresponder à variável dynamodb_table_name do S3
  }
}
