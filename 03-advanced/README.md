# Module 03: Advanced - Scheduling & Lifecycle Management

**Focus:** Control where Pods run and manage their complete lifecycle from creation to termination.

**Duration:** 2-3 days  
**Prerequisites:** Module 01-02 completed  
**KCNA Alignment:** Container Orchestration (46%), Cloud Native Architecture (16%)

## 📚 Learning Objectives

By completing this module, you will:

- Use labels and selectors for Pod organization and filtering
- Control Pod scheduling with node affinity and pod affinity
- Use taints and tolerations to restrict Pod placement
- Set resource requests and limits
- Implement health checks with liveness and readiness probes
- Manage Job and CronJob resources
- Understand Pod lifecycle hooks (init containers, lifecycle handlers)

## 📂 Exercise Breakdown

| Exercise        | Topics                                                                              | Time     |
| --------------- | ----------------------------------------------------------------------------------- | -------- |
| **scheduling/** | Labels, selectors, node affinity, pod affinity, taints/tolerations, resource limits | 1.5 days |
| **lifecycle/**  | Probes (liveness, readiness), init containers, lifecycle hooks                      | 0.5 day  |
| **cronjobs/**   | Jobs, CronJobs, parallelism, completion                                             | 1 day    |

## 🎯 Key Concepts

### Labels & Selectors

- Metadata for organizing Kubernetes resources
- Selectors enable querying and grouping resources
- Services use label selectors to find backend Pods
- Deployments use selectors to manage Pod replicas

### Scheduling Constraints

**Node Affinity:**

- Preferred or required constraints on which nodes Pods run
- Based on node labels
- More flexible than older nodeSelector

**Pod Affinity/Anti-Affinity:**

- Attract Pods toward/away from each other
- Based on labels of already-running Pods
- Useful for co-locating related services or spreading workloads

**Taints & Tolerations:**

- Taint: Mark nodes as unsuitable for certain Pods
- Toleration: Allow Pods to be scheduled on tainted nodes
- Prevents unwanted Pods from running on specific nodes

### Resource Management

**Requests:**

- Minimum guaranteed resources for a Pod
- Scheduler uses requests to find suitable nodes
- Pod gets evicted if node becomes constrained

**Limits:**

- Maximum resources a Container can use
- Pod killed if it exceeds limits
- Prevents runaway resource consumption

### Health Checks

**Liveness Probe:**

- Determines if Pod is alive
- Kubelet restarts Pod if probe fails
- Use to detect deadlocks or infinite loops

**Readiness Probe:**

- Determines if Pod is ready to receive traffic
- Service endpoints updated based on readiness
- Use to delay traffic until Pod is actually ready

### Jobs & CronJobs

**Job:**

- Runs containerized program to completion
- Useful for batch processing, backups, etc.
- Can run in parallel and managed completion count

**CronJob:**

- Schedules Jobs at specified times
- Similar to system cron jobs
- Supports schedule, concurrency, and retention policies

## 🚀 Getting Started

1. Start with scheduling exercises (labels, affinity, resource limits)
2. Apply lifecycle concepts to running Deployments
3. Practice Jobs and CronJobs for batch workloads
4. Combine all concepts in advanced scenarios

## 💡 Tips

- **Label strategically** - Use consistent naming for environment, team, version
- **Start simple with affinity** - Use soft affinity (preferred) before hard requirements
- **Resource requests matter** - Underestimating requests can cause pod evictions
- **Test probes carefully** - Wrong probe configuration can cause pod restart loops
- **Monitor Job completion** - Watch logs to debug failed Jobs

## 📖 Useful Commands (See cheatsheet.md for more)

```bash
# Labels and selectors
kubectl get pods -l app=nginx
kubectl label nodes node1 disktype=ssd
kubectl get nodes --show-labels

# Scheduling
kubectl describe node <node-name>  # See taints
kubectl taint nodes <node> key=value:NoSchedule
kubectl describe pod <pod-name>  # See affinity rules

# Resource limits
kubectl describe node <node-name>  # See allocatable resources
kubectl top nodes  # Current resource usage (requires metrics-server)
kubectl top pod <pod-name>

# Health checks
kubectl get events  # See probe failures and restarts
kubectl describe pod <pod-name>  # See probe configuration

# Jobs
kubectl get jobs
kubectl get pods -l job-name=<job-name>
kubectl logs pod/<pod-name>
```

## ✅ Module Completion Checklist

- [ ] Used labels to organize and filter resources
- [ ] Configured node affinity constraints
- [ ] Used taints and tolerations
- [ ] Set resource requests and limits
- [ ] Implemented liveness and readiness probes
- [ ] Created init containers
- [ ] Created and managed Jobs
- [ ] Created CronJobs with scheduling
- [ ] Understand when probes fail and why
- [ ] Ready to move to Module 04

---

**Prerequisites:** Complete Module 01-02 first  
**Next Step:** Start with `scheduling/exercise.md`
