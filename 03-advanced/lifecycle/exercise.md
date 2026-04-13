# Exercise: Pod Lifecycle - Health Checks and Initialization

## Problem Statement

Manage Pod lifecycle from creation to termination. You'll implement health checks to ensure Pods only receive traffic when ready, use init containers for setup, and configure lifecycle hooks for graceful handling of events.

## Learning Objectives

By completing this exercise, you will be able to:

1. Implement liveness probes to detect and restart failing applications
2. Implement readiness probes to control service endpoint inclusion
3. Use init containers for pre-application setup
4. Configure lifecycle hooks (preStop, postStart)
5. Understand Pod phase transitions
6. Debug probe failures and restart loops

## Exercises

### Exercise 1.1: Liveness Probe (HTTP)

**Objective:** Detect when Pod application is stuck and needs restart.

**Instructions:**

1. Create pod with HTTP liveness probe:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-http
spec:
  containers:
    - name: app
      image: nginx:latest
      ports:
        - containerPort: 80
      livenessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 10 # Give app time to start
        periodSeconds: 5 # Check every 5 seconds
        failureThreshold: 3 # Kill after 3 failures
        timeoutSeconds: 2 # Timeout each check at 2s
```

2. Test normal behavior - app is healthy
3. Destroy app process - observe pod restart

**Verification Steps:**

```bash
# Apply pod
kubectl apply -f liveness-http.yaml

# Watch pod (normal running)
kubectl get pod liveness-http

# Check liveness probe in describe
kubectl describe pod liveness-http | grep -A 10 Liveness

# Exec in and kill nginx to trigger probe failure
kubectl exec liveness-http -- pkill -f nginx

# Watch pod restart
watch kubectl get pod liveness-http

# Check restart count
kubectl get pod liveness-http -o jsonpath='{.status.containerStatuses[0].restartCount}'

# Verify pod restarted itself (normal nginx back)
kubectl exec liveness-http -- curl localhost/
```

**Expected Outcomes:**

- Pod starts and runs normally
- When app process killed, liveness probe fails
- After 3 consecutive failures, pod is restarted
- Restart count increases
- Container starts fresh after restart
- Pod is continuously restarted in CrashLoopBackOff style if app keeps dying

---

### Exercise 1.2: Readiness Probe

**Objective:** Control when Pod receives traffic from Services.

**Instructions:**

1. Create deployment with readiness probe:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: readiness-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: readiness-test
  template:
    metadata:
      labels:
        app: readiness-test
    spec:
      containers:
        - name: app
          image: busybox:latest
          command: ["sh", "-c"]
          args:
            - |
              echo "0" > /tmp/ready
              sleep 5  # Simulate startup time
              echo "1" > /tmp/ready
              sleep 3600
          readinessProbe:
            exec:
              command:
                - test
                - -f
                - /tmp/ready
            initialDelaySeconds: 3
            periodSeconds: 2
```

2. Create service pointing to deployment
3. Test traffic routing before pod is ready

**Verification Steps:**

```bash
# Apply deployment
kubectl apply -f readiness-app.yaml

# Create service
kubectl expose deployment readiness-app --port=80 --target-port=8080 --type=ClusterIP

# Watch pods coming ready
watch kubectl get pods -l app=readiness-test

# Check endpoint status (should show not ready initially)
kubectl describe endpoints readiness-app

# Once ready, endpoints appear
kubectl get endpoints readiness-app

# Exec and disable readiness
kubectl exec <pod-name> -- sh -c 'rm /tmp/ready'

# Pod goes NotReady
kubectl get pods

# Endpoints removed pod
kubectl get endpoints readiness-app

# Re-enable readiness
kubectl exec <pod-name> -- sh -c 'echo 1 > /tmp/ready'

# Pod becomes ready again
watch kubectl get pods

# Endpoints restored
kubectl get endpoints readiness-app
```

**Expected Outcomes:**

- Pod starts but initially not ready (startup time)
- Service doesn't route traffic to pod until ready
- Once ready, pod appears in service endpoints
- If readiness check fails, pod removed from service (no traffic)
- Pod itself keeps running (not restarted)
- Readiness check passes, pod re-added to service

