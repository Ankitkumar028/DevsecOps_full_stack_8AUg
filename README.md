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
EC2 t3.micro — free tier  (single-node k3s cluster)
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
│   └── ansible/            # k3s + docker bootstrap playbooks
├── app/                    # Sample Python microservice (Flask)
├── charts/                 # Helm chart for the app
├── gitops/                 # ArgoCD Application manifests
├── policies/               # OPA / Kyverno admission policies
├── observability/          # Prometheus rules, Grafana dashboards-as-code
├── chaos/                  # Chaos Mesh experiment manifests
├── .github/workflows/      # ci.yml, security-scan.yml, terraform.yml
├── docs/
│   ├── runbooks/           # Incident runbooks
│   ├── postmortems/        # Postmortem templates + filled examples
│   └── assets/             # Architecture diagrams
└── README.md
```

---

## 🗺️ Build Phases

Each phase is a demonstrable milestone with its own README section and Git tag.

| Phase | Focus | Key Tools | Tag |
|-------|-------|-----------|-----|
| **1** | IaC + Basic CI/CD | Terraform, GitHub Actions, Docker Compose | `v0.1` |
| **2** | Container Orchestration | k3s, Helm, ArgoCD (GitOps) | `v0.2` |
| **3** | DevSecOps Pipeline | Trivy, Gitleaks, tfsec, Checkov, Semgrep, ZAP, Kyverno | `v0.3` |
| **4** | Observability & SRE | Prometheus, Grafana, Loki, Alertmanager, SLOs | `v0.4` |
| **5** | Chaos & Resilience | Chaos Mesh, incident runbooks, postmortems | `v0.5` |
| **6** | Platform Layer | Golden-path reusable workflows, cookiecutter template | `v0.6` |

---

## 💰 Cost-Safety Guardrails

> **Target: $0/month on AWS Free Tier**

- ✅ Set AWS Budget alerts at **$1** and **$5** on day one
- ✅ Single public subnet — **no NAT Gateway** (NAT GW = #1 free-tier trap)
- ✅ No EKS (use k3s), no RDS Multi-AZ, no unattached Elastic IPs
- ✅ `terraform destroy` when not working, `terraform apply` to resume
- ✅ All state (Helm values, ArgoCD apps, dashboards) lives in Git → rebuilding is free

---

## 🛠️ Tool Stack by Discipline

### DevOps
- **GitHub Actions** — unlimited minutes on public repos
- **Terraform** — IaC for AWS resources
- **Ansible** — EC2 bootstrapping (k3s, Docker)
- **Docker + Helm + ArgoCD** — containerization & GitOps

### DevSecOps
- **Trivy / Grype** — container image & IaC vulnerability scanning
- **Gitleaks** — secrets scanning (pre-commit + CI)
- **tfsec / Checkov** — Terraform security scanning
- **Semgrep** — SAST (static analysis)
- **OWASP ZAP** — DAST baseline scan
- **OPA / Kyverno** — policy-as-code admission control
- **Vault OSS** — secrets management

### Platform Engineering
- Reusable GitHub Actions workflows (golden path)
- Cookiecutter service template
- Self-service Helm charts
- Internal developer portal (Backstage — optional)

### SRE
- **Prometheus + Grafana** — metrics & SLO dashboards
- **Loki + Promtail** — log aggregation
- **Alertmanager** → Slack webhook
- **Chaos Mesh** — pod-kill / latency-injection experiments
- Runbooks + postmortem docs for each induced failure

---

## 🚀 Quick Start

### Prerequisites
- AWS account (free tier)
- Terraform ≥ 1.6
- Ansible ≥ 2.14
- kubectl + Helm ≥ 3.12
- GitHub account (for Actions + GHCR)

### 1. Bootstrap AWS backend
```bash
cd infra/terraform/bootstrap
terraform init && terraform apply
```

### 2. Provision EC2 + networking
```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your SSH key path
terraform init && terraform apply
```

### 3. Install k3s + Docker via Ansible
```bash
cd infra/ansible
ansible-playbook -i inventory.ini site.yml
```

### 4. Deploy app via ArgoCD
```bash
kubectl apply -f gitops/argocd-install.yaml
kubectl apply -f gitops/apps/
```

---

## 📖 What I Learned — Per Phase

> *(Fill in as you complete each phase)*

### Phase 1 — IaC + Basic CI/CD
- ...

### Phase 2 — Container Orchestration
- ...

### Phase 3 — DevSecOps Pipeline
- ...

### Phase 4 — Observability & SRE
- ...

### Phase 5 — Chaos & Resilience
- ...

### Phase 6 — Platform Layer
- ...

---

## 📄 License

MIT — see [LICENSE](LICENSE)
