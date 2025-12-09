output "lambda_function_name" {
  description = "Nome da função Lambda"
  value       = aws_lambda_function.cleanup.function_name
}

output "lambda_function_arn" {
  description = "ARN da função Lambda"
  value       = aws_lambda_function.cleanup.arn
}

output "lambda_role_arn" {
  description = "ARN da IAM role da Lambda"
  value       = aws_iam_role.lambda.arn
}

output "eventbridge_rule_arn" {
  description = "ARN da regra EventBridge"
  value       = aws_cloudwatch_event_rule.datasync_complete.arn
}

output "datasync_task_arn" {
  description = "ARN do Data Sync Task (se criado)"
  value       = var.create_datasync_task ? aws_datasync_task.sync[0].arn : null
}

output "cloudwatch_log_group" {
  description = "Nome do CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.lambda.name
}
