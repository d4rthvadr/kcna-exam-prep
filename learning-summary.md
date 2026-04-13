# KCNA Learning Summary & Review Guide

## Overview

This document summarizes the key concepts from all 5 modules in this KCNA prep repository. Use this as a quick reference guide and final review before the exam.

---

## Module 01: Kubernetes Fundamentals

### Pods

- **Definition**: Smallest deployable unit; typically 1 container (can have multiple)
- **Lifecycle**: Pending → Running → Succeeded/Failed
- **Status Conditions**: PodScheduled, Initialized, ContainersReady, Ready
- **restartPolicy**: Always (default), OnFailure, Never
- **Key Command**: `kubectl run <pod> --image=<image>`, `kubectl describe pod <pod>`

### Deployments

- **Purpose**: Manage ReplicaSets automatically; enables rolling updates
- **Key Features**: Desired replicas, rolling update strategy, automatic restart
- **Strategy Types**: RollingUpdate (default), Recreate (downtime)
- **Rolling Update Controls**: maxSurge (extra pods), maxUnavailable (pods down)
- **ReplicaSet**: Internal object created by Deployment to manage pod replicas
- **Key Commands**: `kubectl set image deployment/<dep> <container>=<image>:<tag>`, `kubectl scale deployment/<dep> --replicas=<N>`

### Services

- **ClusterIP** (default): Internal service, accessible from within cluster only
- **NodePort**: Exposes on node port (30000-32767); accessible externally
- **LoadBalancer**: Allocates external load balancer (cloud providers)
- **Service Discovery DNS**: `<service>.<namespace>.svc.cluster.local`
  - Same namespace: `<service>`
  - Different namespace: `<service>.<namespace>` or full FQDN
- **Endpoints**: Maps service name to pod IPs; created automatically
- **Selector**: Labels used to match pods; Kubernetes updates endpoints automatically
- **Key Commands**: `kubectl expose pod/deployment <name> --port=80`, `kubectl get endpoints <service>`

### Namespaces

- **Isolation**: Logical partition of cluster resources
- **Default Namespace**: `default` (created automatically)
- **System Namespace**: `kube-system` (internal Kubernetes components)
- **Resource Quotas**: Can limit resources per namespace
- **RBAC Scoping**: Roles/RoleBindings are namespace-scoped
- **Key Commands**: `kubectl create namespace <name>`, `kubectl get ns`, `kubectl config set-context --current --namespace=<ns>`

### Labels & Selectors

- **Labels**: Key-value pairs attached to Kubernetes objects
- **Use Cases**: Grouping (label pods by environment: `env: prod`), selecting pods for services
- **Selectors**: Filter objects by labels
  - **Equality**: `app=web` (key equals value)
  - **Set-based**: `env in (prod, staging)`, `env notin (dev)`
- **Key Commands**: `kubectl get pods -l app=web`, `kubectl label pod <name> <key>=<value>`

---

## Module 02: Configuration & Storage

### ConfigMaps

- **Purpose**: Store non-sensitive configuration data
- **Data Types**: key-value pairs (literal) or files
- **Containers See**: Via environment variables or mounted volumes
- **Immutability**: Can set immutable: true to prevent accidental changes
- **Size Limit**: 1MB per ConfigMap
- **Key Commands**: `kubectl create configmap <name> --from-literal=<key>=<value>`, `kubectl get configmap <name> -o yaml`

### Secrets

- **Purpose**: Store sensitive data (passwords, API keys, tokens)
- **Encoding**: Base64-encoded (NOT encrypted by default; use encryption at rest)
- **Types**: `Opaque` (generic), `kubernetes.io/basic-auth`, `kubernetes.io/ssh-auth`, `kubernetes.io/dockercfg`, etc.
- **Immutability**: Can set immutable: true
- **Size Limit**: 1MB per Secret
- **Security Note**: Base64 is encoding (not encryption); don't commit secrets to git!
- **Key Commands**: `kubectl create secret generic <name> --from-literal=<key>=<value>`, `kubectl get secret <name> -o yaml`

