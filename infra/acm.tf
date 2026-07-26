data "aws_acm_certificate" "amazon_issued" {
  provider = aws.virginia
  domain   = "videogarage.jp"
  types    = ["AMAZON_ISSUED"]
  statuses = ["ISSUED"]
}
