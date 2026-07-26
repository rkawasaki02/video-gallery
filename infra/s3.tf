resource "aws_s3_bucket" "video_garage" {
  bucket = "video-garage"
}

resource "aws_s3_bucket_policy" "frontend_oac" {
  bucket = aws_s3_bucket.video_garage.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.video_garage.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}

locals {
  frontend_mime_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "text/javascript"
    ".json" = "application/json"
    ".svg"  = "image/svg+xml"
    ".png"  = "image/png"
    ".ico"  = "image/x-icon"
    ".txt"  = "text/plain"
  }

  frontend_files = [
    for f in fileset("../frontend", "**") : f
    if !can(regex("(^|/)\\.DS_Store$", f)) && !can(regex("(^|/)\\.git", f))
  ]
}

resource "aws_s3_object" "frontend" {
  for_each = toset(local.frontend_files)

  bucket = aws_s3_bucket.video_garage.id
  key    = each.value
  source = "${path.module}/../frontend/${each.value}"

  etag         = filemd5("${path.module}/../frontend/${each.value}")
  content_type = lookup(local.frontend_mime_types, try(regex("\\.[^.]+$", lower(each.value)), ""), "application/octet-stream")
}
