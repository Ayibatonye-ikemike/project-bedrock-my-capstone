###############################################################################
# Data layer module
#
# Replaces the retail-store in-cluster databases with managed AWS services:
#   - catalog  -> Amazon RDS (MySQL)
#   - orders   -> Amazon RDS (PostgreSQL)
#   - carts    -> Amazon DynamoDB
#
# RDS lives in private subnets. Dedicated security groups allow DB traffic only
# from the EKS node security group. Credentials are random-generated and stored
# in AWS Secrets Manager (never hardcoded).
###############################################################################

# --- Random credentials -----------------------------------------------------

resource "random_password" "mysql" {
  length  = 20
  special = false
}

resource "random_password" "postgres" {
  length  = 20
  special = false
}

# --- Subnet group ------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# --- Security groups (DB ingress only from EKS nodes) ------------------------

resource "aws_security_group" "mysql" {
  name        = "${var.project_name}-mysql-sg"
  description = "Allow MySQL from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.node_security_group]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-mysql-sg" }
}

resource "aws_security_group" "postgres" {
  name        = "${var.project_name}-postgres-sg"
  description = "Allow PostgreSQL from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.node_security_group]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-postgres-sg" }
}

# --- RDS MySQL (catalog) -----------------------------------------------------

resource "aws_db_instance" "mysql" {
  identifier     = "${var.project_name}-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage   = 20
  storage_type        = "gp3"
  storage_encrypted   = true
  db_name             = "catalog"
  username            = "catalog_user"
  password            = random_password.mysql.result
  port                = 3306
  multi_az            = false
  publicly_accessible = false
  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.mysql.id]

  tags = { Name = "${var.project_name}-mysql" }
}

# --- RDS PostgreSQL (orders) -------------------------------------------------

resource "aws_db_instance" "postgres" {
  identifier     = "${var.project_name}-postgres"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage   = 20
  storage_type        = "gp3"
  storage_encrypted   = true
  db_name             = "orders"
  username            = "orders_user"
  password            = random_password.postgres.result
  port                = 5432
  multi_az            = false
  publicly_accessible = false
  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.postgres.id]

  tags = { Name = "${var.project_name}-postgres" }
}

# --- DynamoDB (carts) --------------------------------------------------------

resource "aws_dynamodb_table" "carts" {
  name         = "${var.project_name}-carts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Required by the retail-store cart service to look up carts by customer.
  attribute {
    name = "customerId"
    type = "S"
  }

  global_secondary_index {
    name            = "idx_global_customerId"
    hash_key        = "customerId"
    projection_type = "ALL"
  }

  tags = { Name = "${var.project_name}-carts" }
}

# --- Secrets Manager ---------------------------------------------------------

resource "aws_secretsmanager_secret" "mysql" {
  name                    = "${var.project_name}/catalog/mysql"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "mysql" {
  secret_id = aws_secretsmanager_secret.mysql.id
  secret_string = jsonencode({
    username = aws_db_instance.mysql.username
    password = random_password.mysql.result
    host     = aws_db_instance.mysql.address
    port     = aws_db_instance.mysql.port
    name     = aws_db_instance.mysql.db_name
  })
}

resource "aws_secretsmanager_secret" "postgres" {
  name                    = "${var.project_name}/orders/postgres"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id = aws_secretsmanager_secret.postgres.id
  secret_string = jsonencode({
    username = aws_db_instance.postgres.username
    password = random_password.postgres.result
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    name     = aws_db_instance.postgres.db_name
  })
}
