# Data Sync Cleanup Lambda

Lambda function que apaga automaticamente dados de um bucket S3 após a cópia ser concluída pelo AWS Data Sync.

## Arquitetura

```
Data Sync Task → EventBridge (SUCCESS) → Lambda Function → Delete S3 Objects
```

## Componentes

- **Lambda Function**: Função Python que apaga objetos do bucket S3 de origem
- **EventBridge Rule**: Regra que monitora eventos de conclusão do Data Sync
- **IAM Role**: Permissões para a Lambda acessar S3 e Data Sync
- **CloudWatch Logs**: Logs da execução da Lambda

## Pré-requisitos

- AWS CLI configurado
- Terraform >= 1.5.0
- Python 3.11+ (para desenvolvimento local)
- Bucket S3 de origem existente
- Data Sync Task configurado (ou usar a opção de criar automaticamente)

## Configuração

> **⚠️ IMPORTANTE**: Antes de fazer o deploy, você precisa preencher os valores marcados com `XXXX` no arquivo `terraform.tfvars.example` e salvá-lo como `terraform.tfvars`.

### 1. Configurar Variáveis

Copie o arquivo de exemplo e preencha os valores marcados com `XXXX`:

```bash
cd data-sync-cleanup/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` e preencha os campos obrigatórios:

**Campos OBRIGATÓRIOS:**
```hcl
# Bucket S3 de origem
source_bucket_name = "XXXX-meu-bucket-origem"  # Substitua XXXX pelo nome real
source_bucket_arn  = "arn:aws:s3:::XXXX-meu-bucket-origem"  # Substitua XXXX pelo nome real
```

### 2. Opção A: Usar Data Sync Task Existente (Recomendado)

Se você já tem um Data Sync Task configurado:

```hcl
create_datasync_task = false
# Preencha com o ARN do seu Data Sync Task
datasync_task_arn   = "arn:aws:datasync:XXXX-regiao:XXXX-account-id:task/XXXX-task-id"
```

**Onde encontrar o ARN:**
- Console AWS → Data Sync → Tasks → Selecione sua task → Copie o ARN

### 3. Opção B: Criar Data Sync Task Automaticamente

Se você quer que o Terraform crie o Data Sync Task:

```hcl
create_datasync_task    = true
# Preencha com os valores reais (substitua XXXX)
datasync_role_arn       = "arn:aws:iam::XXXX-account-id:role/XXXX-datasync-role"
destination_bucket_arn  = "arn:aws:s3:::XXXX-meu-bucket-destino"
source_subdirectory     = "p012/"      # Opcional - pasta de origem
destination_subdirectory = "backup/"    # Opcional - pasta de destino
```

## Deploy

### 1. Inicializar Terraform

```bash
cd data-sync-cleanup/terraform
terraform init
```

### 2. Revisar Plano

```bash
terraform plan
```

### 3. Aplicar

```bash
terraform apply
```

## Variáveis de Ambiente da Lambda

Cada Lambda usa as seguintes variáveis de ambiente:

- `SOURCE_BUCKET`: Nome do bucket S3 de origem (configurado automaticamente)
- `DELETE_PREFIX`: Prefixo da pasta específica que esta Lambda irá deletar (ex: `p012/adc/`)

**Importante**: Cada pasta terá sua própria Lambda function. Isso permite:
- Logs separados por pasta no CloudWatch
- Execução independente e paralela
- Melhor rastreabilidade e debugging
- Configuração individual se necessário

## Como Funciona

1. **Data Sync completa uma tarefa** com status `SUCCESS`
2. **EventBridge detecta o evento** e aciona todas as Lambdas configuradas
3. **Cada Lambda processa sua pasta específica**:
   - Valida que o Data Sync foi bem-sucedido
   - Lista todos os objetos na sua pasta específica do bucket de origem
   - Deleta os objetos em lotes (até 1000 por vez)
   - Retorna o número de objetos deletados
4. **Todas as Lambdas executam em paralelo**, cada uma cuidando de sua pasta

## Logs

Os logs de cada Lambda estão disponíveis no CloudWatch com nomes separados:

```bash
# Para a pasta adc
aws logs tail /aws/lambda/data-sync-cleanup-prd-p012-adc --follow

# Para a pasta bol
aws logs tail /aws/lambda/data-sync-cleanup-prd-p012-bol --follow
```

