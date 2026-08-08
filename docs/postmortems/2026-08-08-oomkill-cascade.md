# Postmortem — Pod OOMKill Cascading Failure (2026-08-08)

> **Severity**: P2  
> **Date**: 2026-08-08  
> **Duration**: 14:15 – 14:43 UTC (28 minutes)  
> **Author**: @Ankitkumar028  
> **Status**: Closed  

---

## Summary

The `devsecops-app` pod was OOMKilled (exit 137) due to a Prometheus scraping spike
that caused the app's in-process metrics buffer to grow unbounded. The pod restarted
3 times before the `PodCrashLooping` alert fired. ArgoCD self-healed the deployment
within 2 minutes of the alert, but 28 minutes of elevated error rate consumed ~6% of
the monthly SLO error budget.

---

## Timeline

| Time (UTC) | Event |
|------------|-------|
| 14:15 | Chaos Mesh pod-kill experiment ran (scheduled) |
| 14:17 | Pod restarted — memory leak detected post-restart |
| 14:22 | Pod OOMKilled (RSS 290MB vs 256MB limit) |
| 14:23 | `PodCrashLooping` alert fired — Slack notified |
| 14:25 | On-call opened runbook, identified OOMKill via `kubectl describe` |
| 14:28 | Root cause confirmed: unbounded Prometheus metrics registry |
| 14:32 | Memory limit patched to 384Mi via kubectl patch |
| 14:35 | Deployment rolled out cleanly — pod healthy |
| 14:43 | Error rate SLO returned to > 99% — alert resolved |

---

## Root Cause

The Flask `prometheus_client` default registry retains **all time-series indefinitely**.
Under high-cardinality scraping (100+ unique `/api/v1/items/<id>` paths from load test),
the in-process registry grew to 290MB — exceeding the 256Mi container memory limit.

---

## Impact

| Metric | Value |
|--------|-------|
| Duration | 28 minutes |
| Error rate peak | 38% (during OOMKill restart) |
| Requests affected | ~840 requests returned 502 |
| SLO error budget consumed | ~6% of monthly budget |

---

## What Went Well

- `PodCrashLooping` alert fired within 6 minutes of first OOMKill
- Runbook steps correctly identified the issue in < 3 minutes
- ArgoCD self-heal prevented further manual intervention
- Chaos Mesh experiment revealed a latent bug — not a production incident caused by users

---

## What Went Wrong

- Memory limit was too low for the metrics registry under load
- No cardinality limit was set on Prometheus labels (high-cardinality endpoint labels)
- Load test was not preceded by a memory profiling step

---

## Action Items

| Action | Owner | Due | Status |
|--------|-------|-----|--------|
| Set label cardinality limit in Prometheus config | @platform | 2026-08-15 | ✅ Done |
| Increase app memory limit to 384Mi in Helm values | @platform | 2026-08-08 | ✅ Done |
| Add `HighCardinalityMetrics` alert rule | @platform | 2026-08-22 | Open |
| Pre-load test memory profiling step in CI | @dev | 2026-08-29 | Open |
| Add OOMKill to chaos experiment suite | @sre | 2026-08-29 | Open |

---

## Lessons Learned

1. **Always profile memory under realistic load before setting container limits**
2. **High-cardinality Prometheus labels (e.g. user IDs, request IDs in labels) cause memory growth** — use histograms, not counters, for high-cardinality dimensions
3. Chaos experiments are valuable precisely because they find issues before users do

---

*This postmortem is blameless. The goal is systemic improvement, not individual fault.*
