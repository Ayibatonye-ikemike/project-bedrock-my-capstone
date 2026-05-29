###############################################################################
# VPC module — project-bedrock-vpc
#
# Public + private subnets across >= 2 AZs, single NAT gateway (cost), and the
# subnet tags required by the AWS Load Balancer Controller for ELB placement.
###############################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13"

  name = "project-bedrock-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  public_subnets  = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnets = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 4, i + 8)]

  enable_nat_gateway      = true
  single_nat_gateway      = true # one NAT to minimise cost
  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true

  # Tags that let the AWS Load Balancer Controller discover subnets.
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = {
    Name = "project-bedrock-vpc"
  }
}
