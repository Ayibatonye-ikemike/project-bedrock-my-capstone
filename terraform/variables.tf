variable "region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project prefix used in resource names."
  type        = string
  default     = "project-bedrock"
}

variable "cluster_name" {
  description = "EKS cluster name (graded — do not change)."
  type        = string
  default     = "project-bedrock-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster (>= 1.34)."
  type        = string
  default     = "1.34"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability Zones to spread subnets across."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "namespace" {
  description = "Kubernetes namespace for the retail application."
  type        = string
  default     = "retail-app"
}

variable "assets_bucket_name" {
  description = "Name of the S3 assets bucket (graded — must be globally unique)."
  type        = string
  default     = "bedrock-assets-alt-soe-025-4827"
}

variable "developer_user_name" {
  description = "IAM user name for read-only developer access (graded)."
  type        = string
  default     = "bedrock-dev-view"
}

variable "node_instance_types" {
  description = "Instance types for the EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "db_instance_class" {
  description = "RDS instance class for MySQL and PostgreSQL."
  type        = string
  default     = "db.t3.micro"
}

variable "cluster_admin_principal_arns" {
  description = "IAM principal ARNs (e.g. the bootstrap IAM user) granted EKS cluster-admin via access entries, in addition to the CI role."
  type        = list(string)
  default     = []
}
