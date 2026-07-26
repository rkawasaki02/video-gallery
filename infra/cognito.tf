resource "aws_cognito_user_pool" "pool" {
  name                     = "videogarage-user-pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "ap-northeast-1hpxdrky5a"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "videogarage-client"
  user_pool_id = aws_cognito_user_pool.pool.id

  access_token_validity  = 30
  id_token_validity      = 30
  refresh_token_validity = 5

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  explicit_auth_flows = [
    "ALLOW_USER_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "phone"]
  allowed_oauth_flows_user_pool_client = true

  callback_urls = ["https://videogarage.jp"]
}
