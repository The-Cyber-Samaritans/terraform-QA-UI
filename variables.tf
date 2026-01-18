# Variables for QA UI Terraform Configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository for QA UI"
  type        = string
  default     = "intelfoundry-qa-ui"
}

variable "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider in AWS"
  type        = string
  # Example: arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
}

variable "allowed_aws_principals" {
  description = "List of AWS principals allowed to push/pull from ECR"
  type        = list(string)
  default     = []
}
