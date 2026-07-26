data "aws_route53_zone" "selected" {
  name = "videogarage.jp."
}

resource "aws_route53_record" "videogarage_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "videogarage.jp"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "videogarage_record_ipv6" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "videogarage.jp"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}
