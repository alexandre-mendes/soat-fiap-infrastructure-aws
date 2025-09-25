# =================================================================
# API GATEWAY V2 (HTTP API) - SOAT FIAP MICROSERVICES
# =================================================================

# Obter dados dos serviços EKS
data "kubernetes_service" "user_ms_service" {
  metadata {
    name      = "soat-fiap-user-application-ms"
    namespace = "default"
  }
}

data "kubernetes_service" "process_manager_ms_service" {
  metadata {
    name      = "soat-fiap-process-manager-application-ms"
    namespace = "default"
  }
}

# =================================================================
# API GATEWAY V2 - MAIN API
# =================================================================
resource "aws_apigatewayv2_api" "soat_api" {
  name          = "soat-fiap-api-gateway"
  description   = "SOAT FIAP Microservices API Gateway"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["*"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    max_age          = 86400
  }

  tags = {
    Name        = "soat-fiap-api-gateway"
    Environment = "development"
    Project     = "soat-fiap"
  }
}

# =================================================================
# INTEGRATIONS - MICROSERVICES
# =================================================================

# Integração para o User Application Microservice
resource "aws_apigatewayv2_integration" "user_ms_integration" {
  api_id                 = aws_apigatewayv2_api.soat_api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${data.kubernetes_service.user_ms_service.status[0].load_balancer[0].ingress[0].hostname}/"
  payload_format_version = "1.0"
  
  request_parameters = {
    "overwrite:path" = "$request.path"
  }

  timeout_milliseconds = 30000
}

# Integração para o Process Manager Microservice
resource "aws_apigatewayv2_integration" "process_manager_ms_integration" {
  api_id                 = aws_apigatewayv2_api.soat_api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${data.kubernetes_service.process_manager_ms_service.status[0].load_balancer[0].ingress[0].hostname}/"
  payload_format_version = "1.0"
  
  request_parameters = {
    "overwrite:path" = "$request.path"
  }

  timeout_milliseconds = 30000
}

# =================================================================
# ROUTES - MICROSERVICES
# =================================================================

# Rota para User Application Microservice - Users
resource "aws_apigatewayv2_route" "user_ms_route" {
  api_id    = aws_apigatewayv2_api.soat_api.id
  route_key = "ANY /api/users/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.user_ms_integration.id}"
}

# Rota para User Application Microservice - Users (sem proxy)
resource "aws_apigatewayv2_route" "user_ms_base_route" {
  api_id    = aws_apigatewayv2_api.soat_api.id
  route_key = "ANY /api/users"
  target    = "integrations/${aws_apigatewayv2_integration.user_ms_integration.id}"
}

# Rota para Autenticação - Login
resource "aws_apigatewayv2_route" "auth_login_route" {
  api_id    = aws_apigatewayv2_api.soat_api.id
  route_key = "POST /api/auth/login"
  target    = "integrations/${aws_apigatewayv2_integration.user_ms_integration.id}"
}

# Rota para Autenticação - Validate
resource "aws_apigatewayv2_route" "auth_validate_route" {
  api_id    = aws_apigatewayv2_api.soat_api.id
  route_key = "POST /api/auth/validate"
  target    = "integrations/${aws_apigatewayv2_integration.user_ms_integration.id}"
}

# Rota para Autenticação - Catch All
resource "aws_apigatewayv2_route" "auth_catchall_route" {
  api_id    = aws_apigatewayv2_api.soat_api.id
  route_key = "ANY /api/auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.user_ms_integration.id}"
}

# Rota para Process Manager Microservice - Base
resource "aws_apigatewayv2_route" "process_manager_ms_base_route" {
  api_id    = aws_apigatewayv2_api.soat_api.id
  route_key = "ANY /api/process-manager"
  target    = "integrations/${aws_apigatewayv2_integration.process_manager_ms_integration.id}"
}

