###############################################################################
# Root module — wires the child modules together.
###############################################################################

locals {
  common_tags = {
    Project = "karatu-2025-capstone"
  }
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  azs          = var.azs
  cluster_name = var.cluster_name
}

module "eks" {
  source = "./modules/eks"

  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
}

module "data" {
  source = "./modules/data"

  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  node_security_group = module.eks.node_security_group_id
  db_instance_class   = var.db_instance_class
}

module "iam_developer" {
  source = "./modules/iam-developer"

  user_name         = var.developer_user_name
  assets_bucket_arn = module.serverless.assets_bucket_arn
  cluster_name      = module.eks.cluster_name
}

module "observability" {
  source = "./modules/observability"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn

  depends_on = [module.eks]
}

module "serverless" {
  source = "./modules/serverless"

  assets_bucket_name = var.assets_bucket_name
}
