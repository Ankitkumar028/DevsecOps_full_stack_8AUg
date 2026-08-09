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
  # checkov:skip=CKV_AWS_144: Cross-region replication not needed for local tfstate
  # checkov:skip=CKV_AWS_18: Access logging not needed
  # checkov:skip=CKV_AWS_52: Event notifications not needed
  # checkov:skip=CKV_AWS_300: Lifecycle abort failed uploads not required
  # checkov:skip=CKV_AWS_145: KMS encryption not required for local tfstate
  # checkov:skip=CKV2_AWS_61: Lifecycle configuration not needed
  # checkov:skip=CKV2_AWS_62: Event notifications not needed
  bucket        = "${var.project_name}-tfstate-ankitkumar028"
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
  # checkov:skip=CKV_AWS_28: Point-in-time recovery not needed for terraform lock table
  # checkov:skip=CKV_AWS_24: PITR backup not needed for lock table
  # checkov:skip=CKV_AWS_119: Customer managed KMS not needed for lock table
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
