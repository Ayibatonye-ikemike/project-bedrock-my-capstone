output "mysql_endpoint" {
  description = "RDS MySQL endpoint."
  value       = aws_db_instance.mysql.address
}

output "postgres_endpoint" {
  description = "RDS PostgreSQL endpoint."
  value       = aws_db_instance.postgres.address
}

output "dynamodb_table_name" {
  description = "DynamoDB carts table name."
  value       = aws_dynamodb_table.carts.name
}

output "mysql_secret_arn" {
  description = "ARN of the MySQL credentials secret."
  value       = aws_secretsmanager_secret.mysql.arn
}

output "postgres_secret_arn" {
  description = "ARN of the PostgreSQL credentials secret."
  value       = aws_secretsmanager_secret.postgres.arn
}
