# Module 05: Expert II - Operations & Observability

**Focus:** Master deployment strategies, scaling, monitoring, and troubleshooting in production scenarios.

**Duration:** 2-3 days  
**Prerequisites:** Module 01-04 completed  
**KCNA Alignment:** Container Orchestration (46%), Cloud Native Observability (8%), Cloud Native Application Delivery (5%)

## 📚 Learning Objectives

By completing this module, you will:

- Implement deployment strategies (rolling update, recreate, blue-green, canary)
- Rollback failed deployments
- Scale applications manually and automatically with HPA/VPA
- Setup metrics collection and monitoring
- Implement logging strategies
- Troubleshoot deployment, scaling, and application issues
- Understand cloud-native observability patterns

## 📂 Exercise Breakdown

| Exercise             | Topics                                                                     | Time    |
| -------------------- | -------------------------------------------------------------------------- | ------- |
| **rollouts/**        | Deployment strategies, rolling updates, rollbacks, revision history        | 1 day   |
| **scaling/**         | Manual scaling, HorizontalPodAutoscaler (HPA), VerticalPodAutoscaler (VPA) | 1 day   |
| **metrics/**         | metrics-server, custom metrics, monitoring setup                           | 0.5 day |
| **troubleshooting/** | Common issues, debugging techniques, log analysis                          | 1 day   |

## 🎯 Key Concepts

### Deployment Strategies

**Rolling Update (default):**

- Gradually replace old Pods with new ones
- Maintains service availability
- Configured with maxUnavailable and maxSurge

**Recreate:**

- Delete all old Pods, then create new ones
- Causes downtime
- Useful for resources that can't run multiple versions

**Blue-Green (manual):**

- Run two identical environments (blue=old, green=new)
- Quick switch with service selector change
- Easy rollback, but requires 2x resources

**Canary (advanced):**

- Gradually increase traffic to new version
- Typically paired with Service Mesh
- Enables testing with real traffic

### Scaling

**Horizontal Pod Autoscaling (HPA):**

- Automatically adjust replica count based on metrics
- Based on CPU, memory, or custom metrics
- Requires metrics-server for metrics collection

**Vertical Pod Autoscaling (VPA):**

- Automatically adjust resource requests/limits
- Useful for capacity planning
- Less common than HPA

**Manual Scaling:**

- `kubectl scale deployment <name> --replicas=5`
- Quick scaling, but not automated

### Observability

**Metrics:**

- Time-series data about resource usage (CPU, memory)
- Collected by metrics-server
- Used by HPA and for dashboards

**Logging:**

- Container stdout/stderr captured by kubelet
- Accessible via `kubectl logs`
- Best practice: log to stdout, not files

**Events:**

- Record of what happened in cluster
- Accessible via `kubectl get events`
- Useful for troubleshooting pod issues

### Troubleshooting Common Issues

**Pod won't start:**

- Check: ImagePullBackOff, CrashLoopBackOff, Pending
- Use: logs, describe, events

**Pod crashes repeatedly:**

- Check: Liveness probe configuration
- Verify: Application startup time vs probe delay

**High resource usage:**

- Check: Resource requests/limits
- Use: `kubectl top pods` to see actual usage
- Consider: HPA or VPA

**Network connectivity issues:**

- Check: Service selector labels
- Check: NetworkPolicy rules
- Test: curl from pod to service

## 🚀 Getting Started

1. Start with rollouts (deployment strategies and updates)
2. Progress to scaling exercises
3. Setup metrics collection and monitoring
4. Work through troubleshooting scenarios
5. Combine all concepts in complex scenarios

## 💡 Tips

- **Test strategy first** - Understand rolling updates before attempting blue-green
- **Metrics require setup** - Install metrics-server first for HPA to work
- **HPA minimums matter** - Set minReplicas high enough to handle baseline load
- **Logs are your friend** - Always check logs first when debugging
- **Use kubectl describe** - Often shows recent events that explain issues

## 📖 Useful Commands (See cheatsheet.md for more)

```bash
# Deployment info
kubectl get deployment <name> -o yaml
kubectl get replicaset  # See history of deployments
kubectl describe deployment <name>

# Rolling updates
kubectl set image deployment/<name> <container>=<image>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout status deployment/<name>

# Scaling
kubectl scale deployment <name> --replicas=5
kubectl get hpa
kubectl describe hpa <name>

# Metrics
kubectl top nodes
kubectl top pods
kubectl get metrics # May not work without proper setup

# Troubleshooting
kubectl get events --sort-by='.lastTimestamp'
kubectl logs <pod>
kubectl logs <pod> --previous  # Logs from crashed container
kubectl exec -it <pod> -- /bin/sh
kubectl port-forward svc/<service> 8080:80
```

## ✅ Module Completion Checklist

- [ ] Implemented rolling update deployment strategy
- [ ] Successfully rolled back a failed deployment
- [ ] Manually scaled a Deployment
- [ ] Created and configured HorizontalPodAutoscaler
- [ ] Verified metrics collection with metrics-server
- [ ] Understood pod lifecycle during scaling events
- [ ] Examined application logs for debugging
- [ ] Troubleshot CrashLoopBackOff scenarios
- [ ] Troubleshot resource constraint issues
- [ ] Troubleshot network connectivity issues
- [ ] Can identify root cause of common production issues
- [ ] Ready for KCNA exam!

---

**Prerequisites:** Complete Module 01-04 first  
**Next Step:** Start with `rollouts/exercise.md`
