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

### 1. Variáveis Obrigatórias

Edite `terraform/terraform.tfvars` ou passe via linha de comando:

```hcl
source_bucket_name = "meu-bucket-origem"
source_bucket_arn  = "arn:aws:s3:::meu-bucket-origem"
```

### 2. Opção A: Usar Data Sync Task Existente

Se você já tem um Data Sync Task configurado:

```hcl
create_datasync_task = false
datasync_task_arn   = "arn:aws:datasync:us-east-1:123456789012:task/task-1234567890abcdef0"
```

### 3. Opção B: Criar Data Sync Task Automaticamente

Se você quer que o Terraform crie o Data Sync Task:

```hcl
create_datasync_task    = true
datasync_role_arn       = "arn:aws:iam::123456789012:role/datasync-role"
destination_bucket_arn  = "arn:aws:s3:::meu-bucket-destino"
source_subdirectory     = "dados/"      # Opcional
destination_subdirectory = "backup/"     # Opcional
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

A Lambda usa as seguintes variáveis de ambiente:

- `SOURCE_BUCKET`: Nome do bucket S3 de origem (configurado automaticamente)
- `DELETE_PREFIX`: Prefixo opcional para filtrar arquivos (padrão: vazio = deleta tudo)

## Como Funciona

1. **Data Sync completa uma tarefa** com status `SUCCESS`
2. **EventBridge detecta o evento** e aciona a Lambda
3. **Lambda processa o evento**:
   - Valida que o Data Sync foi bem-sucedido
   - Lista todos os objetos no bucket de origem (opcionalmente filtrado por prefixo)
   - Deleta os objetos em lotes (até 1000 por vez)
   - Retorna o número de objetos deletados

## Logs

Os logs da Lambda estão disponíveis no CloudWatch:

```bash
aws logs tail /aws/lambda/data-sync-cleanup-dev --follow
```

## Teste Manual

Você pode testar a Lambda manualmente enviando um evento simulado:

```bash
aws lambda invoke \
  --function-name data-sync-cleanup-dev \
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

### Filtrar Arquivos por Prefixo

Para deletar apenas arquivos em um diretório específico:

```hcl
delete_prefix = "temp/"
```

### Ajustar Timeout e Memória

```hcl
lambda_timeout     = 600  # 10 minutos
lambda_memory_size = 512  # 512 MB
```

## Troubleshooting

### Lambda não está sendo acionada

1. Verifique se o EventBridge rule está ativo:
   ```bash
   aws events describe-rule --name data-sync-cleanup-dev-datasync-complete
   ```

2. Verifique os logs do EventBridge:
   ```bash
   aws logs tail /aws/events/rule/data-sync-cleanup-dev-datasync-complete --follow
   ```

### Erro de permissões

Verifique se a IAM role da Lambda tem as permissões corretas:
```bash
aws iam get-role-policy --role-name data-sync-cleanup-dev-lambda-role --policy-name data-sync-cleanup-dev-lambda-s3-policy
```

### Arquivos não estão sendo deletados

1. Verifique os logs da Lambda no CloudWatch
2. Confirme que o bucket e prefixo estão corretos
3. Verifique se há objetos no bucket que correspondem ao prefixo

## Limpeza

Para remover todos os recursos:

```bash
terraform destroy
```

**Atenção**: Isso também deletará o Data Sync Task se foi criado pelo Terraform.
