# Module 01: Beginner - Core Kubernetes Objects

**Focus:** Master the fundamental building blocks of Kubernetes - understanding how to create, inspect, update, and delete core resources.

**Duration:** 2-3 days  
**Prerequisites:** kubectl basics, cluster access  
**KCNA Alignment:** Kubernetes Fundamentals (25%)

## Learning Objectives

By completing this module, you will:

- Create and manage Pods (single-container and multi-container)
- Understand Pod lifecycle and troubleshooting
- Deploy and update Deployments with replicas
- Expose applications using Services (ClusterIP, NodePort, LoadBalancer)
- Understand ReplicaSets and how Deployments manage them
- Use labels and selectors to organize resources

## Exercise Breakdown

| Exercise         | Topics                                                       | Time  |
| ---------------- | ------------------------------------------------------------ | ----- |
| **pods/**        | Pod creation, multi-container pods, init containers, logging | 1 day |
| **deployments/** | Deployment creation, replicas, updates, rollbacks            | 1 day |
| **services/**    | Service types, port mapping, DNS discovery, load balancing   | 1 day |

## Key Concepts

### Pods

- Smallest deployable unit in Kubernetes
- Can contain multiple containers (though usually one)
- Ephemeral - not intended to be long-lived
- Share network namespace (localhost access between containers)

### Deployments

- Declarative way to manage Pods
- Manages ReplicaSets automatically
- Enables rolling updates and automatic rollbacks
- Ensures desired number of replicas always running

### Services

- Abstract way to expose Pods as a network service
- **ClusterIP**: Internal-only service (default)
- **NodePort**: Expose on each Node's IP at a static port
- **LoadBalancer**: Cloud load balancer (if cluster supports it)

### Labels & Selectors

- Key-value metadata for organizing resources
- Services use selectors to route traffic to Pods
- Enable filtering and grouping resources by concern

## Getting Started

1. Navigate to each exercise subdirectory
2. Read the exercise.md file
3. Create your YAML manifests in that directory
4. Deploy and verify using kubectl commands
5. Move to next exercise once verified

## Tips

- **Use templates** - Check `/templates` for Pod, Deployment, Service skeletons
- **Name your files well** - e.g., `nginx-pod.yaml`, `my-deployment.yaml`
- **Test incrementally** - Deploy one resource at a time, verify, then build on it
- **Use `-v 8` flag** - `kubectl apply -f <file> -v 8` shows detailed execution details
- **Keep it clean** - Delete resources after verification: `kubectl delete -f <file>`

## Useful Commands (See cheatsheet.md for more)

```bash
# Create resources
kubectl apply -f pod.yaml

# View resources
kubectl get pods
kubectl get deployments
kubectl get services

# Inspect resources
kubectl describe pod <pod-name>
kubectl describe service <service-name>

# View logs
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>

# Port forward for service testing
kubectl port-forward svc/<service-name> 8080:80

# Delete resources
kubectl delete -f pod.yaml
kubectl delete pod <pod-name>
```

## Module Completion Checklist

- [ ] Completed all exercises in pods/
- [ ] Completed all exercises in deployments/
- [ ] Completed all exercises in services/
- [ ] Can create Pods and Deployments from scratch
- [ ] Understand how Services route traffic to Pods
- [ ] Can troubleshoot Pods that fail to start
- [ ] Ready to move to Module 02

---

**Next Step:** Start with `pods/exercise.md`
