###############################################################################
# EKS module — project-bedrock-cluster
#
# - Kubernetes >= 1.34
# - Managed node group in private subnets
# - Control-plane logging for all 5 log types -> CloudWatch
# - IRSA / OIDC enabled
# - AWS Load Balancer Controller installed via Helm (IRSA-backed)
# - API access entries (used by the developer RBAC module)
###############################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_endpoint_public_access = true

  # Cluster admins are declared explicitly (below) so access is deterministic
  # regardless of which principal runs `terraform apply` (local vs CI). The
  # caller-based "creator" entry is disabled to avoid drift between runners.
  enable_cluster_creator_admin_permissions = false

  # Control-plane logging -> CloudWatch (graded).
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  # Core managed add-ons.
  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      desired_size   = var.node_desired_size
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      capacity_type  = "ON_DEMAND"
    }
  }

  # Allow this account to use API + ConfigMap auth so the developer module can
  # add access entries.
  authentication_mode = "API_AND_CONFIG_MAP"

  # Explicit cluster-admin access entries: the CI/CD role (so GitHub Actions can
  # manage Helm/Kubernetes resources during apply) plus any bootstrap admin
  # principals (e.g. the IAM user used for local applies).
  access_entries = merge(
    var.ci_role_arn == "" ? {} : {
      ci = {
        principal_arn = var.ci_role_arn
        policy_associations = {
          admin = {
            policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = { type = "cluster" }
          }
        }
      }
    },
    {
      for idx, arn in var.admin_principal_arns : "admin_${idx}" => {
        principal_arn = arn
        policy_associations = {
          admin = {
            policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = { type = "cluster" }
          }
        }
      }
    }
  )
}

###############################################################################
# AWS Load Balancer Controller (for ALB ingress)
###############################################################################

module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name                              = "${var.cluster_name}-alb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.lb_controller_irsa.iam_role_arn
  }
  set {
    name  = "region"
    value = data.aws_region.current.name
  }
  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  depends_on = [module.eks]
}

data "aws_region" "current" {}
