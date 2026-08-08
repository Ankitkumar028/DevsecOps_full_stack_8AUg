#!/usr/bin/env bash
# scripts/terraform-safe-destroy.sh
# Safely destroys the AWS environment + verifies no cost-generating resources remain
# Run before going offline to stay within free tier

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[✅] $1${NC}"; }
warn() { echo -e "${YELLOW}[⚠️ ] $1${NC}"; }

echo "================================================"
echo " Safe Terraform Destroy — Free Tier Protection"
echo "================================================"
warn "This will DESTROY: EC2, VPC, Subnets, Security Groups, S3 artifacts bucket"
warn "It will KEEP:      S3 state backend + DynamoDB lock table (< $1/month)"
echo ""
read -rp "Type 'destroy' to confirm: " confirm
[[ "$confirm" != "destroy" ]] && { echo "Aborted."; exit 0; }

cd "$(dirname "$0")/../infra/terraform"

log "Running terraform destroy..."
terraform destroy -auto-approve

echo ""
log "Verifying no cost-generating resources remain..."

# Check for leftover EC2 instances
INSTANCES=$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=devsecops-platform" "Name=instance-state-name,Values=running,stopped" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text 2>/dev/null || echo "")

if [[ -n "$INSTANCES" ]]; then
  warn "WARNING: EC2 instances still running: $INSTANCES"
  warn "Run: aws ec2 terminate-instances --instance-ids $INSTANCES"
else
  log "No EC2 instances running ✅"
fi

# Check for unattached Elastic IPs (charged even when idle)
EIPS=$(aws ec2 describe-addresses \
  --filters "Name=tag:Project,Values=devsecops-platform" \
  --query "Addresses[?AssociationId==null].AllocationId" \
  --output text 2>/dev/null || echo "")

if [[ -n "$EIPS" ]]; then
  warn "WARNING: Unattached Elastic IPs found: $EIPS (these cost money!)"
  warn "Release them: aws ec2 release-address --allocation-id <ID>"
else
  log "No unattached Elastic IPs ✅"
fi

echo ""
log "Environment destroyed safely. Resume with: terraform apply"
