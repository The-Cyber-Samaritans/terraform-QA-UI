# Terraform configuration for QA UI ECR Repository
# This creates and manages the ECR repository for QA UI Docker images

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration - update with your S3 bucket for state storage
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "qa-ui/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "IntelFoundry"
      Environment = "QA"
      ManagedBy   = "Terraform"
      Repository  = "terraform-QA-UI"
    }
  }
}

# ECR Repository for QA UI
resource "aws_ecr_repository" "qa_ui" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = var.ecr_repository_name
    Environment = "QA"
    Application = "UI"
  }
}

# ECR Lifecycle Policy - Keep last 10 QA images and clean up untagged
resource "aws_ecr_lifecycle_policy" "qa_ui" {
  repository = aws_ecr_repository.qa_ui.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 QA tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["qa-", "QA-"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository Policy - Allow GitHub Actions to push images
resource "aws_ecr_repository_policy" "qa_ui" {
  repository = aws_ecr_repository.qa_ui.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPushPull"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_aws_principals
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}

# IAM Role for GitHub Actions OIDC
resource "aws_iam_role" "github_actions" {
  name = "github-actions-qa-ui-ecr"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.github_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:The-Cyber-Samaritans/design-QA:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "GitHub Actions QA UI ECR Role"
  }
}

# IAM Policy for ECR access
resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "ecr-push-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
        Resource = aws_ecr_repository.qa_ui.arn
      }
    ]
  })
}
