variable "project_name" {
  description = "Project prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "node_security_group" {
  description = "EKS node security group ID allowed to reach the databases."
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
}
