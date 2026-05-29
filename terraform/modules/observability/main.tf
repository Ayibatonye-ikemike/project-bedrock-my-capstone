###############################################################################
# Observability module
#
# Installs the Amazon CloudWatch Observability EKS add-on, which deploys the
# CloudWatch Agent + Fluent Bit to ship container logs and Container Insights
# metrics to CloudWatch. (Control-plane logging is enabled in the EKS module.)
###############################################################################

# IRSA role the add-on uses to write to CloudWatch.
module "cw_observability_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name = "${var.cluster_name}-cw-observability"

  role_policy_arns = {
    cloudwatch = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["amazon-cloudwatch:cloudwatch-agent"]
    }
  }
}

resource "aws_eks_addon" "cw_observability" {
  cluster_name             = var.cluster_name
  addon_name               = "amazon-cloudwatch-observability"
  service_account_role_arn = module.cw_observability_irsa.iam_role_arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}
