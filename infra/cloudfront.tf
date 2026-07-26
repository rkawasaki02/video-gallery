locals {
  # CloudFront定額プランが自動作成したWeb ACL。
  # 定額プラン加入中はWeb ACLの差し替え・解除がAPIレベルで拒否されるため
  # (InvalidArgument: You can't remove or replace the web ACL)、
  # Terraform管理下に置けずARNを直接参照している。
  # 従量課金プランへの切り替え検討後、aws_wafv2_web_acl リソースへ移行予定。
  cloudfront_web_acl_arn = "arn:aws:wafv2:us-east-1:691529316955:global/webacl/CreatedByCloudFront-c9b30a49/12b39cdf-4661-49a4-89f2-ec86275b7577"
}
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "video-garage-cf"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


resource "aws_cloudfront_distribution" "frontend" {
  origin {
    domain_name              = aws_s3_bucket.video_garage.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = aws_s3_bucket.video_garage.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["videogarage.jp"]

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.video_garage.id
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }


  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.amazon_issued.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  web_acl_id = local.cloudfront_web_acl_arn
}