Ou liste todas as Lambdas:
```bash
aws lambda list-functions --query "Functions[?contains(FunctionName, 'data-sync-cleanup')].FunctionName"
```

## Teste Manual

Você pode testar cada Lambda manualmente enviando um evento simulado:

```bash
# Testar Lambda da pasta adc
aws lambda invoke \
  --function-name data-sync-cleanup-prd-p012-adc \
  --payload '{
    "detail": {
      "status": "SUCCESS",
      "taskArn": "arn:aws:datasync:us-east-1:123456789012:task/task-1234567890abcdef0",
      "executionArn": "arn:aws:datasync:us-east-1:123456789012:execution/exec-1234567890abcdef0"
    }
  }' \
  response.json

# Testar Lambda da pasta bol
aws lambda invoke \
  --function-name data-sync-cleanup-prd-p012-bol \
  --payload '{
    "detail": {
      "status": "SUCCESS",
      "taskArn": "arn:aws:datasync:us-east-1:123456789012:task/task-1234567890abcdef0",
      "executionArn": "arn:aws:datasync:us-east-1:123456789012:execution/exec-1234567890abcdef0"
    }
  }' \
  response.json
```

## Segurança

- A Lambda tem permissões mínimas necessárias:
  - `s3:ListBucket`, `s3:DeleteObject` no bucket de origem
  - `datasync:DescribeTaskExecution` para validação
  - CloudWatch Logs para logging

## Customização

### Configurar Pastas e DataSync Tasks (uma Lambda por pasta)

Agora cada pasta tem sua própria Lambda **e** seu próprio DataSync Task. Exemplo:

```hcl
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
```

**Importante**:
- Cada prefixo deve terminar com `/`
- Cada pasta tem **sua própria Lambda** e **seu próprio DataSync Task**
- As Lambdas executam em paralelo quando **seu** DataSync Task completa
- Se não configurar, o padrão cria duas Lambdas com valores placeholder (substitua pelos ARNs reais)

### Ajustar Timeout e Memória

```hcl
lambda_timeout     = 600  # 10 minutos
lambda_memory_size = 512  # 512 MB
```

### Usar IAM Role e Policy Existentes

Se você já tem uma IAM role e policy configuradas (ex: `datasync_role` e `datasync_policy`), pode reutilizá-las:

```hcl
use_existing_iam_role   = true
existing_iam_role_name   = "datasync_role"
use_existing_iam_policy  = true
existing_iam_policy_name = "datasync_policy"
```

**Importante**: 
- A role deve ter a trust policy para `lambda.amazonaws.com`
- A policy deve ter as permissões necessárias para S3 (ListBucket, DeleteObject) e DataSync (DescribeTaskExecution)
- Se `use_existing_iam_role = false`, uma nova role será criada
- Se `use_existing_iam_policy = false`, novas policies inline serão criadas

## Troubleshooting

### Lambdas não estão sendo acionadas

1. Verifique se o EventBridge rule está ativo:
   ```bash
   aws events describe-rule --name data-sync-cleanup-prd-datasync-complete
   ```

2. Verifique as regras e targets (uma regra por Lambda):
   ```bash
   aws events list-rules --name-prefix data-sync-cleanup-prd
   aws events list-targets-by-rule --rule data-sync-cleanup-prd-p012-adc-datasync-complete
   aws events list-targets-by-rule --rule data-sync-cleanup-prd-p012-bol-datasync-complete
   ```

3. Verifique os logs do EventBridge:
   ```bash
   aws logs tail /aws/events/rule/data-sync-cleanup-prd-datasync-complete --follow
   ```

### Erro de permissões

Verifique se a IAM role compartilhada tem as permissões corretas:
```bash
aws iam get-role-policy --role-name data-sync-cleanup-prd-lambda-role --policy-name data-sync-cleanup-prd-lambda-s3-policy
```

### Arquivos não estão sendo deletados

1. Verifique os logs de cada Lambda no CloudWatch (cada uma tem seu próprio log group)
2. Confirme que o bucket e prefixos estão corretos no `terraform.tfvars`
3. Verifique se há objetos no bucket que correspondem aos prefixos configurados
4. Liste todas as Lambdas criadas:
   ```bash
   aws lambda list-functions --query "Functions[?contains(FunctionName, 'data-sync-cleanup-prd')].FunctionName"
   ```

## Limpeza

Para remover todos os recursos:

```bash
terraform destroy
```

**Atenção**: Isso também deletará o Data Sync Task se foi criado pelo Terraform.
