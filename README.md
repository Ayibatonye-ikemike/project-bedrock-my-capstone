# Project Bedrock — InnovateMart EKS Deployment

Production-grade microservices platform on AWS EKS for InnovateMart's Retail Store
Sample App. Provisioned end-to-end with Terraform, secured for developer hand-off,
observable via CloudWatch, and extended with an event-driven serverless pipeline.

> AltSchool of Cloud Engineering — Karatu 2025, Capstone (Project Bedrock).

## Standards & Naming (must not change)

| Resource | Value |
|---|---|
| AWS Region | `us-east-1` |
| EKS Cluster | `project-bedrock-cluster` (>= v1.34) |
| VPC Name tag | `project-bedrock-vpc` |
| App Namespace | `retail-app` |
| Developer IAM user | `bedrock-dev-view` |
| S3 assets bucket | `bedrock-assets-alt-soe-025-4827` |
| Lambda function | `bedrock-asset-processor` |
| Global tag | `Project = karatu-2025-capstone` |

Required root outputs: `cluster_endpoint`, `cluster_name`, `region`, `vpc_id`,
`assets_bucket_name`.

## Repository layout

```
My-Capstone-Project/
├── bootstrap/           # one-time: creates the S3 remote-state bucket
├── terraform/           # root module + child modules (the real infra)
│   └── modules/
│       ├── vpc/
│       ├── eks/
│       ├── data/
│       ├── iam-developer/
│       ├── serverless/
│       └── observability/
├── k8s/                 # namespace, RBAC, ingress, app values
├── lambda/              # bedrock-asset-processor source
└── .github/workflows/   # CI/CD (plan on PR, apply on merge)
```

## Deployment guide

### 0. Prerequisites
- Terraform >= 1.6, AWS CLI v2 (authenticated to account in `us-east-1`),
  `kubectl`, `helm`.

### 1. Bootstrap remote state (run once)
```bash
cd bootstrap
terraform init
terraform apply            # creates the versioned, encrypted state bucket
```
Copy the output bucket name into `terraform/backend.tf`.

### 2. Provision infrastructure
```bash
cd ../terraform
terraform init
terraform plan
terraform apply
```

### 3. Configure kubectl
```bash
aws eks update-kubeconfig --region us-east-1 --name project-bedrock-cluster
kubectl get nodes
```

### 4. Deploy the application
See [k8s/README.md](k8s/README.md) (or the Helm command once added).

### 5. Generate grading data
```bash
cd terraform
terraform output -json > ../grading.json
```

## Cost warning
EKS control plane, NAT gateway, 2x RDS, and the ALB bill continuously. Run
`terraform destroy` when not actively working.
