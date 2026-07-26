output "cloudfront_domain" {
  value       = aws_cloudfront_distribution.frontend.domain_name
  description = "CloudFrontのデフォルトドメイン名"
}

output "api_endpoint" {
  value       = aws_apigatewayv2_stage.default.invoke_url
  description = "API GatewayのベースURL"
}

output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.pool.id
  description = "CognitoユーザープールID"
}

output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.client.id
  description = "CognitoアプリクライアントID"
}

output "aws_cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.frontend.id
  description = "キャッシュ無効化に使うディストリビューションID"
}
