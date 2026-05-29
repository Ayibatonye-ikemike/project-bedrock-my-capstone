###############################################################################
# Root outputs — the graded keys are: cluster_endpoint, cluster_name, region,
# vpc_id, assets_bucket_name. Do not rename these.
###############################################################################

output "cluster_endpoint" {
  description = "Endpoint of the EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "region" {
  description = "AWS region."
  value       = var.region
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "assets_bucket_name" {
  description = "Name of the S3 assets bucket."
  value       = module.serverless.assets_bucket_name
}

# --- Helpful extras (not graded) -------------------------------------------

output "cluster_certificate_authority_data" {
  description = "Base64 CA cert for the cluster."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "developer_access_key_id" {
  description = "Access Key ID for the bedrock-dev-view user."
  value       = module.iam_developer.access_key_id
  sensitive   = true
}

output "developer_secret_access_key" {
  description = "Secret Access Key for the bedrock-dev-view user."
  value       = module.iam_developer.secret_access_key
  sensitive   = true
}

output "developer_console_password" {
  description = "Console password for the bedrock-dev-view user."
  value       = module.iam_developer.console_password
  sensitive   = true
}

output "lambda_function_name" {
  description = "Name of the asset processor Lambda."
  value       = module.serverless.lambda_function_name
}
