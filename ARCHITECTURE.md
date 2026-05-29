# Project Bedrock — Architecture

InnovateMart's production-grade microservices platform on AWS EKS.

## High-level diagram

```mermaid
flowchart TB
    user([Internet User])
    dev([bedrock-dev-view Developer])
    gh[GitHub Actions OIDC]

    subgraph AWS["AWS us-east-1 — Tag: Project=karatu-2025-capstone"]
        subgraph VPC["VPC: project-bedrock-vpc (10.0.0.0/16)"]
            subgraph PUB["Public Subnets (2 AZs)"]
                alb[Application Load Balancer]
                nat[NAT Gateway]
            end
            subgraph PRIV["Private Subnets (2 AZs)"]
                subgraph EKS["EKS: project-bedrock-cluster v1.34"]
                    albc[AWS LB Controller]
                    cwo[CloudWatch Observability Addon]
                    subgraph NS["namespace: retail-app"]
                        ui[ui]
                        catalog[catalog]
                        orders[orders]
                        carts[carts]
                        checkout[checkout]
                        broker[(RabbitMQ / Redis in-cluster)]
                    end
                end
                rdsmysql[(RDS MySQL - catalog)]
                rdspg[(RDS PostgreSQL - orders)]
            end
        end
        dynamo[(DynamoDB - carts)]
        secrets[Secrets Manager - DB creds]
        s3assets[(S3: bedrock-assets-alt-soe-025-4827)]
        lambda[Lambda: bedrock-asset-processor]
        cw[CloudWatch Logs: Control Plane + Containers]
        s3state[(S3 Terraform remote state)]
    end

    user -->|HTTPS| alb --> ui
    ui --> catalog & orders & carts & checkout
    catalog --> rdsmysql
    orders --> rdspg
    carts --> dynamo
    checkout --> broker
    secrets -.inject.-> NS
    cwo --> cw
    EKS -->|control plane logs| cw
    dev -->|ReadOnly + kubectl view| EKS
    dev -->|s3:PutObject| s3assets
    s3assets -->|S3 Event| lambda --> cw
    gh -->|plan / apply| AWS
    gh -.state.-> s3state
```

## Components

### Networking (`modules/vpc`)
- VPC `project-bedrock-vpc`, CIDR `10.0.0.0/16`.
- Public + private subnets across 2 AZs (`us-east-1a`, `us-east-1b`).
- Single NAT gateway (cost-optimised) for private egress.
- Subnet discovery tags for the AWS Load Balancer Controller.

### Compute (`modules/eks`)
- EKS `project-bedrock-cluster`, Kubernetes v1.34.
- Managed node group (`t3.medium`) in private subnets.
- Control-plane logging (api, audit, authenticator, controllerManager, scheduler) → CloudWatch.
- IRSA/OIDC enabled; AWS Load Balancer Controller installed via Helm.

### Data layer (`modules/data`)
- `catalog` → Amazon RDS **MySQL** (private subnets).
- `orders` → Amazon RDS **PostgreSQL** (private subnets).
- `carts` → Amazon **DynamoDB**.
- Dedicated security groups allow DB ports only from the EKS node security group.
- Credentials generated randomly and stored in **AWS Secrets Manager**.

### Developer access (`modules/iam-developer`)
- IAM user `bedrock-dev-view`.
- AWS console + API: `ReadOnlyAccess` + `s3:PutObject` on the assets bucket.
- Kubernetes: EKS access entry → group bound to the built-in `view` ClusterRole.

### Observability (`modules/observability`)
- Amazon CloudWatch Observability EKS add-on (CloudWatch Agent + Fluent Bit).
- Ships container logs and Container Insights to CloudWatch.

### Serverless (`modules/serverless`)
- Private S3 bucket `bedrock-assets-alt-soe-025-4827`.
- Lambda `bedrock-asset-processor` (Python 3.12) logs uploaded filenames.
- S3 `ObjectCreated` event notification triggers the Lambda.

### State & CI/CD
- Remote state in S3 (`bedrock-tfstate-alt-soe-025-4827`) with native lockfile.
- GitHub Actions: `terraform plan` on PR (commented), `terraform apply` on merge.
- AWS auth via GitHub OIDC role (no static keys in the repo).
```
