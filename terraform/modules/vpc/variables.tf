variable "project_name" {
  description = "Project prefix."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Availability Zones."
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name (used for subnet discovery tags)."
  type        = string
}
