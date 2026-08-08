## GitHub Secrets Required

Configure these in **Settings → Secrets and variables → Actions**:

| Secret | Description | Where to get it |
|--------|-------------|-----------------|
| `AWS_ACCESS_KEY_ID` | IAM user access key for Terraform | AWS Console → IAM → Users → Security credentials |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key | Same as above |
| `TF_VAR_KEY_NAME` | EC2 Key Pair name (no `.pem`) | AWS Console → EC2 → Key Pairs |
| `TF_VAR_ALLOWED_SSH_CIDR` | Your public IP in CIDR e.g. `1.2.3.4/32` | `curl ifconfig.me` |
| `APP_URL` | Public URL of the deployed app for ZAP DAST | `http://<EC2-IP>:5000` |
| `SEMGREP_APP_TOKEN` | Semgrep token (optional — free tier available) | [semgrep.dev](https://semgrep.dev) |

## IAM Policy for Terraform

Create an IAM user with **programmatic access** and attach this minimum policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*", "vpc:*",
        "s3:*",
        "dynamodb:*",
        "iam:CreateServiceLinkedRole",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

> **Tip**: Scope this down further once you know which exact API calls Terraform makes.

## ArgoCD Initial Setup

After Ansible deploys ArgoCD:

```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Port-forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open https://localhost:8080 (admin / <password above>)
```

## GHCR Image Pull Secret

```bash
# Create pull secret for k3s to pull from GHCR
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_PAT \
  --docker-email=YOUR_EMAIL \
  -n devsecops
```
