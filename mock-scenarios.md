# KCNA Mock Scenarios & Practice Questions

## Overview

This section contains realistic KCNA-style exam scenarios and multiple-choice questions to practice for the actual exam. Each scenario provides a situation and multiple possible answers. Try to answer without referencing the modules, then review the explanation.

---

## Scenario-Based Questions (Exam Format)

### Scenario 1: Production Deployment Update

**Situation:**
Your company has a production application running 10 replicas of a critical microservice. The application must process credit card transactions continuously with zero tolerance for errors. A new version (v2.0) with performance improvements is ready to deploy, but it has not been thoroughly tested in production-like conditions. The current version is v1.9 and is stable.

**Requirements:**

- Minimize risk of complete application outage
- Limit exposure to potentially buggy new code
- Must be able to quickly revert if v2.0 has issues
- Other microservices depend on API stability (can't change interfaces)

**Question:** Which deployment strategy best meets these requirements?

**Options:**
A) Rolling update with 2 pod surge, 1 pod unavailable
B) Blue-green deployment with 10 replicas running in each environment
C) Canary deployment with 1-2 replicas of v2.0, monitoring metrics, then gradually scale
D) Big bang deployment: scale old to 0, new to 10 immediately

**Answer: C (Canary Deployment)**

**Explanation:**

- **Why C is correct:** Canary deploys a small percentage first (1-2 of 10 = 10%), allowing monitoring of v2.0 without risking all traffic. If issues detected, rollback is simple. Once validated, can scale up gradually. This matches risk minimization + API stability requirements perfectly.
- **Why not A:** Rolling update doesn't provide protection against systematic bugs in v2.0; only gradual pod replacement. If v2.0 is fundamentally broken, it will break all pods.
- **Why not B:** Blue-green requires double resources (20 pods instead of 10); cost prohibitive. Also doesn't match "gradually expose" requirement.
- **Why not D:** Big bang deployment is highest risk; violates "minimize outage" requirement.

**Key Concepts Tested:**

- Understanding deployment strategies beyond basic mechanics
- Risk management in production
- Canary deployment pattern use-case

---

### Scenario 2: Persistent Data Loss

**Situation:**
Your team manages a stateful database pod running PostgreSQL with a mounted PersistentVolume. The pod crashed yesterday and was restarted by the kubelet liveness probe. Today, the database won't start—it reports "corrupted database file." The PersistentVolume was provisioned from a "slow-performance" storage class which is not replicated.

**Pod Configuration:**

```yaml
livenessProbe:
  exec:
    command: ["pg_isready"]
  initialDelaySeconds: 10
  periodSeconds: 30
  failureThreshold: 3
```

**Question:** What is the primary root cause of the data corruption?

**Options:**
A) The liveness probe crashed the database by forcing restart
B) The storage class is not replicated; single disk failure would cause loss
C) PersistentVolume was not properly bound to PVC
D) Aggressive probing caused rapid crash-restart cycle, corrupting files

**Answer: D (Probing caused rapid crash-restart cycle)**

**Explanation:**

- **Why D is correct:** The liveness probe is checking `pg_isready` every 30 seconds with `failureThreshold: 3`. If PostgreSQL crashes during data recovery, the probe quickly restarts it (3 failures × 30sec = 90sec or less). Multiple rapid restarts during recovery can corrupt the database file (writes are interrupted mid-operation).
- **Why not A:** Probes don't "crash" the database; they detect crashes. But they can restart during critical operations.
- **Why not B:** Replication helps with hardware failure, but doesn't explain THIS crash pattern.
- **Why not C:** If PVC wasn't bound, there'd be no data at all, not corruption.

**Key Concepts Tested:**

- Understanding liveness probe side effects
- Database recovery and probe timing interaction
- Why initialDelaySeconds matters (database needs time to start cleanly)

**Better Configuration:**

```yaml
livenessProbe:
  exec:
    command: ["pg_isready"]
  initialDelaySeconds: 60 # Increase for DB startup
  periodSeconds: 30
  failureThreshold: 3
```

---

### Scenario 3: Service Discovery Failure

**Situation:**
You have two microservices:

- **Frontend** (3 pods, namespace: `web`) - needs to call Backend API
- **Backend** (2 pods, namespace: `api`) - exposes Service named `backend-api`

Frontend developers report the application cannot reach the backend. The error logs show: "Cannot resolve host: backend-api". All pods are Running and Ready. No NetworkPolicy is configured.

**Question:** What is the most likely cause?

