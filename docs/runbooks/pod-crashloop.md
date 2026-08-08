# Pod CrashLoopBackOff — Runbook

**Alert**: `PodCrashLooping`  
**Severity**: Critical  
**Condition**: Pod restarts > 5 times in 15 minutes  

---

## 1. Immediate Triage (< 3 minutes)

```bash
# Which pods are crash-looping?
kubectl get pods -n devsecops --field-selector=status.phase!=Running

# Get restart count + last state
kubectl describe pod <POD_NAME> -n devsecops | grep -A 10 "Last State"

# Read the crash logs (last terminated container)
kubectl logs <POD_NAME> -n devsecops --previous --tail=100
```

## 2. Common Causes + Fixes

| Exit Code | Meaning | Fix |
|-----------|---------|-----|
| `1` | App error / uncaught exception | Check app logs — see below |
| `137` | OOMKilled — out of memory | Increase `resources.limits.memory` in values.yaml |
| `139` | Segfault | Container runtime / base image issue |
| `143` | SIGTERM — graceful shutdown took too long | Increase `terminationGracePeriodSeconds` |

```bash
# Check if it was OOMKilled
kubectl describe pod <POD_NAME> -n devsecops | grep -i "OOMKilled\|Reason\|Exit Code"

# Check node memory pressure
kubectl describe node | grep -A 5 "Conditions"
kubectl top node
kubectl top pod -n devsecops
```

## 3. Remediation

### OOMKilled — increase memory limit
```bash
# Quick patch (then update values.yaml properly)
kubectl patch deployment devsecops-app -n devsecops \
  --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/resources/limits/memory","value":"512Mi"}]'
```

### App crash — rollback to last good image
```bash
kubectl rollout history deployment/devsecops-app -n devsecops
kubectl rollout undo deployment/devsecops-app -n devsecops
kubectl rollout status deployment/devsecops-app -n devsecops
```

### Image pull error — check GHCR secret
```bash
kubectl get events -n devsecops --sort-by=.lastTimestamp | grep -i "pull\|image"
kubectl get secret ghcr-secret -n devsecops  # should exist
```

### Config error — check environment variables
```bash
kubectl exec -n devsecops deploy/devsecops-app -- env | grep APP_
```

## 4. Verify Recovery

```bash
# Watch pod stabilise (0/1 → 1/1)
kubectl get pods -n devsecops -w

# Verify restart count drops to 0
kubectl get pod <POD_NAME> -n devsecops -o jsonpath='{.status.containerStatuses[0].restartCount}'
```

## 5. Post-Incident

- [ ] File postmortem if SLO was breached → `docs/postmortems/`
- [ ] Add memory limit check to Kyverno policies
- [ ] Add unit test covering the crash scenario

---
*Last updated: 2026-08-08*  
*Owner: platform-team*
