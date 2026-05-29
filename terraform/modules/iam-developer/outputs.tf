output "access_key_id" {
  description = "Access Key ID for bedrock-dev-view."
  value       = aws_iam_access_key.developer.id
}

output "secret_access_key" {
  description = "Secret Access Key for bedrock-dev-view."
  value       = aws_iam_access_key.developer.secret
  sensitive   = true
}

output "console_password" {
  description = "Console login password for bedrock-dev-view."
  value       = aws_iam_user_login_profile.developer.password
  sensitive   = true
}

output "user_arn" {
  description = "ARN of the developer IAM user."
  value       = aws_iam_user.developer.arn
}
