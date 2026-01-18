# Terraform QA UI Infrastructure

This repository contains Terraform configuration and Kubernetes manifests for the QA UI infrastructure.

## Architecture

- **Domain**: `qa-cloud.intelfoundry.onceamerican.com`
- **Namespace**: `ns-qa`
- **Backend**: Uses dev services (`api.dev.intelfoundry.net`, `auth.dev.intelfoundry.net`)
- **ECR Repository**: `intelfoundry-qa-ui`

## Resources Created

### Terraform (AWS)
- **ECR Repository**: `intelfoundry-qa-ui` - Stores QA UI Docker images
- **ECR Lifecycle Policy**: Keeps last 30 QA images, removes untagged after 7 days
- **IAM Role**: GitHub Actions role for pushing images to ECR via OIDC

### Kubernetes (k8s/)
- **Namespace**: `ns-qa`
- **Deployment**: QA UI frontend (2 replicas)
- **Service**: ClusterIP service for internal routing
- **Cloudflared**: Tunnel for exposing via Cloudflare
- **PodDisruptionBudget**: Ensures availability during updates

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0.0
3. **kubectl** configured for your cluster
4. **GitHub OIDC Provider** configured in AWS IAM
5. **Cloudflare Tunnel** created for `qa-cloud.intelfoundry.onceamerican.com`

### Setting up GitHub OIDC Provider

If you haven't set up the GitHub OIDC provider in AWS, create it first:

```bash
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## Terraform Usage

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your AWS account details:
   - Set your GitHub OIDC provider ARN
   - Adjust other variables as needed

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the plan:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Kubernetes Deployment

### 1. Update kustomization.yaml

Edit `k8s/kustomization.yaml` and replace `YOUR_AWS_ACCOUNT_ID` with your actual AWS account ID:

```yaml
images:
  - name: ${ECR_REPOSITORY_URL}
    newName: YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/intelfoundry-qa-ui
    newTag: qa-latest
```

### 2. Create Cloudflare Tunnel

Create a Cloudflare Tunnel for the QA environment:

```bash
# Using Cloudflare API or dashboard, create a tunnel
# Configure it to route:
#   qa-cloud.intelfoundry.onceamerican.com -> http://qa-ui.ns-qa.svc.cluster.local:80
```

### 3. Store Tunnel Token

Get the tunnel token and create the secret:

```bash
# Replace with your actual tunnel token
export CLOUDFLARE_TUNNEL_TOKEN="your-tunnel-token"

kubectl create namespace ns-qa --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic cloudflared-qa-tunnel-token \
    --namespace=ns-qa \
    --from-literal=token="${CLOUDFLARE_TUNNEL_TOKEN}"
```

### 4. Deploy with Kustomize

```bash
# Preview the deployment
kubectl kustomize k8s/

# Apply the deployment
kubectl apply -k k8s/
```

### 5. Verify Deployment

```bash
# Check pods
kubectl get pods -n ns-qa

# Check services
kubectl get svc -n ns-qa

# Check cloudflared logs
kubectl logs -n ns-qa -l app=cloudflared
```

## Terraform Outputs

After applying, you'll get:
- `ecr_repository_url`: Use this in your Docker push commands
- `github_actions_role_arn`: Add this as `AWS_ROLE_ARN` secret in GitHub

## GitHub Actions Setup

After applying this Terraform, add the following secret to the `design-QA` repository:

- **AWS_ROLE_ARN**: The value from `github_actions_role_arn` output

The following variables are already configured:
- `VITE_API_URL`: https://api.dev.intelfoundry.net
- `VITE_KEYCLOAK_URL`: https://auth.dev.intelfoundry.net
- `VITE_KEYCLOAK_REALM`: intelfoundry
- `VITE_KEYCLOAK_CLIENT_ID`: intelfoundry-ui

## Image Tagging Convention

Images pushed to this ECR repository follow this naming convention:
- `qa-{git-sha}` - Specific commit
- `qa-{timestamp}-{git-sha}` - Timestamped version
- `qa-latest` - Latest QA build

## Related Repositories

- [design-QA](https://github.com/The-Cyber-Samaritans/design-QA) - QA UI source code
- [ux-ui](https://github.com/The-Cyber-Samaritans/ux-ui) - Main UI repository
