# Correção Automática de Erros com ML, Observabilidade e DevOps

Sistema de correção automatizada de erros baseado em Machine Learning, observabilidade e práticas DevOps.

## Arquitetura

- **AWS EKS**: Cluster Kubernetes para orquestração
- **S3**: Armazenamento de logs e artefatos de ML
- **CloudWatch**: Monitoramento e logs
- **MongoDB**: Banco de dados para estado e feedback
- **Grafana**: Dashboards de observabilidade
- **GitHub Actions**: CI/CD automatizado

## Estrutura do Projeto

```
.
├── app/                    # Serviço principal da aplicação
│   ├── src/               # Código fonte
│   └── tests/             # Testes
├── ml/                     # Serviço de Machine Learning
│   ├── service/           # API de inferência
│   └── training/          # Pipeline de treinamento
├── infra/                  # Infraestrutura como código
│   ├── terraform/         # Terraform (EKS, S3, CloudWatch)
│   └── helm/              # Helm charts
└── .github/workflows/      # GitHub Actions CI/CD
```

## Pré-requisitos

- AWS CLI configurado
- Terraform >= 1.5.0
- kubectl
- helm
- Docker
- Python 3.11+

## Configuração Inicial

### 1. Configurar AWS

```bash
aws configure
```

### 2. Aplicar Infraestrutura

```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```

### 3. Configurar Secrets no GitHub

Configure os seguintes secrets no GitHub (Settings > Secrets and variables > Actions):

- `AWS_ROLE_ARN`: ARN da role IAM para GitHub OIDC
- `AWS_REGION`: us-east-1
- `EKS_CLUSTER`: Nome do cluster EKS (ex: `tcc-auto-fix-dev`)
- `ECR_APP_REPO`: URL do repositório ECR para app
- `ECR_ML_REPO`: URL do repositório ECR para ml
- `ENV`: dev (ou stage/prod)

### 4. Deploy dos Serviços

Os serviços são deployados automaticamente via GitHub Actions quando há push para `app/` ou `ml/`.

Para deploy manual:

```bash
# App Service
helm upgrade --install app infra/helm/app-service \
  --set image.repository=<ECR_APP_REPO> \
  --set image.tag=latest

# ML Service
helm upgrade --install ml infra/helm/ml-service \
  --set image.repository=<ECR_ML_REPO> \
  --set image.tag=latest
```

## Observabilidade

O stack de observabilidade (Prometheus + Grafana) pode ser instalado via Terraform:

```bash
terraform apply -var 'enable_observability=true'
```

Ou manualmente:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install obs prometheus-community/kube-prometheus-stack \
  -n observability --create-namespace
```

## Desenvolvimento

### Executar App Localmente

```bash
cd app
pip install -r requirements.txt
uvicorn src.main:app --reload
```

### Executar ML Service Localmente

```bash
cd ml/service
pip install -r requirements.txt
uvicorn main:app --reload
```

## Testes

```bash
# App
cd app
pytest

# ML
cd ml
pytest
```

## Contribuindo

1. Crie uma branch para sua feature
2. Faça commit das mudanças
3. Abra um Pull Request

## Licença

Este projeto é parte de um trabalho de conclusão de curso (TCC).

