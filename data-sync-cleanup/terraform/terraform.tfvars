# Exemplo de arquivo terraform.tfvars
# Copie este arquivo para terraform.tfvars e preencha os valores marcados com XXXX

# Ambiente
environment = "prd"  # ou "stage", "prod"
aws_region  = "sa-east-1"  

# Bucket S3 de origem (OBRIGATÓRIO - preencher com seus valores)
source_bucket_name = "cawa.rafa.prd"
source_bucket_arn  = "arn:aws:s3:::cawa.rafa.prd"

# Lista de pastas a serem deletadas e seus DataSync Tasks específicos
# Cada pasta terá sua própria Lambda function e um task dedicado
delete_targets = [
  {
    prefix            = "p012/adc/"
    datasync_task_arn = "arn:aws:datasync:sa-east-1:XXXX-account-id:task/adc-task-id"
  },
  {
    prefix            = "p012/bol/"
    datasync_task_arn = "arn:aws:datasync:sa-east-1:XXXX-account-id:task/bol-task-id"
  }
]

# Configuração da Lambda (opcional - valores padrão já definidos)
lambda_timeout     = 300
lambda_memory_size = 256
log_retention_days = 14

# Usar IAM role e policy existentes
use_existing_iam_role   = true
existing_iam_role_name   = "datasync_role"
use_existing_iam_policy  = true
existing_iam_policy_name = "datasync_policy"

# ============================================================================
# OPÇÃO 1: Usar Data Sync Task existente (recomendado)
# ============================================================================
create_datasync_task = false
# OBRIGATÓRIO: Preencher com o ARN do seu Data Sync Task
datasync_task_arn    = "arn:aws:datasync:XXXX-regiao:XXXX-account-id:task/XXXX-task-id"

# ============================================================================
# OPÇÃO 2: Criar Data Sync Task automaticamente
# Descomente e preencha se quiser que o Terraform crie o Data Sync Task
# ============================================================================
# create_datasync_task    = true
# OBRIGATÓRIO se create_datasync_task = true:
# datasync_role_arn       = "arn:aws:iam::XXXX-account-id:role/XXXX-datasync-role"
# destination_bucket_arn = "arn:aws:s3:::XXXX-meu-bucket-destino"
# Opcionais:
# source_subdirectory     = "p012/"  # ou deixe vazio ""
# destination_subdirectory = "backup/"  # ou deixe vazio ""
