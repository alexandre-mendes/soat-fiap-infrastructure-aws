# Variables for S3 module
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "terraform_state_bucket_name" {
  description = "Name for the Terraform state bucket"
  type        = string
  default     = "terraform-state-video-processing"
}

variable "video_processing_bucket_name" {
  description = "Name for the video processing bucket"
  type        = string
  default     = "video-processing-storage-fiap-x"
}

variable "dynamodb_table_name" {
  description = "Name for the DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-lock"
}