### PersistentVolumes (PV)

- **Definition**: Cluster-level storage resource (created by admin)
- **Lifecycle**: Available → Bound (to PVC) → Released → Reclaimed or Retained
- **Reclaim Policies**:
  - **Retain**: Keep data after PVC deleted; manual cleanup required
  - **Delete**: Automatically delete underlying storage when PVC deleted
  - **Recycle**: Scrub data and return to Available (deprecated)
- **Access Modes**: ReadWriteOnce (one pod on one node), ReadOnlyMany, ReadWriteMany
- **Is Persistent**: YES, survives pod/node restart/deletion

### PersistentVolumeClaims (PVC)

- **Definition**: Pod's request for storage (like pod is request for compute)
- **Binding**: Kubernetes automatically binds PVC to PV with matching size/mode
- **StorageClass**: Can reference StorageClass for automatic PV creation
- **Pod Mount**: Pods mount PVC by name (not PV directly)
- **Lifecycle**: Pods can use PVC even if original pod deleted; storage persists
- **Key Commands**: `kubectl get pvc`, `kubectl describe pvc <name>`

### StorageClass

- **Purpose**: Define storage types; allows dynamic PV provisioning
- **Parameters**: Provisioner, parameters (e.g., SSD or HDD), reclaimPolicy
- **Automatic Provisioning**: Create PVC without PV existing; StorageClass auto-creates
- **Cloud Integration**: Each cloud provider has StorageClass for their storage (e.g., AWS EBS, Azure Disk)

### StatefulSet

- **Purpose**: Manage stateful apps requiring stable pod identity and storage
- **Differs from Deployment**: Pods have stable hostname (e.g., `mysql-0`, `mysql-1`), ordered startup, stable storage
- **Use Cases**: Databases, message queues, clustered apps
- **Headless Service**: Required (clusterIP: None) for DNS names of individual pods
- **Storage**: Each pod typically has own PVC; not shared

---

## Module 03: Advanced Scheduling & Lifecycle

### Labels & Node Affinity

- **Node Selector** (basic): `nodeSelector: { disktype: ssd }` - only pods with matching labels
- **Node Affinity** (advanced):
  - **requiredDuringSchedulingIgnoredDuringExecution**: Must match (hard constraint)
  - **preferredDuringSchedulingIgnoredDuringExecution**: Prefer match (soft constraint)
  - **Operators**: In, NotIn, Gt, Lt, Exists, DoesNotExist

### Pod Affinity & Anti-Affinity

- **Pod Affinity**: Schedule pod near other pods (same topology key, e.g., same node/zone)
- **Pod Anti-Affinity**: Schedule pod away from other pods
- **Topology Key**: e.g., `kubernetes.io/hostname` (different nodes), `topology.kubernetes.io/zone` (different zones)

### Taints & Tolerations

