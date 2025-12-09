"""
Lambda function para apagar dados do bucket S3 após a cópia feita pelo Data Sync.

Esta função é acionada por um evento do EventBridge quando o Data Sync completa
uma tarefa de sincronização. Ela então apaga os arquivos do bucket de origem.
"""

import json
import os
import boto3
import logging
from typing import Dict, Any

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Clientes AWS
s3_client = boto3.client('s3')
datasync_client = boto3.client('datasync')

# Variáveis de ambiente
SOURCE_BUCKET = os.environ.get('SOURCE_BUCKET')
DELETE_PREFIX = os.environ.get('DELETE_PREFIX', '')  # Prefixo opcional para filtrar arquivos


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handler principal da Lambda.
    
    Args:
        event: Evento do EventBridge contendo informações sobre o Data Sync task
        context: Contexto da Lambda
    
    Returns:
        Dict com status code e mensagem
    """
    try:
        logger.info(f"Evento recebido: {json.dumps(event)}")
        
        # Validar variáveis de ambiente
        if not SOURCE_BUCKET:
            raise ValueError("SOURCE_BUCKET não está configurado nas variáveis de ambiente")
        
        # Extrair informações do evento do Data Sync
        task_arn = None
        execution_arn = None
        
        # Tentar extrair do evento do EventBridge (padrão Data Sync)
        if 'detail' in event:
            detail = event['detail']
            task_arn = detail.get('taskArn')
            execution_arn = detail.get('executionArn')
            
            # Verificar se a execução foi bem-sucedida
            status = detail.get('status', '').upper()
            if status != 'SUCCESS':
                logger.warning(f"Data Sync task não foi bem-sucedida. Status: {status}")
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': f'Data Sync não completou com sucesso. Status: {status}',
                        'taskArn': task_arn
                    })
                }
        
        # Se não encontrou no detail, tentar extrair diretamente do evento
        if not task_arn:
            task_arn = event.get('taskArn') or event.get('TaskArn')
            execution_arn = event.get('executionArn') or event.get('ExecutionArn')
        
        logger.info(f"Processando limpeza para task: {task_arn}")
        
        # Obter lista de arquivos copiados (opcional - pode ser usado para validação)
        files_copied = []
        if execution_arn:
            try:
                # Obter detalhes da execução para validar
                execution_detail = datasync_client.describe_task_execution(
                    TaskExecutionArn=execution_arn
                )
                logger.info(f"Detalhes da execução: {json.dumps(execution_detail, default=str)}")
            except Exception as e:
                logger.warning(f"Não foi possível obter detalhes da execução: {str(e)}")
        
        # Apagar arquivos do bucket de origem
        deleted_count = delete_files_from_bucket(SOURCE_BUCKET, DELETE_PREFIX)
        
        logger.info(f"Limpeza concluída. {deleted_count} objetos deletados do bucket {SOURCE_BUCKET}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Limpeza do bucket concluída com sucesso',
                'bucket': SOURCE_BUCKET,
                'deletedCount': deleted_count,
                'taskArn': task_arn,
                'executionArn': execution_arn
            })
        }
        
    except ValueError as e:
        logger.error(f"Erro de validação: {str(e)}")
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'Erro de validação',
                'message': str(e)
            })
        }
    except Exception as e:
        logger.error(f"Erro ao processar evento: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Erro interno',
                'message': str(e)
            })
        }


def delete_files_from_bucket(bucket_name: str, prefix: str = '') -> int:
    """
    Apaga todos os arquivos do bucket S3 que correspondem ao prefixo.
    
    Args:
        bucket_name: Nome do bucket S3
        prefix: Prefixo para filtrar arquivos (opcional)
    
    Returns:
        Número de objetos deletados
    """
    deleted_count = 0
    paginator = s3_client.get_paginator('list_objects_v2')
    
    try:
        # Listar e deletar objetos em lotes
        pages = paginator.paginate(Bucket=bucket_name, Prefix=prefix)
        
        for page in pages:
            if 'Contents' not in page:
                continue
            
            # Preparar lista de objetos para deletar (máximo 1000 por vez)
            objects_to_delete = [
                {'Key': obj['Key']} 
                for obj in page['Contents']
            ]
            
            if objects_to_delete:
                # Deletar em lote
                response = s3_client.delete_objects(
                    Bucket=bucket_name,
                    Delete={
                        'Objects': objects_to_delete,
                        'Quiet': True
                    }
                )
                
                deleted_count += len(objects_to_delete)
                logger.info(f"Deletados {len(objects_to_delete)} objetos do bucket {bucket_name}")
                
                # Verificar se houve erros
                if 'Errors' in response and response['Errors']:
                    for error in response['Errors']:
                        logger.error(f"Erro ao deletar {error['Key']}: {error['Message']}")
        
        # Se não havia prefixo, também deletar versões (se versionamento estiver habilitado)
        if not prefix:
            try:
                versions_paginator = s3_client.get_paginator('list_object_versions')
                versions_pages = versions_paginator.paginate(Bucket=bucket_name)
                
                for page in versions_pages:
                    # Deletar versões de objetos
                    if 'Versions' in page:
                        versions_to_delete = [
                            {'Key': v['Key'], 'VersionId': v['VersionId']}
                            for v in page['Versions']
                        ]
                        
                        if versions_to_delete:
                            s3_client.delete_objects(
                                Bucket=bucket_name,
                                Delete={
                                    'Objects': versions_to_delete,
                                    'Quiet': True
                                }
                            )
                    
                    # Deletar delete markers
                    if 'DeleteMarkers' in page:
                        markers_to_delete = [
                            {'Key': m['Key'], 'VersionId': m['VersionId']}
                            for m in page['DeleteMarkers']
                        ]
                        
                        if markers_to_delete:
                            s3_client.delete_objects(
                                Bucket=bucket_name,
                                Delete={
                                    'Objects': markers_to_delete,
                                    'Quiet': True
                                }
                            )
            except Exception as e:
                logger.warning(f"Não foi possível processar versões de objetos: {str(e)}")
        
        return deleted_count
        
    except s3_client.exceptions.NoSuchBucket:
        logger.error(f"Bucket {bucket_name} não encontrado")
        raise
    except Exception as e:
        logger.error(f"Erro ao deletar arquivos do bucket {bucket_name}: {str(e)}")
        raise
