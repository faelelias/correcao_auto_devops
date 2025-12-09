locals {
  project = "data-sync-cleanup"
  env     = var.environment
  name    = "${local.project}-${local.env}"
  
  # Normalizar prefixos e criar um mapa para for_each
  # Cada item possui prefixo e task específico
  target_map = {
    for target in var.delete_targets :
    trim(replace(target.prefix, "/", "-"), "-") => target
  }
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

# Data source para buscar IAM role existente (se configurado)
data "aws_iam_role" "existing" {
  count = var.use_existing_iam_role ? 1 : 0
  name  = var.existing_iam_role_name
}

# Data source para buscar IAM policy existente (se configurado)
data "aws_iam_policy" "existing" {
  count = var.use_existing_iam_policy ? 1 : 0
  name  = var.existing_iam_policy_name
}

# IAM Role compartilhada para todas as Lambdas (criada apenas se não usar role existente)
resource "aws_iam_role" "lambda" {
  count = var.use_existing_iam_role ? 0 : 1
  name  = "${local.name}-lambda-role"

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

# Policy para as Lambdas acessarem S3 (criada apenas se não usar policy existente)
resource "aws_iam_role_policy" "lambda_s3" {
  count = var.use_existing_iam_policy ? 0 : 1
  name  = "${local.name}-lambda-s3-policy"
  role  = var.use_existing_iam_role ? data.aws_iam_role.existing[0].id : aws_iam_role.lambda[0].id

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

# Policy para as Lambdas acessarem Data Sync (criada apenas se não usar policy existente)
resource "aws_iam_role_policy" "lambda_datasync" {
  count = var.use_existing_iam_policy ? 0 : 1
  name  = "${local.name}-lambda-datasync-policy"
  role  = var.use_existing_iam_role ? data.aws_iam_role.existing[0].id : aws_iam_role.lambda[0].id

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

# Anexar policy existente à role (se configurado)
resource "aws_iam_role_policy_attachment" "existing_policy" {
  count      = var.use_existing_iam_policy ? 1 : 0
  role       = var.use_existing_iam_role ? data.aws_iam_role.existing[0].name : aws_iam_role.lambda[0].name
  policy_arn = data.aws_iam_policy.existing[0].arn
}

# Policy básica para CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = var.use_existing_iam_role ? data.aws_iam_role.existing[0].name : aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Local para obter o ARN da role (existente ou criada)
locals {
  lambda_role_arn = var.use_existing_iam_role ? data.aws_iam_role.existing[0].arn : aws_iam_role.lambda[0].arn
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

# Lambda Functions - uma para cada pasta
resource "aws_lambda_function" "cleanup" {
  for_each = local.target_map

  function_name = "${local.name}-${each.key}"
  role          = local.lambda_role_arn
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
      DELETE_PREFIX = each.value.prefix
    }
  }

  tags = {
    Name        = "${local.name}-${each.key}"
    Environment = local.env
    Project     = local.project
    Prefix      = each.value
    DataSyncTask = each.value.datasync_task_arn
  }
}

# CloudWatch Log Groups - um para cada Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  for_each = local.target_map

  name              = "/aws/lambda/${aws_lambda_function.cleanup[each.key].function_name}"
  retention_in_days = var.log_retention_days
}

# EventBridge Rule para acionar as Lambdas após Data Sync completar
resource "aws_cloudwatch_event_rule" "datasync_complete" {
  for_each    = local.target_map
  name        = "${local.name}-${each.key}-datasync-complete"
  description = "Aciona Lambda para ${each.value.prefix} quando Data Sync task completa com sucesso"

  event_pattern = jsonencode({
    source      = ["aws.datasync"]
    detail-type = ["DataSync Task Execution State Change"]
    detail = {
      status = ["SUCCESS"]
      taskArn = [each.value.datasync_task_arn]
    }
  })
}

# Permissões para EventBridge acionar cada Lambda
resource "aws_lambda_permission" "eventbridge" {
  for_each = local.target_map

  statement_id  = "AllowExecutionFromEventBridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanup[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.datasync_complete[each.key].arn
}

# Targets da regra EventBridge - uma para cada Lambda
resource "aws_cloudwatch_event_target" "lambda" {
  for_each = local.target_map

  rule      = aws_cloudwatch_event_rule.datasync_complete[each.key].name
  target_id = "TriggerLambda-${each.key}"
  arn       = aws_lambda_function.cleanup[each.key].arn
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
