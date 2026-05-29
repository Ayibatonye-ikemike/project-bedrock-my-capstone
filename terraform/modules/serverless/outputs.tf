output "assets_bucket_name" {
  description = "Name of the assets bucket."
  value       = aws_s3_bucket.assets.id
}

output "assets_bucket_arn" {
  description = "ARN of the assets bucket."
  value       = aws_s3_bucket.assets.arn
}

output "lambda_function_name" {
  description = "Name of the asset processor Lambda."
  value       = aws_lambda_function.asset_processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the asset processor Lambda."
  value       = aws_lambda_function.asset_processor.arn
}
