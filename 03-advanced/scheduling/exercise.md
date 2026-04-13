# Exercise: Scheduling & Resource Management - Pod Placement

## 📌 Problem Statement

Control where Pods run and how resources are allocated in the cluster. You'll learn to use labels, node affinity, taints/tolerations, and resource constraints to ensure applications run on appropriate nodes and don't exhaust cluster resources.

## 🎯 Learning Objectives

By completing this exercise, you will be able to:

1. Use labels and selectors to organize resources
2. Control Pod placement with node affinity (preferred and required)
3. Use pod affinity/anti-affinity for pod-to-pod relationships
4. Implement taints and tolerations for node restrictions
5. Set resource requests and limits
6. Understand resource allocation and scheduling decisions
7. Debug scheduling failures

## 📝 Exercises

### Exercise 1.1: Labels and Selectors

**Objective:** Use labels to organize and query resources.

**Instructions:**

1. Create a Deployment with labels:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web
    environment: production
    team: platform
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        environment: production
        team: platform
        version: v1
    spec:
      containers:
        - name: web
          image: nginx:latest
          ports:
            - containerPort: 80
```

2. Verify labels and use selectors to filter

**Verification Steps:**

```bash
# Apply deployment
kubectl apply -f web-app.yaml

# View pods with labels
kubectl get pods --show-labels

# Query by single label
kubectl get pods -l app=web

# Query by multiple labels (AND condition)
kubectl get pods -l app=web,environment=production

# Query with different operators
kubectl get pods -l 'app in (web,api)'
kubectl get pods -l 'team!=platform'
kubectl get pods -l version

# Count pods matching label
kubectl get pods -l app=web --no-headers | wc -l

# Show specific label column
kubectl get pods -L app,team,version

# Describe pod to see labels
kubectl describe pod <pod-name> | grep Labels
```

**Expected Outcomes:**

- Pods created with labels visible in labels column
- Selector queries filter correctly
- Can use label operators (in, notin, =, !=)
- Label information helps organize resources

**Label Best Practices:**

- `app`: Application name
- `version`: Application version
- `environment`: dev, staging, production
- `team`: Owning team
- `component`: frontend, backend, database
- Custom labels for your use case

---

### Exercise 1.2: Node Labels and Node Selector

**Objective:** Label nodes and use node selector to place Pods.

**Instructions:**

1. Label your nodes:

```bash
# Get node names
kubectl get nodes

# Label a node
kubectl label nodes <node-name> disktype=ssd
kubectl label nodes <node-name> gpu=true
```

2. Create deployment requesting specific node label:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fast-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: fast-app
  template:
    metadata:
      labels:
        app: fast-app
    spec:
      nodeSelector:
        disktype: ssd
      containers:
        - name: app
          image: nginx:latest
```

**Verification Steps:**

```bash
# View node labels
kubectl get nodes --show-labels

# Label node
kubectl label nodes <node-name> disktype=ssd

# Verify label applied
kubectl get nodes --show-labels | grep disktype

# Apply deployment
kubectl apply -f fast-app.yaml

# Check which node pod is on
kubectl get pods -o wide

# Try to remove label - pod should go to pending
kubectl label nodes <node-name> disktype-

# Pod will try to reschedule
kubectl get pods -o wide

# Re-add label - pod should start
kubectl label nodes <node-name> disktype=ssd
```

**Expected Outcomes:**

- Nodes labeled successfully
- Pod with nodeSelector only runs on matching nodes
- If label removed, Pod goes to "Pending" (waiting for node)
- If label re-added, Pod schedules normally

**Limitations of nodeSelector:**

- Simple label matching (AND only)
- Can't express "not this label" or "this OR that"
- Use Node Affinity for more complex rules

---

### Exercise 1.3: Node Affinity (Preferred and Required)

**Objective:** Use affinity rules for flexible node placement.

**Instructions:**

1. Create deployment with required node affinity:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: required-affinity-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: required-affinity
  template:
    metadata:
      labels:
        app: required-affinity
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: disktype
                    operator: In
                    values:
                      - ssd
      containers:
        - name: app
          image: nginx:latest
