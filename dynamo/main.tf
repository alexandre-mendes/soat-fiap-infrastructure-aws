# DynamoDB Table for User and Process Data

resource "aws_dynamodb_table" "users" {
  name           = "user"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = {
    Name        = "soat-fiap-users"
    Environment = var.environment
    Purpose     = "User data storage"
  }
}

resource "aws_dynamodb_table" "processes" {
  name           = "process"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "processId"

  attribute {
    name = "processId"
    type = "S"
  }

  tags = {
    Name        = "soat-fiap-processes"
    Environment = var.environment
    Purpose     = "Process data storage"
  }
}
