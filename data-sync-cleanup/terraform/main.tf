locals {
  project = "data-sync-cleanup"
  env     = var.environment
  name    = "${local.project}-${local.env}"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# S3 bucket para armazenar o código da Lambda
resource "aws_s3_bucket" "lambda_code" {
  bucket        = "${local.name}-lambda-code-${data.aws_region.current.name}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code.id
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM Role para a Lambda
resource "aws_iam_role" "lambda" {
  name = "${local.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Policy para a Lambda acessar S3
resource "aws_iam_role_policy" "lambda_s3" {
  name = "${local.name}-lambda-s3-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:ListBucketVersions"
        ]
        Resource = [
          var.source_bucket_arn,
          "arn:aws:s3:::${var.source_bucket_name}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "${var.source_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Policy para a Lambda acessar Data Sync (para obter detalhes da execução)
resource "aws_iam_role_policy" "lambda_datasync" {
  name = "${local.name}-lambda-datasync-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "datasync:DescribeTaskExecution",
          "datasync:ListTaskExecutions"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy básica para CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Zip do código da Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Upload do código para S3
resource "aws_s3_object" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code.id
  key    = "lambda_function-${data.archive_file.lambda_zip.output_md5}.zip"
  source = data.archive_file.lambda_zip.output_path
  etag   = data.archive_file.lambda_zip.output_md5
}

# Lambda Function
resource "aws_lambda_function" "cleanup" {
  function_name = local.name
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  s3_bucket = aws_s3_bucket.lambda_code.id
  s3_key    = aws_s3_object.lambda_code.key

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SOURCE_BUCKET = var.source_bucket_name
      DELETE_PREFIX = var.delete_prefix
    }
  }

  tags = {
    Name        = local.name
    Environment = local.env
    Project     = local.project
  }
}

# CloudWatch Log Group para a Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.cleanup.function_name}"
  retention_in_days = var.log_retention_days
}

# EventBridge Rule para acionar a Lambda após Data Sync completar
resource "aws_cloudwatch_event_rule" "datasync_complete" {
  name        = "${local.name}-datasync-complete"
  description = "Aciona Lambda quando Data Sync task completa com sucesso"

  event_pattern = jsonencode({
    source      = ["aws.datasync"]
    detail-type = ["DataSync Task Execution State Change"]
    detail = {
      status = ["SUCCESS"]
      taskArn = var.datasync_task_arn != "" ? [var.datasync_task_arn] : null
    }
  })
}

# Permissão para EventBridge acionar a Lambda
resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.datasync_complete.arn
}

# Target da regra EventBridge
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.datasync_complete.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.cleanup.arn
}

# Opcional: Configuração do Data Sync Task (se não existir)
resource "aws_datasync_location_s3" "source" {
  count = var.create_datasync_task ? 1 : 0

  s3_bucket_arn = var.source_bucket_arn
  subdirectory  = var.source_subdirectory

  s3_config {
    bucket_access_role_arn = var.datasync_role_arn
  }

  tags = {
    Name = "${local.name}-source"
  }
}

resource "aws_datasync_location_s3" "destination" {
  count = var.create_datasync_task ? 1 : 0

  s3_bucket_arn = var.destination_bucket_arn
  subdirectory  = var.destination_subdirectory

  s3_config {
    bucket_access_role_arn = var.datasync_role_arn
  }

  tags = {
    Name = "${local.name}-destination"
  }
}

resource "aws_datasync_task" "sync" {
  count = var.create_datasync_task ? 1 : 0

  name                     = "${local.name}-task"
  source_location_arn      = aws_datasync_location_s3.source[0].arn
  destination_location_arn = aws_datasync_location_s3.destination[0].arn

  options {
    verify_mode                = "POINT_IN_TIME_CONSISTENT"
    overwrite_mode             = "ALWAYS"
    atime                      = "BEST_EFFORT"
    mtime                      = "PRESERVE"
    uid                        = "NONE"
    gid                        = "NONE"
    preserve_deleted_files     = "REMOVE"
    preserve_devices            = "NONE"
    posix_permissions          = "NONE"
    bytes_per_second            = -1
    task_queueing              = "ENABLED"
    log_level                  = "TRANSFER"
    transfer_mode              = "CHANGED"
    security_descriptor_copy_flags = "NONE"
  }

  tags = {
    Name = "${local.name}-task"
  }
}
