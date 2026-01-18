# Outputs for QA UI Terraform Configuration

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.qa_ui.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.qa_ui.arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.qa_ui.name
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.name
}
