# Descrição Objetiva do Projeto: Sistema de Correção Automática de Erros

## Recursos do Projeto

### Infraestrutura Cloud (AWS)
- **EKS (Elastic Kubernetes Service)**: Cluster Kubernetes gerenciado para orquestração de containers
- **ECR (Elastic Container Registry)**: Repositórios Docker para imagens dos serviços app e ml
- **S3**: Armazenamento de logs, artefatos de ML e dados de observabilidade
- **CloudWatch**: Agregação e monitoramento de logs da aplicação
- **VPC**: Rede isolada com subnets públicas e privadas, NAT Gateway
- **SSM Parameter Store**: Armazenamento seguro de senhas e configurações

### Serviços de Aplicação
- **app-service**: API FastAPI que recebe eventos de erro, consulta o serviço de ML e registra feedback
- **ml-service**: API FastAPI para inferência de modelos de ML (classificação e sugestão de correções)
- **ml-training**: Pipeline de treinamento de modelos usando dados de logs e feedback

### Observabilidade
- **Prometheus**: Coleta de métricas do cluster e aplicações
- **Grafana**: Dashboards para visualização de métricas e logs
- **OpenTelemetry Collector**: Coleta de traces e logs distribuídos
- **CloudWatch Logs**: Agregação centralizada de logs

### DevOps e CI/CD
- **GitHub Actions**: Pipeline automatizado de build, teste e deploy
- **Terraform**: Infraestrutura como código (IaC) para provisionamento AWS
- **Helm**: Gerenciamento de charts Kubernetes para deploy dos serviços
- **Docker**: Containerização dos serviços

### Banco de Dados
- **MongoDB**: Armazenamento de eventos de erro, sugestões de correção e feedback dos usuários

## Como o Sistema Funciona

### Fluxo Principal de Correção de Erros

1. **Recepção de Erro**
   - Um evento de erro é enviado para o endpoint `POST /errors` do app-service
   - O erro contém informações como: mensagem, stack trace, contexto da aplicação, timestamp

2. **Classificação e Sugestão (ML)**
   - O app-service encaminha o erro para o ml-service via endpoint `POST /predict`
   - O ml-service processa o erro usando modelo de ML treinado:
     - Classifica o tipo de erro (ex: config_issue, dependency_error, timeout)
     - Gera sugestão de ação (ex: restart_pod, update_config, scale_up)
     - Retorna nível de confiança da sugestão

3. **Armazenamento e Feedback**
   - O app-service registra o erro e a sugestão no MongoDB
   - Logs são enviados para S3 e CloudWatch
   - O sistema retorna a sugestão ao cliente

4. **Aprendizado Contínuo**
   - Quando uma correção é aplicada, feedback é enviado via `POST /feedback`
   - O feedback é armazenado no MongoDB com labels (correto/incorreto)
   - O pipeline de treinamento (ml-training) processa periodicamente:
     - Extrai features de logs em S3
     - Combina com labels do MongoDB
     - Treina novo modelo (LightGBM/Sklearn)
     - Salva artefatos no S3 (bucket ml_artifacts)
     - Atualiza o ml-service com nova versão do modelo

### Pipeline CI/CD

1. **Desenvolvimento**
   - Desenvolvedor faz push de código para GitHub
   - GitHub Actions detecta mudanças em `app/` ou `ml/`

2. **Build e Teste**
   - Executa testes unitários (pytest)
   - Build da imagem Docker
   - Push da imagem para ECR

3. **Deploy**
   - Autenticação no EKS via OIDC
   - Atualização do Helm chart no cluster
   - Rolling update dos pods

### Observabilidade

- **Métricas**: Prometheus coleta métricas de CPU, memória, latência, taxa de erro
- **Logs**: CloudWatch agrega logs de todos os serviços
- **Traces**: OpenTelemetry rastreia requisições entre serviços
- **Dashboards**: Grafana visualiza métricas e logs em tempo real

### Infraestrutura

- **Terraform**: Provisiona toda infraestrutura AWS (EKS, S3, ECR, VPC, CloudWatch)
- **Helm**: Gerencia deploy dos serviços no Kubernetes
- **IRSA (IAM Roles for Service Accounts)**: Permissões seguras para pods acessarem AWS

## Tecnologias Utilizadas

- **Backend**: Python 3.11+, FastAPI, Uvicorn
- **ML**: Scikit-learn, LightGBM (planejado)
- **Infraestrutura**: AWS (EKS, S3, ECR, CloudWatch), Terraform, Helm
- **Containerização**: Docker
- **Orquestração**: Kubernetes (EKS)
- **CI/CD**: GitHub Actions
- **Observabilidade**: Prometheus, Grafana, OpenTelemetry
- **Banco de Dados**: MongoDB
- **Monitoramento**: CloudWatch Logs

## Diagrama de Arquitetura

O diagrama de arquitetura visual está disponível no arquivo `arquitetura_sistema.jpg`, mostrando:
- Camada de Desenvolvimento & CI/CD (GitHub, GitHub Actions, Terraform, Helm)
- Infraestrutura AWS (VPC, EKS, ECR, S3, CloudWatch, SSM)
- Serviços no EKS (app-service, ml-service, Observability Stack, MongoDB)
- Pipeline de Treinamento ML
- Fluxos de dados entre componentes