**Options:**
A) Service `backend-api` in `api` namespace doesn't have endpoints
B) Frontend pods need fully qualified name: `backend-api.api.svc.cluster.local`
C) Backend service is ClusterIP which is only accessible within the same namespace
D) CoreDNS is misconfigured and not resolving cross-namespace DNS requests

**Answer: B (Need FQDN for cross-namespace access)**

**Explanation:**

- **Why B is correct:** In Kubernetes, short names like `backend-api` only resolve within the same namespace. Cross-namespace requires FQDN: `backend-api.api.svc.cluster.local`. Frontend in `web` namespace trying to use just `backend-api` will fail.
- **Why not A:** If service had no endpoints, error would be different (timeout, not "cannot resolve").
- **Why not C:** ClusterIP works across namespaces; that's its design.
- **Why not D:** If CoreDNS was broken, even same-namespace DNS would fail, but described as working (other services work).

**Solution:**
Either:

1. Update Frontend to use FQDN: `backend-api.api.svc.cluster.local`
2. Or move both microservices to same namespace: `backend-api`

**Key Concepts Tested:**

- Service discovery DNS naming
- Cross-namespace service access
- Understanding Kubernetes DNS search domains

---

### Scenario 4: Resource Exhaustion & Eviction

**Situation:**
Your cluster has one 2-CPU, 4GB RAM node. You have:

- Pod A: requests 500m CPU + 1Gi RAM
- Pod B: requests 500m CPU + 1Gi RAM
- Pod C: requests 500m CPU + 1Gi RAM
- Pod D: requests 500m CPU + 1Gi RAM (no limits)

All pods are Running. The node suddenly experiences memory pressure. How will kubelet handle eviction?

**Question:** Which pod(s) will be evicted FIRST?

**Options:**
A) Pod D only (uses most memory, no limits)
B) Any pod with actual memory usage > requested (all are at risk equally)
C) Pod A, B, or C (Guaranteed QoS; Pod D is BestEffort)
D) Pod D only (BestEffort QoS has lowest eviction priority)

**Answer: D (Pod D will be evicted first)**

**Explanation:**

- **Why D is correct:** Pod D has NO limits specified, making it BestEffort QoS. BestEffort pods are evicted first when node is under memory pressure.
- **QoS Class Hierarchy:** Pods A, B, C are Burstable (request < limit, which defaults to none = unlimited), and Pod D is BestEffort. BestEffort (no requests/limits) is evicted first, then Burstable, then Guaranteed.
- **Why not A:** While Pod D is first, answer says "A only" which is technically correct (you asked which will evict FIRST, not all). But A is misleading since D is the one evicted for memory pressure.
- **Why not B:** Kubelet doesn't evict based on actual-vs-requested ratio primarily; it evicts based on QoS class and actual usage within that class.
- **Why not C:** Guaranteed QoS (request == limit) are NEVER evicted unless node is truly critical state.

**Key Concepts Tested:**

- QoS classes (Guaranteed, Burstable, BestEffort)
- Eviction policy (QoS-based priority)
- Resource requests and limits behavior

---

### Scenario 5: Init Container Dependency

**Situation:**
You have a web application with the following pod spec:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  initContainers:
    - name: config-generator
      image: busybox
      command: ["sh", "-c", "echo 'database_host=db.sys' > /shared/config.txt"]
      volumeMounts:
        - name: shared-data
          mountPath: /shared
  containers:
    - name: web
      image: nginx
      volumeMounts:
        - name: shared-data
          mountPath: /app/config
  volumes:
    - name: shared-data
      emptyDir: {}
```

The pod is created but remains in `Init:0/1` status for 10 minutes. There are no error events visible.

**Question:** What is the most likely issue?

**Options:**
A) Init container is running but hasn't completed yet (normal, wait longer)
B) Init container image (busybox) doesn't exist in registry
C) The emptyDir volume cannot be created (storage issue)
D) Init container is in CrashLoopBackOff but logs show no errors

**Answer: A (Init is running, normal to wait)**

**Explanation:**

- **Why A is correct:** The status shows `Init:0/1`, meaning init containers started but one is still running. This is normal; init must complete before app container starts. The `sh -c 'echo...'` should complete quickly though. But question says "10 minutes" suggests something is slower (possibly image pull or slow registry). Init status means waiting for init to finish.
- **Why not B:** If image pull failed, status would show `ImagePullBackOff`, not `Init:0/1`.
- **Why not C:** If volume creation failed, the pod would enter Pending, not Init status.
- **Why not D:** If CrashLoopBackOff, status would show that, not `Init:0/1`.

**Likely Real Issue:** Busybox image is being pulled (first time), which can take time from some registries. Once image is cached, future pods will start faster.

**Key Concepts Tested:**

- Init container behavior and status reporting
- Pod initialization phases
- Image pull delays
- Distinguishing between pod phases (Pending, Init:X/Y, Running)

---

### Scenario 6: RBAC Configuration Error

**Situation:**
You created a ServiceAccount named `app-reader` and want it to read Pods and Deployments in the `production` namespace. You created this Role:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: reader
  namespace: production
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["list"]
```

