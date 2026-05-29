region          = "us-east-1"
project_name    = "project-bedrock"
cluster_name    = "project-bedrock-cluster"
cluster_version = "1.34"
vpc_cidr        = "10.0.0.0/16"
azs             = ["us-east-1a", "us-east-1b"]
namespace       = "retail-app"

assets_bucket_name  = "bedrock-assets-alt-soe-025-4827"
developer_user_name = "bedrock-dev-view"

node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3

db_instance_class = "db.t3.micro"
