locals {
  project          = "tcc-auto-fix"
  env              = var.environment
  eks_cluster_name = "${local.project}-${local.env}"
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.project}-${local.env}-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.0"
  cluster_name    = local.eks_cluster_name
  cluster_version = "1.29"

  manage_aws_auth_configmap = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.large"]
      desired_size   = 2
      min_size       = 2
      max_size       = 4
    }
  }
}

resource "aws_ecr_repository" "app" {
  name = "${local.project}/app"
}

resource "aws_ecr_repository" "ml" {
  name = "${local.project}/ml"
}

resource "aws_s3_bucket" "logs" {
  bucket        = "${local.project}-${local.env}-${var.aws_region}-logs"
  force_destroy = true
}

resource "aws_s3_bucket" "ml_artifacts" {
  bucket        = "${local.project}-${local.env}-${var.aws_region}-ml-artifacts"
  force_destroy = true
}

resource "aws_s3_bucket" "observability" {
  bucket        = "${local.project}-${local.env}-${var.aws_region}-obs"
  force_destroy = true
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/eks/${local.eks_cluster_name}/app"
  retention_in_days = 14
}

resource "aws_iam_role" "irsa_otel" {
  name               = "${local.eks_cluster_name}-otel"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role.json
}

data "aws_iam_policy_document" "irsa_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider_arn, "arn:aws:iam::", "")}:sub"
      values   = ["system:serviceaccount:observability:otel-collector"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "irsa_otel_logs" {
  role       = aws_iam_role.irsa_otel.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Secrets (random) stored in SSM Parameter Store for pipelines
resource "random_password" "app_db_password" {
  length  = 16
  special = false
}

resource "random_password" "ml_db_password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "app_db_password" {
  name  = "/${local.project}/${local.env}/app_db_password"
  type  = "SecureString"
  value = random_password.app_db_password.result
}

resource "aws_ssm_parameter" "ml_db_password" {
  name  = "/${local.project}/${local.env}/ml_db_password"
  type  = "SecureString"
  value = random_password.ml_db_password.result
}

# Optional: deploy kube-prometheus-stack via Helm (can be toggled)
resource "helm_release" "kube_prometheus_stack" {
  count      = var.enable_observability ? 1 : 0
  name       = "obs"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "observability"
  create_namespace = true
  timeout    = 600
}

data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# Outputs kept minimal to avoid clutter; add more as needed.
output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_app_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecr_ml_repository_url" {
  value = aws_ecr_repository.ml.repository_url
}

output "ssm_app_db_password" {
  value = aws_ssm_parameter.app_db_password.name
}

output "ssm_ml_db_password" {
  value = aws_ssm_parameter.ml_db_password.name
}



