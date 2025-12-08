# Observabilidade no EKS

 usar `kube-prometheus-stack` como base (Prometheus, Grafana, Alertmanager) e um OpenTelemetry Collector DaemonSet exportando para CloudWatch Logs e X-Ray.

Passos:
1) Adicionar repositório Helm: `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
2) Instalar: `helm upgrade --install obs prometheus-community/kube-prometheus-stack -n observability --create-namespace -f values.yaml`
3) Implantar o Otel Collector com IRSA (role em `infra/terraform/main.tf`).

Proximos passos - Criar dashboards para: ***EM ANDAMENTO
- Erros por serviço (5xx, exceptions)
- Latência p95/p99
- Taxa de sucesso de correções automáticas
- Comparação antes/depois da correção (SLI/SLO)