# Rota para Process Manager Microservice - Com Proxy
resource "aws_apigatewayv2_route" "process_manager_ms_route" {
  api_id    = aws_apigatewayv2_api.soat_api.id
  route_key = "ANY /api/process-manager/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.process_manager_ms_integration.id}"
}

# Rota para health check (genérico - vai para User MS)
resource "aws_apigatewayv2_route" "health_route" {
  api_id    = aws_apigatewayv2_api.soat_api.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.user_ms_integration.id}"
}

# Rota para metrics (User MS)
resource "aws_apigatewayv2_route" "metrics_route" {
  api_id    = aws_apigatewayv2_api.soat_api.id
  route_key = "GET /metrics"
  target    = "integrations/${aws_apigatewayv2_integration.user_ms_integration.id}"
}

# Rota para API Docs (User MS)
resource "aws_apigatewayv2_route" "api_docs_route" {
  api_id    = aws_apigatewayv2_api.soat_api.id
  route_key = "ANY /api-docs/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.user_ms_integration.id}"
}

# Rota para API Docs base (User MS)
resource "aws_apigatewayv2_route" "api_docs_base_route" {
  api_id    = aws_apigatewayv2_api.soat_api.id
  route_key = "GET /api-docs"
  target    = "integrations/${aws_apigatewayv2_integration.user_ms_integration.id}"
}

# Rota catch-all para User MS (rota padrão)
resource "aws_apigatewayv2_route" "user_ms_default_route" {
  api_id    = aws_apigatewayv2_api.soat_api.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.user_ms_integration.id}"
}

# =================================================================
# STAGE - DEPLOYMENT
# =================================================================
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.soat_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = true
    logging_level            = "INFO"
    throttling_burst_limit   = 5000
    throttling_rate_limit    = 2000
  }

  tags = {
    Name        = "soat-fiap-api-stage"
    Environment = "development"
  }
}

# =================================================================
# CLOUDWATCH LOGS (para monitoramento)
# =================================================================
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/soat-fiap-api"
  retention_in_days = 7

  tags = {
    Name = "soat-fiap-api-logs"
  }
}

# =================================================================
# CUSTOM DOMAIN & SSL CERTIFICATE
# =================================================================

# Data source para buscar a hosted zone do Route53
data "aws_route53_zone" "main" {
  count        = var.enable_custom_domain ? 1 : 0
  name         = var.hosted_zone_name
  private_zone = false
}

# Certificado SSL via AWS Certificate Manager
resource "aws_acm_certificate" "api_cert" {
  count           = var.enable_custom_domain ? 1 : 0
  domain_name     = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.hosted_zone_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-api-cert"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Validação do certificado SSL
resource "aws_acm_certificate_validation" "api_cert_validation" {
  count           = var.enable_custom_domain ? 1 : 0
  certificate_arn = aws_acm_certificate.api_cert[0].arn
  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation : record.fqdn
  ]

  timeouts {
    create = "10m"
  }
}

# Records DNS para validação do certificado
resource "aws_route53_record" "cert_validation" {
  for_each = var.enable_custom_domain ? {
    for dvo in aws_acm_certificate.api_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main[0].zone_id
}

# Custom Domain Name para API Gateway
resource "aws_apigatewayv2_domain_name" "api_domain" {
  count       = var.enable_custom_domain ? 1 : 0
  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api_cert_validation[0].certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [aws_acm_certificate_validation.api_cert_validation]

  tags = {
    Name        = "${var.project_name}-api-domain"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Mapeamento do domínio customizado para o API Gateway
resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  count       = var.enable_custom_domain ? 1 : 0
  api_id      = aws_apigatewayv2_api.soat_api.id
  domain_name = aws_apigatewayv2_domain_name.api_domain[0].id
  stage       = aws_apigatewayv2_stage.default.id
}

# Record DNS A para o domínio customizado
resource "aws_route53_record" "api_record" {
  count   = var.enable_custom_domain && var.create_route53_record ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api_domain[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_domain[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}