**Liveness vs Readiness:**
| Probe | Purpose | Failure Action |
|-------|---------|---|
| Liveness | Detect stuck app | Restart pod |
| Readiness | Detect not-ready app | Remove from service |

---

### Exercise 1.3: Startup Probe

**Objective:** Handle applications with long startup times.

**Instructions:**

1. Create pod with startup probe for slow-starting app:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: startup-probe
spec:
  containers:
    - name: app
      image: busybox:latest
      command: ["sh", "-c"]
      args:
        - |
          echo "Starting slow application..."
          sleep 20  # Simulate long startup
          echo "Ready!"
          sleep 3600
      startupProbe:
        exec:
          command:
            - test
            - -f
            - /proc/self/exe
        failureThreshold: 30 # 30 * 10 = 300 seconds max startup
        periodSeconds: 10
      livenessProbe:
        exec:
          command:
            - test
            - -f
            - /proc/self/exe
        initialDelaySeconds: 5
        periodSeconds: 10
```

2. Verify pod isn't restarted during long startup
3. Then verify liveness probe takes over after startup

**Verification Steps:**

```bash
# Apply pod
kubectl apply -f startup-probe.yaml

# Watch during startup - should NOT restart
watch kubectl get pod startup-probe

# Check restart count
kubectl get pod startup-probe -o jsonpath='{.status.containerStatuses[0].restartCount}'

# Should be 0 (not restarted during startup)

# Describe to see all probe info
kubectl describe pod startup-probe | grep -A 5 'Probes'

# Once started, liveness probe monitors
```

**Expected Outcomes:**

- Pod doesn't get restarted during 20-second startup
- Startup probe gives liveness probe time to work
- Restart count stays at 0 during startup
- After startup, liveness probe monitors health

**When to Use Startup Probe:**

- Applications with long initialization
- Database migrations at startup
- Large file downloads
- Typical startup time > 30 seconds

---

### Exercise 1.4: Init Containers

**Objective:** Use init containers for setup before main app starts.

**Instructions:**

1. Create pod with init container:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-container-example
spec:
  initContainers:
    - name: setup
      image: busybox:latest
      command: ["sh", "-c"]
      args:
        - |
          echo "Init container: Preparing filesystem..."
          echo "Setting up configuration files..."
          echo "Waiting for dependencies..."
          sleep 5
          echo "Setup complete!"
    - name: db-check
      image: busybox:latest
      command: ["sh", "-c"]
      args:
        - |
          echo "Checking database connectivity..."
          sleep 2
          echo "Database ready!"
  containers:
    - name: app
      image: busybox:latest
      command: ["sh", "-c"]
      args:
        - |
          echo "Application: All init containers completed!"
          echo "I can now assume dependencies are ready"
          sleep 3600
```

2. Verify init containers run before main app
3. Verify failure in init container prevents main app from starting

**Verification Steps:**

```bash
# Apply pod
kubectl apply -f init-container-example.yaml

# Immediately check - should see init containers running
kubectl get pod init-container-example -o wide

# Watch progression
watch kubectl get pod init-container-example

# View events
kubectl describe pod init-container-example

# Should show: setup container done → db-check running → app running

# View logs of init containers
kubectl logs init-container-example -c setup
kubectl logs init-container-example -c db-check
kubectl logs init-container-example -c app

# Try failing init container
cat > failing-init.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: failing-init
spec:
  initContainers:
  - name: setup
    image: busybox:latest
    command: ['sh']
    args: ['-c', 'exit 1']  # Init container fails
  containers:
  - name: app
    image: busybox:latest
    command: ['sleep', '3600']
EOF

kubectl apply -f failing-init.yaml

# Pod stuck in Init:0/1 (init container failed)
kubectl get pod failing-init

# Check events
kubectl describe pod failing-init  # Shows init container failure

# Delete pods
kubectl delete pod failing-init
```

**Expected Outcomes:**

- Init containers run sequentially (one at a time)
- Each init container must succeed before next starts
- Main app only starts after all init containers complete
- If init container fails, main app never starts
- Pod stuck in "Initializing" phase
- Can see init logs separately from main app

**Init Container Use Cases:**

