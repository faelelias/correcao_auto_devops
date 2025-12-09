variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "source_bucket_name" {
  description = "Nome do bucket S3 de origem (que será limpo após a cópia)"
  type        = string
}

variable "source_bucket_arn" {
  description = "ARN do bucket S3 de origem"
  type        = string
}

variable "delete_prefix" {
  description = "Prefixo opcional para filtrar quais arquivos deletar (deixe vazio para deletar tudo)"
  type        = string
  default     = ""
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