And this RoleBinding:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-reader-binding
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: reader
subjects:
  - kind: ServiceAccount
    name: app-reader
    namespace: default # <-- Different namespace!
```

Testing with `kubectl auth can-i list deployments --as=system:serviceaccount:production:app-reader` returns "no". Why?

**Options:**
A) The Role doesn't have "get" verb for deployments (missing verb)
B) The RoleBinding's subject references ServiceAccount in wrong namespace
C) The "apps" apiGroup doesn't exist (invalid apiGroup)
D) RBAC rules are case-sensitive and "deployments" should be "Deployments"

**Answer: B (RoleBinding subject references wrong namespace)**

**Explanation:**

- **Why B is correct:** The RoleBinding has `subjects.namespace: default` but ServiceAccount `app-reader` is in `production` namespace. The RoleBinding grants permissions to the wrong subject! It grants to `system:serviceaccount:default:app-reader`, not `system:serviceaccount:production:app-reader`.
- **Why not A:** Role has "list" verb for deployments (line 10), so that's correct. Besides, even if missing, the "no" result would be correct.
- **Why not C:** "apps" is correct apiGroup for Deployments.
- **Why not D:** Kubernetes is not case-sensitive for field values; "deployments" is correct.

**Fix:**

```yaml
subjects:
  - kind: ServiceAccount
    name: app-reader
    namespace: production # <-- Fix: match namespace
```

**Key Concepts Tested:**

- RBAC binding scoping
- ServiceAccount namespaces
- Role vs RoleBinding relationship
- Common RBAC mistakes

---

### Scenario 7: Pod Startup Order & Init Container Dependencies

**Situation:**
Your application has a backend database that takes 30 seconds to start. Your web pod has an init container that connects to the database to apply migrations. Without waiting, the migrations fail.

**Current initContainer:**

```yaml
initContainers:
  - name: migrate
    image: migrate-tool:latest
    command: ["migrate", "up"]
```

The pod continuously fails (CrashLoopBackOff) because migrations are timing out. You want the init to wait for the database to be ready before attempting migration.

**Which solution best follows Kubernetes design patterns?**

**Options:**
A) Change init container command to: `["sh", "-c", "for i in {1..30}; do sleep 1; done; migrate up"]`
B) Create an init container that uses probe-like logic: `["sh", "-c", "while ! nc -z db 5432; do sleep 1; done; migrate up"]`
C) Increase the init container's timeout by modifying initContainers[].timeoutSeconds: 60
D) Use a liveness probe on the database pod to maintain it running, then increase init retry count

**Answer: B (Init container waits for database readiness)**

**Explanation:**

- **Why B is correct:** The init container uses a loop to check if database is reachable (`nc -z db 5432`), waiting until it responds. This is the Kubernetes pattern: init containers poll for dependencies, not blindly wait a fixed time. This is cloud-native, idempotent, and adapts to actual startup time.
- **Why not A:** Fixed sleep of 30 seconds is fragile; what if database takes 40 seconds? What if it takes 5 seconds (waste 25 seconds)? Not cloud-native.
- **Why not C:** There's no standard `timeoutSeconds` for init containers that works this way. And even if there were, it doesn't solve the problem.
- **Why not D:** Liveness probes control pod restarts, not init behavior.

**Key Concepts Tested:**

- Init container design patterns
- Dependency management in Kubernetes
- Cloud-native patterns (adaptive vs. fixed)
- Understanding init container scope

---

### Scenario 8: NetworkPolicy Diagnostic

**Situation:**
You have a NetworkPolicy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

A pod in the `default` namespace cannot reach a service in the `kube-system` namespace (e.g., kube-dns on port 53). DNS resolution fails.

**What is the issue?**

**Options:**
A) NetworkPolicy blocks all ingress, so outbound to kube-dns is blocked
B) NetworkPolicy is namespace-scoped; it can't affect cross-namespace traffic
C) DNS uses **egress**, not ingress; this policy doesn't block egress
D) The NetworkPolicy needs "Egress" policyType to block outbound

**Answer: C (NetworkPolicy doesn't block egress; DNS uses UDP egress)**

**Explanation:**

- **Why C is correct:** The NetworkPolicy specifies only `policyTypes: ["Ingress"]`, which means "Deny all ingress, but ingress only." Egress is NOT restricted. However, DNS resolution failure suggests egress IS blocked, which means:
  - Either egress is implicitly denied separately (policies are additive, but this one doesn't specify egress)
  - OR there's a default-deny egress policy elsewhere
  - If only Ingress policyType is specified, egress is allowed by default in most CNI implementations.
- **Why not A:** Ingress policies don't affect outbound connections; that's egress.
- **Why not B:** This is partially true (NetworkPolicy is namespace-scoped), but the pod can still reach services in other namespaces unless egress is restricted.
- **Why not D:** If you want to block egress, need to add `Egress` policyType with rules.

**Likely Real Cause:** There is likely a separate default-deny egress policy, or the CNI plugin treats Ingress-only policies as deny-all.

**Fix:** Either:

1. Add explicit allow egress to kube-dns:

```yaml
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              name: kube-system
      ports:
        - protocol: UDP
          port: 53
