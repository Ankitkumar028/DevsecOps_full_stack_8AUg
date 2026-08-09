# ─────────────────────────────────────────────────────
#  Bootstrap: S3 bucket + DynamoDB table for TF state
#  Uses a FIXED bucket name so main.tf backend can reference it
# ─────────────────────────────────────────────────────
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  # No remote backend here — this is the bootstrap itself
}

provider "aws" { region = var.aws_region }

variable "aws_region" { default = "us-east-1" }
variable "project_name" { default = "devsecops" }

resource "aws_s3_bucket" "tfstate" {
  bucket        = "${var.project_name}-platform-tfstate"
  force_destroy = true
  tags          = { Name = "terraform-state" }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tflock" {
  name         = "${var.project_name}-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = { Name = "terraform-state-lock" }
}

output "state_bucket_name" { value = aws_s3_bucket.tfstate.bucket }
output "lock_table_name" { value = aws_dynamodb_table.tflock.name }