- Database migrations
- Waiting for dependencies (service mesh, config servers)
- Downloading secrets/configs from external services
- File system setup and permissions
- Validating host environment

---

### Exercise 1.5: Lifecycle Hooks (postStart and preStop)

**Objective:** Execute scripts at key lifecycle points.

**Instructions:**

1. Create pod with lifecycle hooks:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-hooks
spec:
  containers:
    - name: app
      image: busybox:latest
      command: ["sh", "-c"]
      args:
        - |
          echo "Main app running"
          sleep 3600
      lifecycle:
        postStart:
          exec:
            command:
              ["/bin/sh", "-c", 'echo "Post-start hook executed"; sleep 3']
        preStop:
          exec:
            command:
              ["/bin/sh", "-c", 'echo "Pre-stop hook executing"; sleep 5']
```

2. Create pod and watch lifecycle transitions
3. Delete pod and observe preStop hook

**Verification Steps:**

```bash
# Apply pod
kubectl apply -f lifecycle-hooks.yaml

# Describe to see lifecycle hooks configured
kubectl describe pod lifecycle-hooks | grep -A 3 Lifecycle

# Give postStart time to complete
sleep 5

# Delete pod and immediately watch
kubectl delete pod lifecycle-hooks &
watch 'kubectl get pod lifecycle-hooks 2>/dev/null || echo "Pod deleted"'

# Pod should show "Terminating" for ~5 seconds (preStop sleep)

# Check logs if hook output is visible
kubectl logs lifecycle-hooks 2>/dev/null
```

**Expected Outcomes:**

- postStart hook runs after container starts (before readiness probe)
- preStop hook runs before termination (gives graceful shutdown time)
- Pod removal is delayed by preStop hook duration
- Useful for cleanup before termination

**Use Cases:**

- **postStart**: Warm up caches, verify sidecars started
- **preStop**: Graceful shutdown, drain connections, cleanup resources

**Note:** Hooks run alongside main process, not blocking it

---

### Exercise 1.6: Probe Configuration Examples

**Objective:** Understand different probe types and their configuration.

**Instructions:**

1. Create pod with multiple probe types:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: probe-examples
spec:
  containers:
    - name: app
      image: nginx:latest
      readinessProbe:
        httpGet:
          path: /
          port: 80
          httpHeaders:
            - name: X-Custom-Header
              value: Awesome
        initialDelaySeconds: 5
        periodSeconds: 10
      livenessProbe:
        tcpSocket:
          port: 80
        initialDelaySeconds: 15
        periodSeconds: 20
      startupProbe:
        httpGet:
          path: /
          port: 80
        failureThreshold: 30
        periodSeconds: 10
```

2. Test each probe type

**Verification Steps:**

```bash
# Apply pod
kubectl apply -f probe-examples.yaml

# Check all probes configured
kubectl get pod probe-examples -o yaml | grep -A 10 '\- name: app' | grep -A 10 'Probe'

# Describe to see probe configuration
kubectl describe pod probe-examples | grep -A 5 Probes

# Each probe type can use:
# - httpGet (HTTP status 200-399 = success)
# - exec (exit code 0 = success)
# - tcpSocket (port accessible = success)
```

**Probe Types Comparison:**

| Type          | Pros              | Cons                        |
| ------------- | ----------------- | --------------------------- |
| **httpGet**   | Easy, standard    | App must serve HTTP         |
| **exec**      | Works for any app | Slower, resource intensive  |
| **tcpSocket** | Fast, lightweight | Doesn't check app readiness |

---

### Exercise 1.7: Debugging Probe Failures

**Objective:** Understand and fix probe issues.

**Scenarios:**

**Scenario 1: Probe fails because port not open**

```bash
# Pod with wrong port in probe
cat > wrong-port-probe.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: wrong-port
spec:
  containers:
  - name: app
    image: nginx:latest
    ports:
    - containerPort: 80
    readinessProbe:
      httpGet:
        path: /
        port: 8080  # Wrong port!
      initialDelaySeconds: 3
EOF

kubectl apply -f wrong-port-probe.yaml

# Pod will be NotReady

# Debug:
kubectl describe pod wrong-port  # Shows connection refused errors
```