```

**Key Concepts Tested:**

- NetworkPolicy scoping (Ingress vs Egress)
- Namespace-scoped policies
- DNS egress requirement
- Complex network policy behavior

---

### Scenario 9: Deployment Strategy & Zero-Downtime

**Situation:**
You have a Deployment with 5 replicas. You need to update the image. The application:

- Takes 10 seconds to start and become ready
- Takes 5 seconds to gracefully shutdown
- Handles requests: ~100 req/sec, each taking 1-2 seconds
- Requires minimum 4 replicas to handle load (below 4, request queue backs up)

**Current Deployment Strategy:**

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 1
```

**Will this strategy cause any request errors during update?**

**Options:**
A) No, 5 - 1 = 4 replicas means minimum is met
B) Yes, during max scaling (5 + 1 = 6) there's temporary resource waste, causing slowdowns
C) No, rolling update doesn't pause requests
D) Yes, but only during image pull phase before container starts

**Answer: A (No, 4 replicas is maintained)**

**Explanation:**

- **Why A is correct:** With `maxUnavailable: 1`, only 1 pod goes down at a time. Means minumum of 5 - 1 = 4 replicas always available. Since application needs 4+ replicas for load, this maintains SLA.
  - Timeline: 1 pod removed (4 left), new pod starts and becomes ready (10 sec), old pod fully shutdown (5 sec), next pod removed. Total for 5→5 update: ~5 cycles × 15 sec = ~75 seconds for full update.
- **Why not B:** Resource waste (6 pods) doesn't cause request errors unless node capacity exhausted, which isn't mentioned.
- **Why not C:** Rolling update does pause requests if replicas go below minimum needed.
- **Why not D:** Image pull happens before readiness; included in the 10-second startup.

**Key Concepts Tested:**

- Rolling update math (desired, maxSurge, maxUnavailable)
- Deployment strategy impact on availability
- Readiness probe timing and gracefulshutdown period

---

### Scenario 10: Storage & Data Lifecycle

**Situation:**
You have 100 application pods that generate temporary log files. Each pod writes 100MB/day to a directory. You want:

- Per-pod isolated storage (each pod's logs separate)
- Logs persisted across pod restart
- Automatic cleanup of old logs (>7 days)

**Which storage solution is appropriate?**

**Options:**
A) PersistentVolume (PV) + PersistentVolumeClaim (PVC) for each pod, with TTL cleanup job
B) emptyDir volume (doesn't require PVC) with daily cleanup job
C) Hostpath volume mounted directly from node
D) Single shared PVC mounted by all pods with subdirectories

**Answer: A (PV + PVC for isolation + cleanup job)**

**Explanation:**

- **Why A is correct:**
  - Per-pod isolation: Each pod gets its own PVC (100 pods = 100 PVCs)
  - Persistence: PV survives pod restart
  - Cleanup: kubectl annotations or CronJob can trigger cleanup job to delete files >7 days old (implemented as `find /mnt -mtime +7 -delete`)
  - Scales properly for 100 pods across nodes
