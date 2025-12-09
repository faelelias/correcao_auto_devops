output "lambda_functions" {
  description = "Mapa com informações de todas as Lambdas criadas"
  value = {
    for key, lambda in aws_lambda_function.cleanup : key => {
      function_name = lambda.function_name
      function_arn  = lambda.arn
      prefix        = local.target_map[key].prefix
      datasync_task = local.target_map[key].datasync_task_arn
    }
  }
}

output "lambda_function_names" {
  description = "Lista de nomes das funções Lambda"
  value       = [for lambda in aws_lambda_function.cleanup : lambda.function_name]
}

output "lambda_role_arn" {
  description = "ARN da IAM role compartilhada das Lambdas (existente ou criada)"
  value       = local.lambda_role_arn
}

output "eventbridge_rule_arns" {
  description = "Mapa de ARNs das regras EventBridge (uma por Lambda)"
  value       = { for key, rule in aws_cloudwatch_event_rule.datasync_complete : key => rule.arn }
}

output "datasync_task_arn" {
  description = "ARN do Data Sync Task (se criado)"
  value       = var.create_datasync_task ? aws_datasync_task.sync[0].arn : null
}

output "cloudwatch_log_groups" {
  description = "Mapa com nomes dos CloudWatch Log Groups"
  value = {
    for key, log_group in aws_cloudwatch_log_group.lambda : key => log_group.name
  }
}

output "delete_targets" {
  description = "Lista de pastas e tasks configurados"
  value       = var.delete_targets
}
