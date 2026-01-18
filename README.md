# Terraform QA UI Infrastructure

This repository contains Terraform configuration for the QA UI infrastructure, specifically the ECR repository and IAM roles for GitHub Actions CI/CD.

## Resources Created

- **ECR Repository**: `intelfoundry-qa-ui` - Stores QA UI Docker images
- **ECR Lifecycle Policy**: Keeps last 30 QA images, removes untagged after 7 days
- **IAM Role**: GitHub Actions role for pushing images to ECR via OIDC

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0.0
3. **GitHub OIDC Provider** configured in AWS IAM

### Setting up GitHub OIDC Provider

If you haven't set up the GitHub OIDC provider in AWS, create it first:

```bash
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## Usage

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

## Outputs

After applying, you'll get:
- `ecr_repository_url`: Use this in your Docker push commands
- `github_actions_role_arn`: Add this as `AWS_ROLE_ARN` secret in GitHub

## GitHub Actions Setup

After applying this Terraform, add the following secret to the `design-QA` repository:

- **AWS_ROLE_ARN**: The value from `github_actions_role_arn` output

## Image Tagging Convention

Images pushed to this ECR repository follow this naming convention:
- `qa-{git-sha}` - Specific commit
- `qa-latest` - Latest QA build

## Related Repositories

- [design-QA](https://github.com/The-Cyber-Samaritans/design-QA) - QA UI source code
- [ux-ui](https://github.com/The-Cyber-Samaritans/ux-ui) - Main UI repository
