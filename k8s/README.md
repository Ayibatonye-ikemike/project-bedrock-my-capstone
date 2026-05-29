# Application Deployment — retail-store-sample-app

Deploys the AWS Retail Store Sample App into the `retail-app` namespace, wired
to the managed AWS data layer (RDS MySQL, RDS PostgreSQL, DynamoDB) created by
Terraform.

> The upstream project now publishes **per-component** Helm charts to ECR
> Public (the old single `retail-store-sample-app-chart` no longer exists).
> Each microservice is installed from its own chart.

## Prerequisites
- Terraform `apply` completed (cluster, ALB controller, RDS, DynamoDB, secrets).
- `export AWS_PROFILE=capstone` set for every command below.
- `kubectl` and `helm` configured for the cluster:
  ```bash
  aws eks update-kubeconfig --region us-east-1 --name project-bedrock-cluster
  ```

## 1. Create the namespace
```bash
kubectl apply -f namespace.yaml
```

## 2. Build per-component values files (keep secrets out of git)
Pull the DB endpoints/passwords Terraform stored in Secrets Manager and write
them into local values files (e.g. under `/tmp`, never committed). The committed
`values.yaml` documents the schema with placeholders; substitute the real host
and password before deploying:
```bash
# MySQL (catalog)
aws secretsmanager get-secret-value --secret-id project-bedrock/catalog/mysql \
  --query SecretString --output text | jq

# PostgreSQL (orders)
aws secretsmanager get-secret-value --secret-id project-bedrock/orders/postgres \
  --query SecretString --output text | jq
```

## 3. Deploy each component via Helm
The cart service requires a global secondary index `idx_global_customerId` on
the DynamoDB table (provisioned by the `data` module), and the EKS node role is
granted DynamoDB access for `project-bedrock-carts`.

```bash
# catalog -> RDS MySQL
helm upgrade --install catalog \
  oci://public.ecr.aws/aws-containers/retail-store-sample-catalog-chart \
  -n retail-app --set fullnameOverride=catalog -f catalog-values.yaml --wait

# orders -> RDS PostgreSQL (messaging kept in-memory)
helm upgrade --install orders \
  oci://public.ecr.aws/aws-containers/retail-store-sample-orders-chart \
  -n retail-app --set fullnameOverride=orders -f orders-values.yaml --wait

# carts -> DynamoDB
helm upgrade --install carts \
  oci://public.ecr.aws/aws-containers/retail-store-sample-cart-chart \
  -n retail-app --set fullnameOverride=carts -f carts-values.yaml --wait

# checkout -> in-cluster redis (chart default)
helm upgrade --install checkout \
  oci://public.ecr.aws/aws-containers/retail-store-sample-checkout-chart \
  -n retail-app --set fullnameOverride=checkout --wait

# ui -> ClusterIP (exposed via ALB ingress, not a LoadBalancer)
helm upgrade --install ui \
  oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  -n retail-app --set fullnameOverride=ui --set service.type=ClusterIP --wait
```

Verify:
```bash
kubectl get pods,svc -n retail-app
```

## 4. Expose the UI via ALB
```bash
kubectl apply -f ingress.yaml
kubectl get ingress retail-ui -n retail-app   # wait for ADDRESS (ALB DNS)
```
Open the ALB DNS name in a browser to reach the store.

## 5. Verify developer RBAC (bedrock-dev-view)
Using the developer credentials:
```bash
kubectl get pods -n retail-app            # should succeed
kubectl delete pod <name> -n retail-app   # should be Forbidden
```
