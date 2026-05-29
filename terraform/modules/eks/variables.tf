variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for nodes."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired node count."
  type        = number
}

variable "node_min_size" {
  description = "Minimum node count."
  type        = number
}

variable "node_max_size" {
  description = "Maximum node count."
  type        = number
}

variable "ci_role_arn" {
  description = "IAM role ARN (GitHub Actions OIDC) to grant cluster-admin access via an EKS access entry. Empty disables it."
  type        = string
  default     = ""
}

variable "admin_principal_arns" {
  description = "Additional IAM principal ARNs (e.g. the bootstrap IAM user) to grant cluster-admin via EKS access entries."
  type        = list(string)
  default     = []
}
