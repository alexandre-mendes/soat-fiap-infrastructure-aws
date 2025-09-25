# =================================================================
# VARIABLES - API GATEWAY
# =================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "soat-fiap"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

# EKS Cluster name (for service discovery)
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "soat-cluster"
}

# API Gateway configuration
variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "soat-fiap-api-gateway"
}

variable "enable_cors" {
  description = "Enable CORS for API Gateway"
  type        = bool
  default     = true
}

variable "cors_allow_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}

variable "cors_allow_methods" {
  description = "CORS allowed methods"
  type        = list(string)
  default     = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
}

variable "cors_allow_headers" {
  description = "CORS allowed headers"
  type        = list(string)
  default     = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"]
}

# Throttling settings
variable "throttling_rate_limit" {
  description = "API Gateway throttling rate limit"
  type        = number
  default     = 2000
}

variable "throttling_burst_limit" {
  description = "API Gateway throttling burst limit"
  type        = number
  default     = 5000
}

# Logging
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "logging_level" {
  description = "API Gateway logging level"
  type        = string
  default     = "INFO"
  
  validation {
    condition     = contains(["OFF", "ERROR", "INFO"], var.logging_level)
    error_message = "Logging level must be OFF, ERROR, or INFO."
  }
}

# Custom Domain Configuration
variable "enable_custom_domain" {
  description = "Enable custom domain for API Gateway"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Custom domain name for the API Gateway"
  type        = string
  default     = "api.soat-fiap.com"
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name (without trailing dot)"
  type        = string
  default     = "soat-fiap.com"
}

variable "create_route53_record" {
  description = "Create Route53 A record for the custom domain"
  type        = bool
  default     = true
}