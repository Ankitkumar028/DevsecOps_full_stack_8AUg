terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state — S3 backend + DynamoDB locking
  # Provisioned separately via infra/terraform/bootstrap/
  backend "s3" {
    bucket         = "devsecops-platform-tfstate"
    key            = "core/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devsecops-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devsecops-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