- **Taint**: Applied to nodes; repels pods unless they tolerate
- **Toleration**: Pod's tolerance to a taint; allows scheduling despite taint
- **Taint Effects**: NoSchedule (don't schedule), NoExecute (evict if already scheduled), PreferNoSchedule (prefer not to)
- **Use Case**: Dedicate nodes to specific workloads (e.g., GPU nodes)

### Resource Requests & Limits

- **Requests**: Guaranteed minimum resources; used for scheduling decisions
- **Limits**: Maximum resources pod can use; enforced by kubelet (OOMKilled if exceeded)
- **CPU Units**: m (millicores); 1000m = 1 CPU
- **Memory Units**: Ki (kibibyte), Mi (mebibyte), Gi (gibibyte)
- **QoS Classes**:
  - **Guaranteed**: requests == limits; never evicted (highest priority)
  - **Burstable**: requests < limits; evicted second
  - **BestEffort**: no requests/limits; evicted first

### Probes

- **Readiness Probe**: Determines if pod should receive traffic; failed = no traffic
- **Liveness Probe**: Determines if pod should restart; failed = pod restart
- **Startup Probe**: Pod is starting; gives more time before liveness kicks in
- **Probe Types**:
  - **httpGet**: HTTP request to endpoint; success if 200-399
  - **exec**: Run command; success if exit code 0
  - **tcpSocket**: Connect to port; success if port opens
- **Timing**: initialDelaySeconds (wait before first probe), periodSeconds (interval), failureThreshold (consecutive failures)

### Init Containers

- **Purpose**: Run setup tasks before main containers start (e.g., wait for database, download config)
- **Behavior**: Run in order, must complete successfully (exit 0); main containers don't start until all inits complete
- **Logging**: Separate logs from main containers (`kubectl logs <pod> -c <init-name>`)

### Jobs & CronJobs

- **Job**: One-off task; pod runs to completion (may retry on failure)
- **backoffLimit**: Number of retries before job fails
- **activeDeadlineSeconds**: Max time job can run
- **CronJob**: Job on schedule (cron format)
- **concurrencyPolicy**: Allow (multiple runs), Forbid (skip if running), Replace (cancel old run)

---

## Module 04: Security & Access Control

### RBAC (Role-Based Access Control)

- **Components**:
  - **ServiceAccount**: Identity for apps/pods (similar to user)
  - **Role**: Set of permissions in a namespace (e.g., "can get and list pods")
  - **RoleBinding**: Connects ServiceAccount to Role (in a namespace)
  - **ClusterRole**: Cluster-wide permissions (both cluster resources and namespaced)
  - **ClusterRoleBinding**: Connects Subject to ClusterRole (cluster-wide)

- **Verbs**: get, list, watch (read), create, update, patch (write), delete, deletecollection (admin)
- **apiGroups**: "" (core/v1), "apps", "batch", "rbac.authorization.k8s.io", etc.
- **Resources**: "pods", "deployments", "services", "roles", etc.
- **Testing**: `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<namespace>:<name>`

### NetworkPolicies

- **Purpose**: Control pod-to-pod and pod-to-external traffic
- **Default**: No NetworkPolicy = allow all traffic
- **Ingress Rules**: Control inbound traffic to pods (who can send TO pods)
- **Egress Rules**: Control outbound traffic from pods (pods can send TO whom)
- **Selectors**:
  - **podSelector**: Target pods (in same namespace) by labels
  - **namespaceSelector**: Allow from/to pods in other namespaces
  - **ipBlock**: Allow from/to external CIDR ranges (e.g., external SaaS APIs)

- **Default Deny Pattern**: Create empty NetworkPolicy to implicitly deny all

### SecurityContext

- **Purpose**: Set security-related pod/container options
- **Container Level**: Run as user/group, read-only filesystem, capabilities
- **Pod Level**: Service account, filesystem group, SELinux context

---

## Module 05: Operations & Observability

### Metrics & Monitoring

- **metrics-server**: Kubelet agent that collects CPU/memory metrics
- **kubectl top nodes**: Show node resource utilization
- **kubectl top pods**: Show pod resource utilization
- **Resource Usage**: Actual current usage (not requested/limited)

### Logging

- **Pod Logs**: `kubectl logs <pod> [-c <container>] [--previous] [-f]`
- **Container Logs**: Stored at `/var/log/pods/*` on nodes
- **Stdout/Stderr**: Kubernetes captures all output to stdout/stderr
- **Previous Logs**: `--previous` shows logs from crashed/restarted container

### Deployment Strategies

- **Rolling Update** (default): Gradually replace pods; minDowntime
  - Controls: maxSurge (extra pods), maxUnavailable (down during update)
  - Uses readiness probes to determine when pod is ready
- **Blue-Green**: Two complete environments; instant switch via service selector
  - Double resource usage; instant rollback
- **Canary**: Deploy to small percentage first; validate then expand
  - Gradual exposure; longer rollout time

### Rollout & Rollback

- **kubectl rollout history deployment/<name>**: Show revisions
- **kubectl rollout undo deployment/<name>**: Revert to previous revision
- **kubectl rollout undo deployment/<name> --to-revision=<N>**: Revert to specific revision
- **kubectl rollout pause/resume**: Pause and resume rolling update with manual validation

### Health & Readiness

- **Readiness Probe**: Controls traffic routing; failed = no traffic to pod
- **Liveness Probe**: Controls pod restart; failed = pod restart
- **Both Critical**: For deployments to work properly

### QoS Classes (Eviction Priority)

1. **BestEffort** (no requests/limits): Evicted first
2. **Burstable** (requests < limits): Evicted second
3. **Guaranteed** (requests == limits): Never evicted (last)

### Node Pressure Conditions

- **MemoryPressure**: Node low on memory; kubelet evicts pods
- **DiskPressure**: Node low on disk space
- **PIDPressure**: Node low on process IDs
- **Ready**: Node healthy and accepting pods
- **Eviction**: Based on QoS class; BestEffort first

### Troubleshooting

- **Pod Status**: Check pod phase (Pending, Running, Succeeded, Failed)
- **Events**: `kubectl describe pod <name>` or `kubectl get events`
- **Container Logs**: `kubectl logs <pod>` (current) or `--previous` (crashed)
- **Endpoint Check**: `kubectl get endpoints <service>` (service routing)
- **DNS Test**: `kubectl exec <pod> -- nslookup <service>` (name resolution)
- **Connectivity**: `kubectl exec <pod> -- nc -zv <ip> <port>` (port reachability)

---

## Cross-Module Concepts

### API Resources

- **Group/Version**: Each resource has API group and version (e.g., `v1`, `apps/v1`, `batch/v1`)
- **Namespaced**: Most resources are namespaced (specific to namespace)
- **Cluster-Scoped**: Some resources are cluster-wide (Node, PersistentVolume, ClusterRole, Namespace, etc.)

### Declarative vs. Imperative

- **Declarative** (preferred): `kubectl apply -f file.yaml` (Kubernetes determines how to achieve state)
- **Imperative** (quick but less repeatable): `kubectl run`, `kubectl create`, `kubectl set` commands

### YAML Structure

```yaml
apiVersion: v1 # API group + version
kind: Pod # Resource type
metadata:
  name: my-pod # Name (must be unique in namespace)
  namespace: default # Namespace (default if omitted)
  labels:
    app: web # Labels for selection
spec: # Specification of desired state
  containers:
    - name: app
      image: nginx:latest
      ports:
        - containerPort: 80
```

### Configuration Management

- **ConfigMaps**: Non-sensitive data (config files, env vars)
- **Secrets**: Sensitive data (passwords, API keys)
- **Both**: Can be environment variables or volumes
- **Mounted Volumes**: Changes reflected eventually (10-60 sec syncing)

### Storage Decisions

- **emptyDir**: Per-pod, temporary (deleted on pod termination)
- **hosPath**: Per-node, local disk (pods can't survive node failure)
- **PersistentVolume**: Cluster-level, survives pod/node failures
- **StorageClass**: Automatic PV provisioning from cloud providers

---

## KCNA Exam Domain Coverage

### Kubernetes Fundamentals (25%)

✓ Pods, Deployments, Services, Namespaces, Labels
✓ Service discovery, pod lifecycle, restarts

### Container Orchestration (46%)

✓ Scaling, rolling updates, auto-scaling concepts
✓ Pod affinity, taints/tolerations, resource management
✓ StatefulSets, Jobs, CronJobs

### Cloud Native Architecture (16%)

✓ 12-factor app principles
✓ ConfigMaps, Secrets, immutability
✓ Init containers, lifecycle management

### Cloud Native Observability (8%)

✓ Metrics (metrics-server, kubectl top)
✓ Logging (kubectl logs)
✓ Health checks (liveness, readiness)

### Cloud Native Application Delivery (5%)

✓ Deployment strategies (rolling, canary, blue-green)
✓ Rolling updates and rollbacks

---

## Command Reference Summary

### Pod Operations

```bash
kubectl run <pod> --image=<image>
kubectl get pod <pod>
kubectl describe pod <pod>
kubectl logs <pod> [-c <container>] [--previous] [-f]
kubectl exec -it <pod> -- /bin/sh
kubectl delete pod <pod>
```

### Deployment Operations

```bash
kubectl create deployment <dep> --image=<image>
kubectl get deployment <dep>
kubectl set image deployment/<dep> <container>=<image>:<tag>
kubectl scale deployment/<dep> --replicas=<N>
kubectl rollout status deployment/<dep>
kubectl rollout history deployment/<dep>
kubectl rollout undo deployment/<dep>
kubectl rollout pause deployment/<dep>
kubectl rollout resume deployment/<dep>
```

### Service & Networking

```bash
kubectl expose pod/deployment <name> --port=80 --target-port=8080
kubectl get service <svc>
kubectl get endpoints <svc>
kubectl port-forward <pod> 8080:80
```

### Configuration

```bash
kubectl create configmap <cm> --from-literal=<key>=<value>
kubectl create secret generic <secret> --from-literal=<key>=<value>
kubectl get configmap/secret <name>
kubectl describe configmap/secret <name>
```

### Cluster & Node Information

```bash
kubectl get nodes
kubectl describe node <node>
kubectl top nodes
kubectl top pods [-n <ns>]
```

### RBAC

```bash
kubectl create serviceaccount <sa>
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa>
```

### Validation & Help

```bash
kubectl apply --dry-run=client -f file.yaml
kubectl apply --dry-run=server -f file.yaml
kubectl explain <resource>.<field>
kubectl api-resources
```

---

## Quick Fact Check

**True or False?**

| Statement                                        | Answer          | Explanation                                                        |
| ------------------------------------------------ | --------------- | ------------------------------------------------------------------ |
| Pods are smallest unit in Kubernetes             | T               | Pods are deployable units; containers cannot be deployed directly  |
| All nodes must run all pods                      | F               | Scheduler places pods on nodes based on requests, affinity, taints |
| Service selector must match exactly              | T               | Pod labels must match service selector for endpoints               |
| NetworkPolicy allows other namespaces by default | F               | Default behavior is allow-all unless policies defined              |
| Readiness probe triggers pod restart             | F               | Liveness probe triggers restart; readiness controls traffic        |
| Secrets are encrypted by default                 | F               | Only base64-encoded; encryption must be enabled separately         |
| PersistentVolume is tied to namespace            | F               | PVs are cluster-wide; PVCs are namespaced                          |
| emptyDir survives pod restart                    | T               | But deleted when pod terminates                                    |
| Rolling update requires readiness probe          | T (practically) | Without it, new pods might not get traffic before old ones removed |
| kubectl top requires metrics-server              | T               | If metrics-server not running, kubectl top won't work              |

---

## Final Review Checklist

Before taking the KCNA exam, ensure you can:

- [ ] Create and describe a pod, deployment, and service manually
- [ ] Expose a deployment as a service (ClusterIP, NodePort, LoadBalancer)
- [ ] Update a deployment image and check rollout progress
- [ ] Rollback a deployment to previous version
- [ ] Create ConfigMap and Secret; mount them in pods
- [ ] Create PersistentVolume and PersistentVolumeClaim; mount in pod
- [ ] Set resource requests and limits; explain QoS classes
- [ ] Configure liveness, readiness, startup probes
- [ ] List and understand node affinity, taints/tolerations
- [ ] Create Role, RoleBinding, and test RBAC permissions
- [ ] Create NetworkPolicy to allow/deny traffic
- [ ] Diagnose pod failures using logs, describe, events
- [ ] Test connectivity between pods and services
- [ ] Understand deployment strategies: rolling, blue-green, canary
- [ ] Interpret metrics from kubectl top
- [ ] Understand storage decisions (emptyDir, PVC, host persistent)

---

**Exam Success!** You're ready for KCNA if you've completed all exercises and understand these concepts.
