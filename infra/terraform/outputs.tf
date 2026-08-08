output "instance_public_ip" {
  description = "Public IP of the k3s EC2 node"
  value       = aws_instance.k3s_node.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the k3s EC2 node"
  value       = aws_instance.k3s_node.public_dns
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.k3s_node.id
}

output "artifacts_bucket" {
  description = "S3 bucket for build artifacts"
  value       = aws_s3_bucket.artifacts.bucket
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_instance.k3s_node.public_ip}"
}
