# High Error Rate — Runbook

**Alert**: `HighErrorRate`  
**Severity**: Critical  
**SLO**: HTTP 5xx error rate > 1% for 5 minutes  

---

## 1. Triage (< 2 minutes)

```bash
# Check pod status
kubectl get pods -n devsecops

# Check recent logs
kubectl logs -n devsecops -l app.kubernetes.io/name=app --tail=100

# Check error rate live
kubectl port-forward svc/prometheus-operated 9090:9090 -n monitoring &
# Open http://localhost:9090 → query:
# sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))
```

## 2. Identify Root Cause

| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| Pod CrashLoopBackOff | App bug / OOM | Check `kubectl describe pod` + logs |
| Pod Running but errors | Bad deploy | `kubectl rollout undo deployment/devsecops-app -n devsecops` |
| All pods healthy | Upstream dep | Check external service reachability |
| Node memory high | Free-tier OOM | Restart lowest-priority pod; check node_memory |

## 3. Remediation

### Rollback last deployment
```bash
kubectl rollout undo deployment/devsecops-app -n devsecops
kubectl rollout status deployment/devsecops-app -n devsecops
```

### Force pod restart
```bash
kubectl rollout restart deployment/devsecops-app -n devsecops
```

### Scale down temporarily (single-node — be careful)
```bash
kubectl scale deployment/devsecops-app --replicas=0 -n devsecops
kubectl scale deployment/devsecops-app --replicas=1 -n devsecops
```

## 4. Verify Recovery

```bash
# Watch error rate drop in Prometheus
# Alert auto-resolves when rate < 1% for 5m
kubectl get prometheusrule -n monitoring
```

## 5. Post-Incident

- [ ] File postmortem within 24 hours → `docs/postmortems/`
- [ ] Add a test case covering the failure mode
- [ ] Update this runbook if steps were inaccurate

---
*Last updated: <!-- date -->*  
*Owner: platform-team*
