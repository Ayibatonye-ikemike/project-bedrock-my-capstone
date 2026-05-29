###############################################################################
# Developer access module — bedrock-dev-view
#
# Two layers of access:
#   1. AWS Console / API: managed ReadOnlyAccess + s3:PutObject on the assets
#      bucket (so the grader can upload a test object and trigger the Lambda).
#   2. Kubernetes: EKS access entry mapping the user into a group bound to the
#      built-in "view" ClusterRole (read-only). The user can `kubectl get pods`
#      but not `kubectl delete pod`.
###############################################################################

resource "aws_iam_user" "developer" {
  name = var.user_name
  tags = { Name = var.user_name }
}

# Console login profile (password). Output is sensitive.
resource "aws_iam_user_login_profile" "developer" {
  user                    = aws_iam_user.developer.name
  password_length         = 20
  password_reset_required = false
}

resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}

# Layer 1a: AWS managed ReadOnlyAccess.
resource "aws_iam_user_policy_attachment" "readonly" {
  user       = aws_iam_user.developer.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Layer 1b: s3:PutObject on the assets bucket only.
resource "aws_iam_user_policy" "s3_put" {
  name = "${var.user_name}-s3-put-assets"
  user = aws_iam_user.developer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "PutAssets"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${var.assets_bucket_arn}/*"
      }
    ]
  })
}

# Layer 2a: EKS access entry — maps the IAM user into a Kubernetes group.
resource "aws_eks_access_entry" "developer" {
  cluster_name      = var.cluster_name
  principal_arn     = aws_iam_user.developer.arn
  kubernetes_groups = ["bedrock-viewers"]
  type              = "STANDARD"
}

# Layer 2b: bind that group to the built-in read-only "view" ClusterRole.
resource "kubernetes_cluster_role_binding" "developer_view" {
  metadata {
    name = "bedrock-dev-view-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }

  subject {
    kind      = "Group"
    name      = "bedrock-viewers"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [aws_eks_access_entry.developer]
}
