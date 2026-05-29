###############################################################################
# GitHub Actions OIDC role
#
# Lets the CI/CD workflow assume an AWS role via OIDC (no long-lived keys).
# Created in bootstrap because the pipeline itself relies on this role.
#
# Trust is scoped to a single GitHub repository.
###############################################################################

variable "github_owner" {
  description = "GitHub org/user that owns the repo (must match the login casing used in the OIDC 'sub' claim)."
  type        = string
  default     = "Ayibatonye-ikemike"
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
  default     = "project-bedrock-my-capstone"
}

# GitHub's OIDC provider thumbprint is no longer validated by AWS, but the
# resource still requires the provider URL + audience.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # Accept the configured owner casing as well as a lower-cased variant,
      # since the OIDC 'sub' claim casing must match exactly (StringLike is
      # case-sensitive).
      values = [
        "repo:${var.github_owner}/${var.github_repo}:*",
        "repo:${lower(var.github_owner)}/${var.github_repo}:*",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "project-bedrock-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}

# Broad permissions so the pipeline can manage the full stack. Scope down later
# for least privilege if desired.
resource "aws_iam_role_policy_attachment" "github_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_role_arn" {
  description = "Set this as the AWS_ROLE_ARN repository variable in GitHub."
  value       = aws_iam_role.github_actions.arn
}
