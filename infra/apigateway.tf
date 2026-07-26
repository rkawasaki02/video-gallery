locals {
  api_routes = {
    videos_get    = { route_key = "GET /videos", lambda = aws_lambda_function.this["video_get_func"] }
    videos_post   = { route_key = "POST /videos", lambda = aws_lambda_function.this["video_post_func"] }
    videos_delete = { route_key = "DELETE /videos/{videoId}", lambda = aws_lambda_function.this["video_delete_func"] }
    tabs_get      = { route_key = "GET /tabs", lambda = aws_lambda_function.this["tab_get_func"] }
    tabs_post     = { route_key = "POST /tabs", lambda = aws_lambda_function.this["tab_post_func"] }
    tabs_delete   = { route_key = "DELETE /tabs/{tabId}", lambda = aws_lambda_function.this["tab_delete_func"] }
  }
}

resource "aws_apigatewayv2_api" "videogarage_api" {
  name          = "videogarage-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://videogarage.jp"]
    allow_methods = ["GET", "POST", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_authorizer" "config" {
  api_id           = aws_apigatewayv2_api.videogarage_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "videogarage-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    issuer   = "https://cognito-idp.ap-northeast-1.amazonaws.com/${aws_cognito_user_pool.pool.id}"
  }
}

resource "aws_apigatewayv2_integration" "this" {
  for_each = local.api_routes

  api_id                 = aws_apigatewayv2_api.videogarage_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.lambda.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "this" {
  for_each = local.api_routes

  api_id             = aws_apigatewayv2_api.videogarage_api.id
  route_key          = each.value.route_key
  target             = "integrations/${aws_apigatewayv2_integration.this[each.key].id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.config.id
}


resource "aws_lambda_permission" "apigw" {
  for_each = local.api_routes

  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.videogarage_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.videogarage_api.id
  name        = "$default"
  auto_deploy = true
}
