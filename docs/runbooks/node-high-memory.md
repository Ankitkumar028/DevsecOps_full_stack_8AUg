# Node High Memory — Runbook

**Alert**: `NodeHighMemory`  
**Severity**: Critical  
**Condition**: Node memory > 85% for 5 minutes  
**Context**: Single free-tier t3.micro (1GB RAM) — this is a critical alert  

---

## 1. Immediate Triage

```bash
# Check current memory usage
kubectl top node
kubectl top pod -A --sort-by=memory | head -20

# Identify the memory hog
kubectl describe node | grep -A 10 "Allocated resources"
```

## 2. Quick Relief — Free Memory

```bash
# Scale down non-critical workloads temporarily
kubectl scale deployment/devsecops-app --replicas=0 -n devsecops

# Restart the highest-memory pod (this kills + restarts it)
kubectl rollout restart deployment/<HEAVY_DEPLOYMENT> -n <NAMESPACE>

# Clear k3s image cache (frees disk which reduces cache pressure)
sudo k3s crictl rmi --prune
```

## 3. Identify Cause

```bash
# Check for memory leaks (container grew over time)
# Look at Grafana: Node Memory Usage % over 24h

# Check OOMKill events in last hour
kubectl get events -A --field-selector=reason=OOMKilling --sort-by=.lastTimestamp

# Check Prometheus for top-N memory consumers
# Query: topk(5, container_memory_working_set_bytes{namespace!="kube-system"})
```

## 4. Permanent Fix

| Cause | Fix |
|-------|-----|
| App memory leak | Fix app + add memory limit in Helm values |
| Prometheus using too much | Reduce retention in `observability/prometheus/values.yaml` |
| Loki cache growing | Reduce `ingestion_rate_mb` in `observability/loki/values.yaml` |
| Too many workloads | Stagger deployments — don't run all stacks simultaneously |

## 5. Free-Tier Specific Advice

> The t3.micro has only **1GB RAM**. Total stack memory budgets:
>
> | Component | Target RSS |
> |-----------|-----------|
> | k3s system | ~150MB |
> | App | ~128MB |
> | Prometheus | ~256MB |
> | Grafana | ~128MB |
> | Loki | ~128MB |
> | Vault | ~64MB |
> | ArgoCD | ~200MB |
> | **Total** | **~1054MB** |
>
> Run stacks in phases — don't deploy everything at once. Add swap as emergency buffer:
> ```bash
> sudo dd if=/dev/zero of=/swapfile bs=128M count=8
> sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
> ```

---
*Last updated: 2026-08-08*  
*Owner: platform-team*
