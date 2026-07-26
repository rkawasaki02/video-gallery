resource "aws_dynamodb_table" "videogarage_tabs" {
  name         = "videogarage-tabs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "tabId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "tabId"
    type = "S"
  }

  #削除保護
  deletion_protection_enabled = true

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_dynamodb_table" "videogarage_videos" {
  name         = "videogarage-videos"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "videoId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "videoId"
    type = "S"
  }

  #削除保護
  deletion_protection_enabled = true

  point_in_time_recovery {
    enabled = true
  }
}