```

2. Create with preferred node affinity:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: preferred-affinity-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: preferred-affinity
  template:
    metadata:
      labels:
        app: preferred-affinity
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              preference:
                matchExpressions:
                  - key: disktype
                    operator: In
                    values:
                      - ssd
      containers:
        - name: app
          image: nginx:latest
```

**Verification Steps:**

```bash
# Apply both deployments
kubectl apply -f required-affinity-app.yaml
kubectl apply -f preferred-affinity-app.yaml

# Check where pods scheduled
kubectl get pods -o wide

# Required affinity pods: only on SSD nodes
# Preferred affinity pods: prefer SSD but can run elsewhere

# Remove SSD label from nodes
kubectl label nodes <node-name> disktype-

# Required pods go to Pending
kubectl get pods required-affinity-app-* -o wide

# Preferred pods still run (just less ideal)
kubectl get pods preferred-affinity-app-* -o wide

# Check pod events
kubectl describe pod <required-pod-name> | grep -A 5 Events

# Re-add label
kubectl label nodes <node-name> disktype=ssd

# Required pods reschedule
kubectl get pods required-affinity-app-* -o wide
```

**Expected Outcomes:**

- Required affinity pods: Won't schedule if no matching nodes
- Preferred affinity pods: Will schedule on any node (but prefer matching)
- Can see scheduling decisions in Pod events
- More flexible than nodeSelector

**Affinity Operators:**

