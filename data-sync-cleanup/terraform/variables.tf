variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
  default     = "prd"
}

variable "aws_region" {
  description = "AWS region to deploy"
  type        = string
  default     = "us-east-1"
}

variable "source_bucket_name" {
  description = "Nome do bucket S3 de origem (que será limpo após a cópia)"
  type        = string
}

variable "source_bucket_arn" {
  description = "ARN do bucket S3 de origem"
  type        = string
}

variable "delete_targets" {
  description = "Lista de pastas com seus respectivos DataSync Task ARNs"
  type = list(object({
    prefix            : string
    datasync_task_arn : string
  }))
  default = [
    {
      prefix            = "p012/adc/"
      datasync_task_arn = "arn:aws:datasync:sa-east-1:111111111111:task/adc-task-id"
    },
    {
      prefix            = "p012/bol/"
      datasync_task_arn = "arn:aws:datasync:sa-east-1:111111111111:task/bol-task-id"
    }
  ]
}

variable "lambda_timeout" {
  description = "Timeout da Lambda em segundos"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Memória alocada para a Lambda em MB"
  type        = number
  default     = 256
}

variable "log_retention_days" {
  description = "Dias de retenção dos logs no CloudWatch"
  type        = number
  default     = 14
}

# Variáveis para usar IAM role e policy existentes
variable "use_existing_iam_role" {
  description = "Se deve usar uma IAM role existente ao invés de criar uma nova"
  type        = bool
  default     = false
}

variable "existing_iam_role_name" {
  description = "Nome da IAM role existente a ser usada (se use_existing_iam_role = true)"
  type        = string
  default     = "datasync_role"
}

variable "use_existing_iam_policy" {
  description = "Se deve usar uma IAM policy existente ao invés de criar novas"
  type        = bool
  default     = false
}

variable "existing_iam_policy_name" {
  description = "Nome da IAM policy existente a ser anexada (se use_existing_iam_policy = true)"
  type        = string
  default     = "datasync_policy"
}

# Variáveis opcionais para criar o Data Sync Task
variable "create_datasync_task" {
  description = "Se deve criar o Data Sync Task automaticamente"
  type        = bool
  default     = false
}

variable "datasync_task_arn" {
  description = "ARN do Data Sync Task existente (deixe vazio se criar automaticamente)"
  type        = string
  default     = ""
}

variable "datasync_role_arn" {
  description = "ARN da IAM role para o Data Sync acessar os buckets S3"
  type        = string
  default     = ""
}

variable "source_subdirectory" {
  description = "Subdiretório no bucket de origem (opcional)"
  type        = string
  default     = ""
}

variable "destination_bucket_arn" {
  description = "ARN do bucket S3 de destino (apenas se create_datasync_task = true)"
  type        = string
  default     = ""
}

variable "destination_subdirectory" {
  description = "Subdiretório no bucket de destino (opcional)"
  type        = string
  default     = ""
}