- **Why not B:** `emptyDir` is NOT persistent; deleted when pod terminates. Explicitly fails the "persisted across restart" requirement.
- **Why not C:** Hostpath couples to specific nodes; doesn't work for multi-node. What if pod moves to different node?
- **Why not D:** Single shared PVC means any pod can see/modify others' logs; fails isolation requirement.

**Key Concepts Tested:**

- Storage selection based on requirements
- PV vs PVC vs emptyDir lifecycle
- Pod isolation patterns
- Data lifecycle management

---

## Quick Multiple Choice Practice (5-min section)

### Q1: ConfigMap Update

**Question:** You update a ConfigMap that a pod has mounted as a volume. How long until the pod sees the new data?

A) Immediately (kubelet watches ConfigMap in real-time)
B) At next pod restart (ConfigMap is baked into pod spec)
C) Within a few seconds to 1 minute (kubelet eventually syncs changes)
D) Never (ConfigMap changes don't affect running pods)

**Answer: C** (kubelet syncs volume changes every 10-60 seconds by default)

---

### Q2: Service ClusterIP

**Question:** Can a pod in namespace `api` access a ClusterIP Service named `auth` in namespace `auth` using the name `auth`?

A) Yes, short names work across all namespaces
B) No, must use fully qualified name `auth.auth.svc.cluster.local`
C) Only if both are in same node (local traffic)
D) Only if there's a corresponding DNS CNAME entry

**Answer: B** (short names only work within same namespace)

---

### Q3: Rollback

**Question:** You rollback a deployment with `kubectl rollout undo`. The ReplicaSet from the previous revision...

A) Is immediately scaled to original replica count
B) Is scaled proportionally based on current state
C) Remains at 0 replicas; must manually scale
D) Is deleted and recreated from backup

**Answer: A** (previous ReplicaSet is immediately scaled up; old is scaled down)

---

### Q4: Probe Failure

**Question:** A pod liveness probe fails 3 times (failureThreshold: 3). The pod will...

A) Immediately restart
B) Be evicted from node
C) Enter Failed state
D) Restart after gracefulTerminationPeriod

**Answer: D** (pod is terminated and restarted by kubelet; respects gracefulTerminationPeriod)

---

### Q5: Namespace Deletion

**Question:** You delete a namespace with `kubectl delete namespace dev`. What happens to all pods in that namespace?

A) Pods are forcefully killed immediately
B) Pods receive SIGTERM and have 30 seconds (default termination grace period) to shutdown gracefully
C) Nothing; namespace deletion is blocked if pods exist
D) Pods are moved to `default` namespace

**Answer: B** (namespace deletion cascades to all resources with graceful shutdown)

---

## Mock Exam Scoring Guide

- **9-10 correct out of 10**: Excellent (likely 90%+ on actual exam)
- **7-8 correct**: Good (likely 75-85% on actual exam)
- **5-6 correct**: Adequate (likely 60-75%, borderline pass)
- **<5 correct**: Study more (focus on failed domains)

---

## Answer Key Summary

| Q   | Scenario            | Domain                    | Answer                         |
| --- | ------------------- | ------------------------- | ------------------------------ |
| 1   | Deployment Strategy | Container Orchestration   | C (Canary)                     |
| 2   | Data Loss           | Cloud Native Architecture | D (Probe cycling)              |
| 3   | DNS Failure         | Kubernetes Fundamentals   | B (FQDN required)              |
| 4   | Eviction Policy     | Container Orchestration   | D (BestEffort first)           |
| 5   | Init Dependency     | Kubernetes Fundamentals   | A (Normal, init running)       |
| 6   | RBAC Config         | Cloud Native Architecture | B (Wrong namespace)            |
| 7   | Init Dependency     | Cloud Native Architecture | B (Poll for readiness)         |
| 8   | NetworkPolicy       | Container Orchestration   | C (Blocks ingress, not egress) |
| 9   | Deployment Math     | Container Orchestration   | A (4 min maintained)           |
| 10  | Storage Selection   | Container Orchestration   | A (PV + PVC + cleanup)         |
| Q1  | ConfigMap           | Cloud Native Architecture | C (1-60 seconds)               |
| Q2  | Service DNS         | Kubernetes Fundamentals   | B (FQDN required)              |
| Q3  | Rollback            | Container Orchestration   | A (Immediate scale-up)         |
| Q4  | Probe               | Container Orchestration   | D (Graceful shutdown)          |
| Q5  | Namespace           | Kubernetes Fundamentals   | B (SIGTERM + grace)            |

---

**Next Steps:** Review failed scenarios in corresponding modules, then retry practice questions to verify understanding.
