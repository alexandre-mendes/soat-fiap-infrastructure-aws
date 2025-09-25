# S3 Infrastructure for Terraform Backend and Video Processing
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.terraform_state_bucket_name
  
  tags = {
    Name        = "Terraform State Bucket"
    Environment = var.environment
    Purpose     = "Store Terraform state files"
  }
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket public access block
resource "aws_s3_bucket_public_access_block" "terraform_state_pab" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = var.environment
    Purpose     = "Lock Terraform state files"
  }
}

# S3 Bucket for Video Processing (opcional)
resource "aws_s3_bucket" "video_processing" {
  bucket = var.video_processing_bucket_name
  
  tags = {
    Name        = "Video Processing Storage"
    Environment = var.environment
    Purpose     = "Store video files for processing"
  }
}

# Video processing bucket versioning
resource "aws_s3_bucket_versioning" "video_processing_versioning" {
  bucket = aws_s3_bucket.video_processing.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Video processing bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "video_processing_encryption" {
  bucket = aws_s3_bucket.video_processing.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
