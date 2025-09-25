# Outputs for S3 module
output "terraform_state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_state_lock.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_state_lock.arn
}

output "video_processing_bucket_name" {
  description = "Name of the S3 bucket for video processing"
  value       = aws_s3_bucket.video_processing.bucket
}

output "video_processing_bucket_arn" {
  description = "ARN of the S3 bucket for video processing"
  value       = aws_s3_bucket.video_processing.arn
}

# Output formatted for backend configuration
output "backend_config" {
  description = "Backend configuration values for other modules"
  value = {
    bucket         = aws_s3_bucket.terraform_state.bucket
    region         = "us-east-1"
    dynamodb_table = aws_dynamodb_table.terraform_state_lock.name
  }
}
