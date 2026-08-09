# 🚀 DevSecOps Full-Stack Platform — Free Tier AWS

> A production-grade DevSecOps, Platform Engineering & SRE reference implementation running on a **single free-tier AWS EC2 instance** with k3s (lightweight Kubernetes).

![Architecture](docs/assets/architecture.png)

---

## 🏗️ Architecture Overview

```
GitHub Repo
    │
    ▼
GitHub Actions CI  ──►  Build / Test / SAST / Image Scan / IaC Scan
    │
    ▼
GHCR Registry  (container images)
    │
    ▼
ArgoCD  (GitOps sync)
    │
    ▼
EC2 t3.medium  (single-node k3s cluster)
    ├── App Pods          (sample microservice)
    ├── Observability     (Prometheus, Grafana, Loki)
    └── Security Layer    (Vault OSS, OPA / Kyverno)
    │
    ▼
Alertmanager  ──►  Slack webhook / email
```

### Why k3s instead of EKS?
EKS control plane ≈ **$73/month** — never free.  
k3s is a CNCF-certified lightweight Kubernetes distro that runs on a single EC2 instance and is **kubectl/Helm/CRD compatible** — it looks identical to any other K8s cluster on a résumé.

---

## 📦 Repo Layout

```
.
├── infra/
│   ├── terraform/          # VPC, EC2, S3 backend, security groups
│   └── ansible/            # OS Hardening, k3s, Docker, GitOps Bootstrap
├── app/                    # Sample Python microservice (Flask)
├── charts/                 # Helm chart for the app
├── gitops/                 # ArgoCD Application manifests
├── policies/               # OPA / Kyverno admission policies
├── observability/          # Prometheus rules, Grafana dashboards-as-code
├── chaos/                  # Chaos Mesh experiment manifests
├── .github/workflows/      # ci.yml, security-scan.yml, terraform.yml
├── docs/
│   ├── Implementation_Report.md # Detailed step-by-step project report
│   ├── runbooks/           # Incident runbooks
│   └── assets/             # Architecture diagrams
└── README.md
```

---

## 🛠️ Tool Stack by Discipline

### DevOps
- **GitHub Actions** — CI/CD automation and artifact building
- **Terraform** — Infrastructure as Code (IaC) for AWS resources
- **Ansible** — Configuration Management (Hardening, k3s, fully automated cluster bootstrapping)
- **Docker + Helm + ArgoCD** — Containerization & GitOps deployment

### DevSecOps (Shift-Left)
- **Trivy** — Container image vulnerability scanning
- **Gitleaks** — Hard-coded secrets scanning (CI pipeline blocker)
- **Checkov** — Terraform security and compliance scanning
- **Semgrep** — SAST (static analysis)
- **OWASP ZAP** — DAST baseline scan
- **Kyverno** — Kubernetes policy-as-code admission control
- **Vault OSS** — Secrets management

### SRE & Observability
- **Prometheus + Grafana** — Metrics & SLO dashboards
- **Loki + Promtail** — Log aggregation
- **Alertmanager** — Automated alerting

---

## 🚀 Quick Start (Fully Automated)

This repository is designed to be 100% hands-free after the initial deployment commands.

### Prerequisites
- AWS account (free tier)
- Terraform ≥ 1.6
- Ansible ≥ 2.14
- GitHub account (for Actions + GHCR)

### 1. Provision Infrastructure (Terraform)
```bash
# Setup remote state backend
cd infra/terraform/bootstrap
terraform init && terraform apply

# Provision Network & EC2
cd ../
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

### 2. Configure & Deploy Everything (Ansible)
Because of the custom `bootstrap_apps` Ansible role, the following single command will completely harden the OS, install Kubernetes, install ArgoCD, and deploy the entire application and observability stack via GitOps:

```bash
cd ../ansible
ansible-playbook -i inventory.ini site.yml
```

Within 5 minutes, your DevSecOps dashboard will be live at: `http://<EC2_IP>:30000`!

---

## 📖 Project Showcase Achievements

### Phase 1: Infrastructure Security
- Engineered a zero-cost AWS environment utilizing strict Security Groups and EBS optimization.
- Resolved and formally documented dozens of Checkov compliance alerts, successfully integrating the Checkov SARIF reports natively into the GitHub Security tab.

### Phase 2: Complete CI/CD Pipeline Automation
- Built a GitHub Actions pipeline that executes linting, PyTest, Trivy image scanning, and Helm chart value updates.
- **Proof of Security:** Intentionally tested the pipeline by injecting fake AWS credentials; Gitleaks successfully caught the vulnerability, blocked the Docker build, and prevented a production deployment.

### Phase 3: "Hands-Free" GitOps Disaster Recovery
- Wrote a custom Ansible `bootstrap_apps` role. If the EC2 server is destroyed, running the Ansible playbook automatically re-clones the repository, executes the deployment scripts, and provisions ArgoCD.
- ArgoCD instantly detects the Git repository and restores all applications, Kyverno policies, and Grafana dashboards without manual SSH intervention.

---

## 📄 License

MIT — see [LICENSE](LICENSE)
