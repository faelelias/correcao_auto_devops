# Terraform (EKS, ECR, S3, CloudWatch)

Componentes principais:
- EKS (cluster + node groups)
- ECR (repositórios app e ml)
- S3 (logs e artefatos de ML)
- CloudWatch Log Group
- IRSA para o OpenTelemetry Collector

Como usar:
1) Região: `aws_region` (default `us-east-1`).
2) Rede: ajuste `vpc_cidr`, `azs`, `private_subnet_cidrs`, `public_subnet_cidrs`.
3) `terraform init`
4) `terraform plan`
5) `terraform apply`

Customize:
- Ajuste tipos de instância, escalabilidade e políticas de IAM conforme necessário.
- Adicione buckets adicionais ou integrações (ex: X-Ray, Secrets Manager).
- `enable_observability` liga/desliga a instalação do `kube-prometheus-stack`.


