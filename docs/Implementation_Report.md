# 🚀 Full-Stack DevSecOps & Platform Engineering Project Report

**Author:** DevSecOps Engineer
**Environment:** AWS Free Tier (Single EC2 Node)
**Architecture:** K3s, ArgoCD, Prometheus, Grafana, Kyverno, GitHub Actions

## 1. Executive Summary
This document serves as a comprehensive report detailing the end-to-end implementation of a modern, cloud-native DevSecOps platform. The goal of this project was to design, provision, secure, and automate a complete Kubernetes-based application lifecycle while maintaining strict zero-cost (free tier) AWS constraints. 

By leveraging "Shift-Left" security methodologies, Infrastructure as Code (IaC), Configuration Management, and GitOps, we successfully built a pipeline that prevents vulnerabilities from reaching production and deploys infrastructure entirely hands-free.

---

## 2. Technology Stack Used
- **Infrastructure as Code (IaC):** Terraform
- **Configuration Management:** Ansible
- **Container Orchestration:** K3s (Lightweight Kubernetes)
- **Continuous Integration (CI):** GitHub Actions
- **Continuous Deployment (CD/GitOps):** ArgoCD, Helm
- **Security & Vulnerability Scanning:** 
  - Gitleaks (Secrets Detection)
  - Checkov (IaC Security)
  - Trivy (Container Vulnerability Scanning)
  - OWASP ZAP (Dynamic Application Security Testing - DAST)
  - pip-audit (Python Dependency Scanning)
  - Kyverno (Kubernetes Admission Control Policies)
- **Observability:** Prometheus, Grafana, Loki

---

## 3. Implementation Steps & Milestones

### Phase 1: Infrastructure as Code (Terraform)
1. **S3 Backend Bootstrap:** Configured a secure AWS S3 bucket for remote state storage and a DynamoDB table for state locking to prevent concurrent modification collisions.
2. **Networking & Security Groups:** Built a custom VPC, Public Subnet, and Internet Gateway. Configured strict Security Groups allowing access only to essential ports (SSH, K3s API, HTTP/HTTPS, and NodePorts).
3. **Compute Provisioning:** Deployed a `t3.micro` EC2 instance, utilizing EBS-optimization and detailed monitoring while adhering strictly to AWS free-tier limits.
4. **Security Hardening (Checkov):** Iteratively resolved and documented Checkov security compliance alerts (e.g., explicitly ignoring enterprise-grade rules like VPC Flow Logs and KMS encryption to avoid AWS costs, while fixing actionable security flaws).

### Phase 2: CI/CD Pipeline Automation (GitHub Actions)
1. **Linting & Unit Testing:** Integrated `ruff` and `pytest` to enforce Python code quality.
2. **Secrets Scanning:** Integrated `Gitleaks` to block any commits containing hard-coded AWS keys or passwords.
3. **Container Build & Push:** Configured Docker Buildx to containerize the Flask application and push the immutable artifact to GitHub Container Registry (GHCR).
4. **Container Security:** Added `Trivy` to scan the Docker image for CRITICAL and HIGH vulnerabilities before deployment.
5. **SARIF Integration:** Configured explicit `security-events: write` permissions so all security tools (Checkov, Trivy, Gitleaks) upload their results natively into the GitHub Security Dashboard.

### Phase 3: Configuration Management (Ansible)
1. **Server Hardening:** Wrote idempotent Ansible playbooks to harden the EC2 instance OS. This included configuring `fail2ban`, `auditd` (resolved systemd lock issues using raw commands), and tightening SSH access.
2. **Kubernetes Installation:** Automated the installation of K3s and Docker via Ansible roles.
3. **GitOps Bootstrapping:** Developed a custom `bootstrap_apps` Ansible role that executes upon server creation. This role:
   - Clones the Git repository directly onto the EC2 instance.
   - Executes the `deploy-stack.sh` script to install Kyverno, Prometheus, and Grafana.
   - Applies the initial ArgoCD manifests (`argocd-project.yaml`, `devsecops-app.yaml`) to the cluster.

### Phase 4: GitOps Deployment & Observability
1. **ArgoCD Sync:** Configured ArgoCD to continuously poll the `main` branch. Any updates to the Helm charts by the CI pipeline are instantly detected and deployed to Kubernetes.
2. **Kyverno Policies:** Enforced strict Kubernetes runtime security policies, such as `disallow-root-user` and `require-resource-limits`, preventing vulnerable pods from being scheduled.
3. **Dashboards:** Brought online a custom DevSecOps Flask web application serving as the architecture dashboard, alongside Grafana dashboards monitoring cluster SLOs, CPU/Memory usage, and application HTTP request metrics.

---

## 4. Security Incident Testing (Shift-Left Validation)
To validate the effectiveness of the DevSecOps pipeline, we executed a real-world security test:
1. **The Flaw:** Injected a hard-coded AWS Secret Key (`AKIAIOSFODNN7EXAMPLE`) directly into the Python application code (`app/main.py`).
2. **The Result:** The developer pushed the code to the `main` branch. The GitHub Actions CI pipeline intercepted the commit. The **Gitleaks** scanner successfully detected the `aws-access-key` signature, failed the CI job, and immediately crashed the pipeline. 
3. **The Prevention:** Because the pipeline failed, the Docker image was never built, and ArgoCD never deployed the vulnerable code. The vulnerability was caught and remediated in the CI phase, proving the "Shift-Left" architecture works flawlessly.

---
*Report generated automatically for project portfolio showcasing.*