**Scenario 2: Probe timeout too short**

```bash
# Slow app, but probe times out
cat > timeout-probe.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: timeout-probe
spec:
  containers:
  - name: app
    image: busybox:latest
    command: ['sh', '-c', 'sleep 3600']
    readinessProbe:
      exec:
        command: ['sleep', '5']
      timeoutSeconds: 1  # Too short!
      periodSeconds: 2
EOF

kubectl apply -f timeout-probe.yaml

# Debug:
kubectl describe pod timeout-probe  # Shows timeout errors
```

**Debugging Steps:**

```bash
# 1. Check probe configuration
kubectl get pod <name> -o yaml | grep -A 10 Probe

# 2. Verify port/endpoint
kubectl exec <pod> -- netstat -tuln  # Check listening ports

# 3. Test manually
kubectl exec <pod> -- curl localhost:80

# 4. Check logs
kubectl logs <pod>

# 5. Describe for events
kubectl describe pod <name> | grep -A 20 Events

# 6. Increase timeout
kubectl edit pod <pod>  # Edit timeoutSeconds
```

---

### Exercise 1.8: Pod Disruption Budgets (Optional)

**Objective:** Protect Pods during voluntary disruptions.

**Instructions:**

1. Create PDB to protect deployment:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2 # Always keep at least 2 pods running
  selector:
    matchLabels:
      app: critical-app
```

2. Try to evict pods - should respect PDB

---

### Exercise 1.9: Cleanup

**Objective:** Delete all lifecycle test pods.

**Verification Steps:**

```bash
# Delete all test pods
kubectl delete pod --all
kubectl delete deployment --all

# Verify cleanup
kubectl get pods
```

---

## 🧠 Key Concepts Explained

### Pod Lifecycle Phases

```
Pending → Running → Succeeded/Failed/Unknown
         ↑         ↑
      Probes    Termination
```

**Pending:** Pod created, waiting to be scheduled  
**Running:** Pod scheduled, at least one container running  
**Succeeded:** All containers exited with code 0  
**Failed:** At least one container exited with non-zero code

### Probe Timing

```
Pod Creation
  ↓ (startup probe - optional)
Startup Probe (max 30 failures * period = 300s default)
  ↓
Container Ready (readiness probe)
  ↓
Service routes traffic
  ↓
Liveness Probe (continuous monitoring)
  ↓
Pod Termination (preStop hook)
```

### probe.failureThreshold

- How many consecutive failures before action taken
- Liveness: default 3
- Readiness: default 1 (very sensitive)
- Startup: default 3

### Health Check Strategy

**Readiness Probe**: Detects if app is ready to serve

```bash
# Check app completed startup, dependencies available
curl http://localhost:8080/health
# Should return 200 if ready
```

**Liveness Probe**: Detects if app is alive

```bash
# Check basic connectivity (less strict than readiness)
curl http://localhost:8080/alive
# Can be simpler than readiness
```

---

## Best Practices

DO:

- Implement both liveness and readiness probes
- Use readiness probe stricter than liveness (avoid restart loops)
- Give adequate initialDelaySeconds (app must start first)
- Use startup probe for slow-starting apps
- Use preStop hooks for graceful shutdown

DON'T:

- Make liveness probe too aggressive (constant restarts)
- Forget initialDelaySeconds (probe runs too early)
- Use only TCP or exec probes if HTTP available
- Make probes do heavy operations (runs frequently)
- Ignore probe failures (indicates production issues)

---

## Exercise Completion Checklist

- [ ] Implemented HTTP liveness probe
- [ ] Implemented readiness probe
- [ ] Used startup probe for slow startup
- [ ] Created pods with init containers
- [ ] Verified init containers run sequentially
- [ ] Configured postStart and preStop hooks
- [ ] Tested multiple probe types (httpGet, exec, tcpSocket)
- [ ] Debugged probe failures
- [ ] Understood pod phase transitions
- [ ] Ready to move to Jobs & CronJobs

---

## 🎓 Next Steps

Once complete, move to `cronjobs/exercise.md` to learn about workload management.

## Reference Templates

Check deployment template with probe examples in `/templates/deployment-template.yaml`.
