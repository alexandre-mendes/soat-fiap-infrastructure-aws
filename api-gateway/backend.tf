terraform {
  backend "s3" {
    bucket         = "terraform-state-video-processing"
    key            = "api-gateway/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}