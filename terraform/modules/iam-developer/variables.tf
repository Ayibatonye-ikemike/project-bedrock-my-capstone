variable "user_name" {
  description = "IAM user name for the developer."
  type        = string
}

variable "assets_bucket_arn" {
  description = "ARN of the S3 assets bucket (for s3:PutObject grant)."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name (for the access entry)."
  type        = string
}
