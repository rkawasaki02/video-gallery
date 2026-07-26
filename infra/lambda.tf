locals {
  lambda_functions = {
    tab_get_func = {
      name         = "videogarage-tabs-get"
      source       = "tabs/get.py"
      role         = aws_iam_role.read_role.arn
      handler_file = "get"
      env          = { TABLE_NAME_TABS = aws_dynamodb_table.videogarage_tabs.name }
    }
    tab_post_func = {
      name         = "videogarage-tabs-post"
      source       = "tabs/post.py"
      role         = aws_iam_role.write_role.arn
      handler_file = "post"
      env          = { TABLE_NAME_TABS = aws_dynamodb_table.videogarage_tabs.name }
    }
    tab_delete_func = {
      name         = "videogarage-tabs-delete"
      source       = "tabs/delete.py"
      role         = aws_iam_role.tabs_delete_role.arn
      handler_file = "delete"
      env = {
        TABLE_NAME_TABS   = aws_dynamodb_table.videogarage_tabs.name
        TABLE_NAME_VIDEOS = aws_dynamodb_table.videogarage_videos.name
      }
    }
    video_get_func = {
      name         = "videogarage-videos-get"
      source       = "videos/get.py"
      role         = aws_iam_role.read_role.arn
      handler_file = "get"
      env          = { TABLE_NAME_VIDEOS = aws_dynamodb_table.videogarage_videos.name }
    }
    video_post_func = {
      name         = "videogarage-videos-post"
      source       = "videos/post.py"
      role         = aws_iam_role.write_role.arn
      handler_file = "post"
      env          = { TABLE_NAME_VIDEOS = aws_dynamodb_table.videogarage_videos.name }
    }
    video_delete_func = {
      name         = "videogarage-videos-delete"
      source       = "videos/delete.py"
      role         = aws_iam_role.videos_delete_role.arn
      handler_file = "delete"
      env          = { TABLE_NAME_VIDEOS = aws_dynamodb_table.videogarage_videos.name }
    }
  }
}

data "archive_file" "lambda_zip" {
  for_each = local.lambda_functions

  type        = "zip"
  source_file = "${path.module}/../backend/lambda/${each.value.source}"
  output_path = "${path.module}/build/${each.key}.zip"
}

resource "aws_lambda_function" "this" {
  for_each = local.lambda_functions

  function_name    = each.value.name
  filename         = data.archive_file.lambda_zip[each.key].output_path
  source_code_hash = data.archive_file.lambda_zip[each.key].output_base64sha256
  role             = each.value.role
  runtime          = "python3.14"
  handler          = "${each.value.handler_file}.lambda_handler"

  environment {
    variables = each.value.env
  }
}