- `In`: Value is in the list
- `NotIn`: Value is not in list
- `Exists`: Keyexists (value doesn't matter)
- `DoesNotExist`: Key doesn't exist
- `Gt`: Greater than (numeric)
- `Lt`: Less than (numeric)

---

### Exercise 1.4: Pod Affinity and Anti-Affinity

**Objective:** Use Pod-to-Pod relationships for placement.

**Instructions:**

1. Deploy a backend Pod first (label it as critical):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: backend
  labels:
    app: backend
spec:
  containers:
    - name: backend
      image: nginx:latest
```

2. Create frontend that wants to run near backend (affinity):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - backend
          topologyKey: kubernetes.io/hostname
  containers:
    - name: frontend
      image: nginx:latest
```

3. Create cache that wants to stay away from backend (anti-affinity):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cache
spec:
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
                - key: app
                  operator: In
                  values:
                    - backend
            topologyKey: kubernetes.io/hostname
  containers:
    - name: cache
      image: redis:latest
```

**Verification Steps:**

```bash
# Apply backend
kubectl apply -f backend-pod.yaml
kubectl get pods -o wide

# Get backend node
BACKEND_NODE=$(kubectl get pod backend -o jsonpath='{.spec.nodeName}')
echo "Backend on: $BACKEND_NODE"

# Apply frontend (should be on SAME node as backend)
kubectl apply -f frontend-pod.yaml
FRONTEND_NODE=$(kubectl get pod frontend -o jsonpath='{.spec.nodeName}')
echo "Frontend on: $FRONTEND_NODE"

# Should match
[ "$BACKEND_NODE" = "$FRONTEND_NODE" ] && echo "✓ Pod affinity working"

# Apply cache (should be on DIFFERENT node from backend)
kubectl apply -f cache-pod.yaml
CACHE_NODE=$(kubectl get pod cache -o jsonpath='{.spec.nodeName}')
echo "Cache on: $CACHE_NODE"

# Should NOT match
[ "$BACKEND_NODE" != "$CACHE_NODE" ] && echo "✓ Pod anti-affinity working"
```

**Expected Outcomes:**

- Frontend runs on same node as backend (affinity)
- Cache runs on different node from backend (anti-affinity)
- topologyKey controls scope (node, zone, region, etc.)
- Useful for locality (low latency) and distribution

**topologyKey values:**

- `kubernetes.io/hostname`: Same node
- `topology.kubernetes.io/zone`: Same zone
- `topology.kubernetes.io/region`: Same region
- Custom labels for specific topology

---

### Exercise 1.5: Taints and Tolerations

**Objective:** Use taints to restrict which Pods can run on nodes.

**Instructions:**

1. Taint a node:

```bash
# Add NoSchedule taint (no new pods)
kubectl taint nodes <node-name> key=value:NoSchedule

# View taints
kubectl describe node <node-name> | grep Taints

# Try to schedule pod without toleration - goes to Pending
kubectl run test-pod --image=nginx --restart=Never
kubectl get pods -o wide
```

2. Create Pod with matching toleration:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tolerant-pod
spec:
  tolerations:
    - key: key
      operator: Equal
      value: value
      effect: NoSchedule
  containers:
    - name: app
      image: nginx:latest
```

3. Verify Pod schedules on tainted node

**Verification Steps:**

```bash
# Add taint to node
kubectl taint nodes <node-name> gpu=true:NoSchedule

# View taints
kubectl describe node <node-name> | grep -A 3 Taints

# Try regular pod - goes to pending
kubectl run regular-pod --image=nginx

# Create tolerant pod
kubectl apply -f tolerant-pod.yaml

# Check pod placement
kubectl get pods -o wide

# Tolerant pod should be on tainted node
# Regular pod should be Pending

# Remove taint
kubectl taint nodes <node-name> gpu-

# Regular pod should reschedule
watch kubectl get pods
```

**Expected Outcomes:**

- Tainted node rejects normal Pods
- Pods with matching toleration can run on tainted node
- Taints useful for: dedicated nodes, special hardware, reserved capacity

**Taint Effects:**

- `NoSchedule`: Don't schedule new pods
- `PreferNoSchedule`: Try to avoid, but schedule if needed
- `NoExecute`: Don't schedule new pods, evict existing ones (dangerous!)

---

### Exercise 1.6: Resource Requests and Limits

**Objective:** Control CPU and memory resource allocation.

**Instructions:**

1. Create deployment with resource requests and limits:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-limited-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: resource-limited
  template:
    metadata:
      labels:
        app: resource-limited
    spec:
      containers:
        - name: app
          image: nginx:latest
          resources:
            requests:
              cpu: 100m # 0.1 CPU
              memory: 128Mi
            limits:
              cpu: 500m # 0.5 CPU
              memory: 512Mi
```

2. Monitor resource usage and limits

**Verification Steps:**

```bash
# Apply deployment
kubectl apply -f resource-limited-app.yaml

# Check resource allocation
kubectl describe deployment resource-limited-app

# View requests and limits in pod spec
kubectl get pods -l app=resource-limited -o yaml | grep -A 3 resources:

# Check node capacity
kubectl describe node <node-name> | grep -A 5 Allocated

# View actual usage (requires metrics-server)
kubectl top nodes
kubectl top pods

# Try to exceed limit (will be killed)
kubectl exec -it <pod-name> -- stress-ng --vm 1 --vm-bytes 600M --timeout 10s

# Pod will be OOMKilled (out of memory)
kubectl describe pod <pod-name> | grep -A 3 State

# Check restart count increased
kubectl get pods
```

**Expected Outcomes:**

- Pods get allocated requested resources
- Scheduler ensures node has enough capacity
- If Pod exceeds limits, it's throttled (CPU) or killed (memory)
- Actual usage visible with metrics-server

**Requests vs Limits:**

- **Request**: Guaranteed minimum, used for scheduling
- **Limit**: Maximum allowed, pod gets killed if exceeded
- **Best practice**: Set both, usually limit = 2-3x request

**Resource Units:**

- CPU: millicores (m), 1000m = 1 CPU core
- Memory: bytes (Ki, Mi, Gi), 1024 Ki = 1 Mi

---

### Exercise 1.7: Scheduling Failures and Debugging

**Objective:** Debug pods that won't schedule.

**Scenarios:**

**Scenario 1: Insufficient resources**

```bash
# Create pod requesting more resources than available
cat > resource-hog.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: resource-hog
spec:
  containers:
  - name: app
    image: nginx:latest
    resources:
      requests:
        cpu: 100  # 100 CPU cores!
        memory: 1Ti
EOF

kubectl apply -f resource-hog.yaml

# Pod will be Pending

# Debug:
kubectl describe pod resource-hog
# Shows: "Insufficient cpu", "Insufficient memory"

kubectl describe node <node-name> | grep -A 5 Allocatable
```

**Scenario 2: Node selector mismatch**

```bash
# Pod requesting non-existent label
cat > missing-label.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: missing-label
spec:
  nodeSelector:
    nonexistent: label
  containers:
  - name: app
    image: nginx:latest
EOF

kubectl apply -f missing-label.yaml

# Pod Pending

# Debug:
kubectl describe pod missing-label
# Shows node selector mismatch
```

**Scenario 3: Required affinity unfulfillable**

```bash
# Affinity requiring non-existent node
cat > bad-affinity.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: bad-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: nonexistent
            operator: Exists
  containers:
  - name: app
    image: nginx:latest
EOF

# Pod Pending

# Debug:
kubectl describe pod bad-affinity
# Shows: "0/1 nodes available: 1 node(s) didn't match node selector"
```

**Debugging Commands:**

```bash
# Describe pod - see Events section
kubectl describe pod <name>

# Check scheduler logs (if accessible)
kubectl logs -n kube-system -l component=kube-scheduler

# Check node resources
kubectl top nodes
kubectl describe node <name>

# Check pod events
kubectl get events --field-selector involvedObject.name=<pod-name>

# Check pod scheduling details
kubectl get pod <name> -o yaml | grep -A 20 affinity
```

---

### Exercise 1.8: Cleanup

**Objective:** Clean up scheduling resources.

**Verification Steps:**

```bash
# Delete deployments and pods
kubectl delete deployment --all
kubectl delete pod --all

# Remove node labels
kubectl label nodes <node-name> disktype- gpu-

# Remove taints
kubectl taint nodes <node-name> key- gpu-

# Verify cleanup
kubectl get pods
kubectl get deployments
kubectl get nodes --show-labels
```

---

## 🧠 Key Concepts Explained

### Scheduling Decision Flow

```
Pod created
  ↓
Filters (node affinity, taints, resource requirements)
  ↓
Scoring (preferred affinity, resource optimization)
  ↓
Binds to best node
```

### Label Selector Operators

| Operator    | Example            | Meaning                |
| ----------- | ------------------ | ---------------------- |
| `=`         | `app=web`          | Exact match            |
| `!=`        | `env!=dev`         | Not equal              |
| `in`        | `app in (web,api)` | Value in list          |
| `notin`     | `env notin (dev)`  | Value not in list      |
| key present | `team`             | Key exists (any value) |
| key absent  | `!team`            | Key doesn't exist      |

### Affinity Types

| Type                  | Behavior              | Binding                             |
| --------------------- | --------------------- | ----------------------------------- |
| **Node Affinity**     | Pod to nodes          | Hard (required) or soft (preferred) |
| **Pod Affinity**      | Pod to pod (colocate) | Hard or soft                        |
| **Pod Anti-Affinity** | Pod away from pod     | Hard or soft                        |
| **Node Selector**     | Simple pod to node    | Hard only                           |

---

## 💡 Best Practices

✅ **DO:**

- Use labels consistently across applications
- Set resource requests for better scheduling
- Use pod affinity for latency-sensitive services
- Use anti-affinity for distributed systems
- Use taints only for special hardware/reserved nodes

❌ **DON'T:**

- Forget to set resource requests (causes overprovisioning)
- Use very high resource limits (waste capacity)
- Use required affinity unless absolutely necessary
- Taint all nodes (leaves nowhere to schedule)
- Assume scheduling is instant (takes time)

---

## ✅ Exercise Completion Checklist

- [ ] Used labels to organize and filter resources
- [ ] Labeled nodes and used node selector
- [ ] Implemented node affinity (required and preferred)
- [ ] Created pods with pod affinity
- [ ] Created pods with pod anti-affinity
- [ ] Tainted node and created tolerant pods
- [ ] Set resource requests and limits
- [ ] Observed metrics-server resource usage
- [ ] Debugged scheduling failures
- [ ] Cleaned up all resources
- [ ] Ready to move to Lifecycle exercises

---

## 🎓 Next Steps

Once complete, move to `lifecycle/exercise.md` to learn about health checks and pod lifecycle.

## 📚 Reference

Check `/templates/deployment-template.yaml` for resource configuration examples.
