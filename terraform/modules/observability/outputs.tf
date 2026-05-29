output "addon_arn" {
  description = "ARN of the CloudWatch Observability add-on."
  value       = aws_eks_addon.cw_observability.arn
}
