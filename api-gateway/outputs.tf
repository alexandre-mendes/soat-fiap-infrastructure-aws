# =================================================================
# OUTPUTS - API GATEWAY
# =================================================================

output "api_gateway_url" {
  description = "The URL of the API Gateway"
  value       = aws_apigatewayv2_api.soat_api.api_endpoint
}

output "api_gateway_id" {
  description = "The ID of the API Gateway"
  value       = aws_apigatewayv2_api.soat_api.id
}

output "api_gateway_arn" {
  description = "The ARN of the API Gateway"
  value       = aws_apigatewayv2_api.soat_api.arn
}

output "api_gateway_execution_arn" {
  description = "The execution ARN of the API Gateway"
  value       = aws_apigatewayv2_api.soat_api.execution_arn
}

# Microservices endpoints
output "user_ms_endpoint" {
  description = "User Microservice endpoint through API Gateway"
  value       = "${aws_apigatewayv2_api.soat_api.api_endpoint}/api/users"
}

output "auth_login_endpoint" {
  description = "Authentication login endpoint"
  value       = "${aws_apigatewayv2_api.soat_api.api_endpoint}/api/auth/login"
}

output "auth_validate_endpoint" {
  description = "Authentication validate endpoint"
  value       = "${aws_apigatewayv2_api.soat_api.api_endpoint}/api/auth/validate"
}

output "process_manager_ms_endpoint" {
  description = "Process Manager Microservice endpoint through API Gateway"
  value       = "${aws_apigatewayv2_api.soat_api.api_endpoint}/api/process-manager"
}

output "swagger_ui_endpoint" {
  description = "Swagger UI endpoint"
  value       = "${aws_apigatewayv2_api.soat_api.api_endpoint}/api-docs"
}

# Health check endpoints
output "health_endpoint" {
  description = "Health check endpoint"
  value       = "${aws_apigatewayv2_api.soat_api.api_endpoint}/health"
}

output "metrics_endpoint" {
  description = "Metrics endpoint"
  value       = "${aws_apigatewayv2_api.soat_api.api_endpoint}/metrics"
}

# Load Balancer URLs (for reference)
output "user_ms_load_balancer_url" {
  description = "Direct URL of User Microservice Load Balancer"
  value       = "http://${data.kubernetes_service.user_ms_service.status[0].load_balancer[0].ingress[0].hostname}"
}

output "process_manager_ms_load_balancer_url" {
  description = "Direct URL of Process Manager Microservice Load Balancer"
  value       = "http://${data.kubernetes_service.process_manager_ms_service.status[0].load_balancer[0].ingress[0].hostname}"
}

# CloudWatch Logs
output "api_gateway_log_group" {
  description = "CloudWatch Log Group for API Gateway"
  value       = aws_cloudwatch_log_group.api_gateway_logs.name
}

# Integration details
output "integrations" {
  description = "API Gateway integrations summary"
  value = {
    user_ms = {
      id  = aws_apigatewayv2_integration.user_ms_integration.id
      uri = aws_apigatewayv2_integration.user_ms_integration.integration_uri
    }
    process_manager_ms = {
      id  = aws_apigatewayv2_integration.process_manager_ms_integration.id
      uri = aws_apigatewayv2_integration.process_manager_ms_integration.integration_uri
    }
  }
}

# Routes summary
output "routes" {
  description = "API Gateway routes summary"
  value = {
    user_api               = aws_apigatewayv2_route.user_ms_route.route_key
    user_api_base         = aws_apigatewayv2_route.user_ms_base_route.route_key
    auth_login            = aws_apigatewayv2_route.auth_login_route.route_key
    auth_validate         = aws_apigatewayv2_route.auth_validate_route.route_key
    auth_catchall         = aws_apigatewayv2_route.auth_catchall_route.route_key
    process_manager_base  = aws_apigatewayv2_route.process_manager_ms_base_route.route_key
    process_manager_api   = aws_apigatewayv2_route.process_manager_ms_route.route_key
    health                = aws_apigatewayv2_route.health_route.route_key
    metrics               = aws_apigatewayv2_route.metrics_route.route_key
    api_docs              = aws_apigatewayv2_route.api_docs_route.route_key
    api_docs_base         = aws_apigatewayv2_route.api_docs_base_route.route_key
    default               = aws_apigatewayv2_route.user_ms_default_route.route_key
  }
}

# =================================================================
# CUSTOM DOMAIN OUTPUTS
# =================================================================
output "custom_domain_enabled" {
  description = "Whether custom domain is enabled"
  value       = var.enable_custom_domain
}

output "custom_domain_name" {
  description = "Custom domain name"
  value       = var.enable_custom_domain ? var.domain_name : null
}

output "custom_domain_url" {
  description = "Custom domain URL for API Gateway"
  value       = var.enable_custom_domain ? "https://${var.domain_name}" : null
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = var.enable_custom_domain ? aws_acm_certificate.api_cert[0].arn : null
}

output "ssl_certificate_status" {
  description = "Status of the SSL certificate"
  value       = var.enable_custom_domain ? aws_acm_certificate.api_cert[0].status : null
}

# Custom domain endpoints for frontend use
output "custom_domain_endpoints" {
  description = "Custom domain endpoints for frontend integration"
  value = var.enable_custom_domain ? {
    base_url              = "https://${var.domain_name}"
    user_ms_endpoint     = "https://${var.domain_name}/api/users"
    auth_login_endpoint  = "https://${var.domain_name}/api/auth/login"
    auth_validate_endpoint = "https://${var.domain_name}/api/auth/validate"
    process_manager_endpoint = "https://${var.domain_name}/api/process-manager"
    swagger_ui_endpoint  = "https://${var.domain_name}/api-docs"
    health_endpoint      = "https://${var.domain_name}/health"
    metrics_endpoint     = "https://${var.domain_name}/metrics"
  } : null
}

# Route53 information
output "route53_hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.enable_custom_domain ? data.aws_route53_zone.main[0].zone_id : null
}

output "route53_name_servers" {
  description = "Route53 name servers"
  value       = var.enable_custom_domain ? data.aws_route53_zone.main[0].name_servers : null
}