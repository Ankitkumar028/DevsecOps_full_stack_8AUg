variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Short project prefix used in resource names"
  type        = string
  default     = "devsecops"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the single public subnet (no NAT Gateway needed)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type — upgraded to t3.medium (2 vCPU, 4GB RAM) for high performance"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the existing EC2 Key Pair for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Your public IP in CIDR notation for SSH access (e.g. 1.2.3.4/32)"
  type        = string
  sensitive   = true
}

variable "ami_id" {
  description = "AMI ID — defaults to Amazon Linux 2023 in us-east-1"
  type        = string
  default     = "ami-0182f373e66f89c85"   # Amazon Linux 2023 us-east-1 (update as needed)
}
