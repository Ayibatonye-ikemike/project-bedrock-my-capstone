# Application Deployment — retail-store-sample-app

Deploys the AWS Retail Store Sample App into the `retail-app` namespace, wired
to the managed AWS data layer (RDS MySQL, RDS PostgreSQL, DynamoDB) created by
Terraform.

## Prerequisites
- Terraform `apply` completed (cluster, ALB controller, RDS, DynamoDB, secrets).
- `kubectl` and `helm` configured for the cluster:
  ```bash
  aws eks update-kubeconfig --region us-east-1 --name project-bedrock-cluster
  ```

## 1. Create the namespace
```bash
kubectl apply -f namespace.yaml
```

## 2. Sync DB credentials from Secrets Manager into Kubernetes secrets
Pull the values Terraform stored in Secrets Manager and create K8s secrets the
chart consumes (never commit these). Example for MySQL:
```bash
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id project-bedrock/catalog/mysql \
  --query SecretString --output text)

kubectl create secret generic catalog-db -n retail-app \
  --from-literal=RETAIL_CATALOG_PERSISTENCE_ENDPOINT="$(echo $SECRET | jq -r .host):$(echo $SECRET | jq -r .port)" \
  --from-literal=RETAIL_CATALOG_PERSISTENCE_DB_NAME="$(echo $SECRET | jq -r .name)" \
  --from-literal=RETAIL_CATALOG_PERSISTENCE_USER="$(echo $SECRET | jq -r .username)" \
  --from-literal=RETAIL_CATALOG_PERSISTENCE_PASSWORD="$(echo $SECRET | jq -r .password)"
```
Repeat for `orders` (PostgreSQL) using `project-bedrock/orders/postgres` and the
`orders-db` secret name.

## 3. Deploy via Helm (single command — bonus 5.1)
```bash
helm upgrade --install retail-store \
  oci://public.ecr.aws/aws-containers/retail-store-sample-app-chart \
  --namespace retail-app \
  --values values.yaml
```

> Adjust `host`/`name`/`tableName` placeholders in `values.yaml` using:
> ```bash
> cd ../terraform && terraform output
> ```

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
