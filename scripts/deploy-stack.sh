#!/usr/bin/env bash
# scripts/deploy-stack.sh
# One-shot script to deploy the full observability + security stack
# Run on the EC2 instance after k3s is running
# Usage: bash scripts/deploy-stack.sh [--skip-monitoring] [--skip-security]

set -euo pipefail

export KUBECONFIG=/home/ec2-user/.kube/config

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[$(date +%H:%M:%S)] ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +%H:%M:%S)] ⚠️  $1${NC}"; }
fail() { echo -e "${RED}[$(date +%H:%M:%S)] ❌ $1${NC}"; exit 1; }

SKIP_MONITORING=false
SKIP_SECURITY=false
for arg in "$@"; do
  [[ "$arg" == "--skip-monitoring" ]] && SKIP_MONITORING=true
  [[ "$arg" == "--skip-security"   ]] && SKIP_SECURITY=true
done

echo "======================================================"
echo " DevSecOps Full-Stack Platform — Stack Deployer"
echo "======================================================"
echo ""

# Pre-flight check
kubectl get nodes || fail "k3s not running — run Ansible playbook first"
log "k3s is running"

# ── Namespaces ──────────────────────────────────────────────────────────────
for ns in devsecops monitoring vault kyverno-system; do
  kubectl create namespace "$ns" 2>/dev/null || warn "Namespace $ns already exists"
done
log "Namespaces ready"

# ── Helm Repositories ────────────────────────────────────────────────────────
log "Adding Helm repositories..."
helm repo add kyverno https://kyverno.github.io/kyverno/ 2>/dev/null || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update

# ── Kyverno (security policies) ─────────────────────────────────────────────
if [[ "$SKIP_SECURITY" == "false" ]]; then
  log "Installing Kyverno..."
  helm upgrade --install kyverno kyverno/kyverno \
    -n kyverno-system \
    --set resources.requests.memory=64Mi \
    --set resources.limits.memory=256Mi \
    --wait --timeout 5m

  log "Applying Kyverno policies..."
  kubectl apply -f policies/kyverno/
  log "Security policies active"
fi

# ── Monitoring Stack ─────────────────────────────────────────────────────────
if [[ "$SKIP_MONITORING" == "false" ]]; then
  log "Installing kube-prometheus-stack..."
  helm upgrade --install kube-prom prometheus-community/kube-prometheus-stack \
    -n monitoring \
    -f observability/prometheus/values.yaml \
    --wait --timeout 10m

  log "Installing Loki + Promtail..."
  helm upgrade --install loki grafana/loki-stack \
    -n monitoring \
    -f observability/loki/values.yaml \
    --set promtail.enabled=true \
    --wait --timeout 5m

  # Create Grafana dashboard ConfigMap from JSON
  kubectl create configmap grafana-dashboards \
    --from-file=slo-dashboard.json=observability/grafana/dashboards/slo-dashboard.json \
    -n monitoring --dry-run=client -o yaml | kubectl apply -f -

  log "Monitoring stack deployed"
  echo ""
  warn "Grafana:     http://$(kubectl get node -o jsonpath='{.items[0].status.addresses[0].address}'):30300  (admin / check GRAFANA_ADMIN_PASSWORD secret)"
  warn "Prometheus:  http://$(kubectl get node -o jsonpath='{.items[0].status.addresses[0].address}'):30090"
  warn "Alertmanager: http://$(kubectl get node -o jsonpath='{.items[0].status.addresses[0].address}'):30093"
fi

# ── Apply Prometheus alert rules ─────────────────────────────────────────────
kubectl apply -f observability/prometheus/alerts.yaml
log "Alert rules applied"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "======================================================"
log "Stack deployment complete!"
echo ""
echo "  Next steps:"
echo "  1. kubectl apply -f gitops/argocd-project.yaml"
echo "  2. kubectl apply -f gitops/apps/devsecops-app.yaml"
echo "  3. kubectl apply -f gitops/applicationset.yaml"
echo "======================================================"
