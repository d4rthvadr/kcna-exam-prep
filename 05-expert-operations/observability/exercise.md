# Observability Exercises

## Module Overview

This exercise set covers Kubernetes observability—the mechanisms for monitoring cluster health, collecting metrics, aggregating logs, and implementing alerting. You'll work with metrics collection (Prometheus), metric queries, pod and container logging, resource utilization monitoring, and health check interpretation. Observability is critical for production-grade Kubernetes deployments and directly supports KCNA exam domain: Cloud Native Observability (8%).

---

## Exercise 1.1: Inspect Metrics with kubectl top

**Problem Statement:**
Your cluster is experiencing performance issues and you need to quickly check resource utilization across nodes and pods. Use `kubectl top` commands to retrieve CPU and memory metrics for nodes and pods to identify resource-hungry components.

**Learning Objectives:**

- Use `kubectl top nodes` to view cluster-wide resource utilization
- Use `kubectl top pods` to identify resource-consuming pods
- Understand metrics-server as the metrics collection backend
- Interpret CPU and memory measurements (m = millicores, Mi = mebibytes)

**Instructions:**

1. Verify metrics-server is running (required for kubectl top):

```bash
kubectl get deployment metrics-server -n kube-system
# Should show metrics-server deployment running

# If not running, install it
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

2. Check node resource utilization:

```bash
kubectl top nodes
# Output shows CPU% and MEMORY% for each node
```

3. Check pod resource utilization in default namespace:

```bash
kubectl top pods
# Shows CPU and MEMORY for each pod
```

4. Check pod utilization across all namespaces:

```bash
kubectl top pods --all-namespaces
# Shows pods from all namespaces with metrics
```

5. Check utilization for specific namespace:

```bash
kubectl top pods -n kube-system
# Shows only pods in kube-system namespace
```

6. Get detailed metrics with labels:

```bash
kubectl top pods -n kube-system --show-labels
# Shows pod names, metrics, and their labels
```

**Verification Steps:**

```bash
# Verify metrics-server is ready
kubectl get deployment metrics-server -n kube-system -o jsonpath='{.status.conditions[?(@.type=="Available")].status}'
# Should return: True

# Check node metrics exist
kubectl top nodes
# Should show table with CPU%, MEMORY%

# Check pod metrics exist
kubectl top pods --all-namespaces | head -5
# Should show pod metrics

# Verify metrics format
kubectl top pods | awk '{print $3}' | head -3
# Should show CPU values in format like "1m", "5m", etc.
```

**Expected Outcomes:**

- metrics-server is deployed and running
- `kubectl top nodes` shows CPU and memory utilization for all nodes
- `kubectl top pods` shows resource usage for all pods
- Metrics are displayed in standard Kubernetes units (m for millicores, Mi for mebibytes)
- Can filter by namespace with `-n <namespace>` flag

**Key Learning Concepts:**

- **metrics-server**: Kubelet agent that collects resource metrics from nodes
- **CPU Units**: m = millicores (1000 = 1 core); 500m = half a core
- **Memory Units**: Mi = mebibytes; 1 Gi = 1024 Mi
- **Actual Usage**: `kubectl top` shows actual current usage, not requested/limited amounts
- **Time Averaging**: Metrics are typically averaged over the last minute
- **Missing Metrics**: If no metrics appear, metrics-server may need time to collect data (1-2 minutes)

---

## Exercise 1.2: Access Pod Logs and Debug Application Issues

**Problem Statement:**
An application pod is experiencing errors and you need to retrieve its logs for debugging. Access pod logs using kubectl log commands, handle multi-container pod scenarios, and understand log streaming vs. historical logs.

**Learning Objectives:**

- Retrieve pod logs with `kubectl logs`
- Handle multi-container pods
- Stream logs in real-time with `-f` flag
- View logs from previous pod instances (crashed containers)
- Use log filtering and formatting

**Instructions:**

1. Create a test pod with application logs:

```bash
kubectl run logging-demo --image=nginx --labels app=web
```

2. Get pod logs (all output since container started):

```bash
kubectl logs logging-demo
# Shows all logs from the pod
```

3. Stream logs in real-time (follow mode):

```bash
kubectl logs logging-demo -f
# Continuously displays new log lines
# Press Ctrl+C to exit
```

4. Get last N lines of logs:

```bash
kubectl logs logging-demo --tail=10
# Shows last 10 lines only
```

5. Get logs from last 5 minutes:

```bash
kubectl logs logging-demo --since=5m
# Shows logs from last 5 minutes
```

6. Get logs with timestamps:

```bash
kubectl logs logging-demo --timestamps=true
# Each log line includes timestamp
```

7. Create a pod with multiple containers:

```bash
kubectl run multi-container --image=nginx --labels app=multi -- sleep 3600
# Add a sidecar container by editing
kubectl edit pod multi-container
```

Or use a manifest:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-logs
spec:
  containers:
    - name: main
      image: nginx
    - name: sidecar
      image: busybox
      command: ["sh", "-c", 'echo "Sidecar started"; sleep 3600']
```

8. Get logs from specific container in multi-container pod:

```bash
kubectl logs multi-container-logs -c main
# Gets logs only from 'main' container

kubectl logs multi-container-logs -c sidecar
# Gets logs only from 'sidecar' container
```

9. Get logs from previous pod instance (if pod restarted):

```bash
# Create a pod that crashes
kubectl run crash-loop --image=busybox -- false

# Wait a moment for restart
sleep 5

# Get logs from previous instance
kubectl logs crash-loop --previous
# Shows logs before the crash
```

**Verification Steps:**

```bash
# Confirm pod exists and has logs
kubectl get pod logging-demo
kubectl logs logging-demo | head -5

# Verify multi-container logs can be retrieved separately
kubectl logs multi-container-logs -c main
kubectl logs multi-container-logs -c sidecar

# Verify previous logs work
kubectl logs crash-loop --previous
# Should show output from before the crash
```

**Expected Outcomes:**

- `kubectl logs` retrieves pod output successfully
- Logs include timestamps when `--timestamps=true` is used
- Real-time streaming works with `-f` flag
- Multi-container pods require `-c` flag to specify container
- `--previous` flag retrieves logs from crashed/restarted containers
- Filters like `--tail` and `--since` work correctly

**Key Learning Concepts:**

- **stdout/stderr**: `kubectl logs` shows all output to stdout by default
- **Container Logs**: Stored at `/var/log/pods/*` on nodes
- **Log Retention**: Old logs are rotated; `--previous` only works for most recent restart
- **Multi-Container Pods**: Must specify container name with `-c` flag
- **Timestamps**: Log timestamps are application-dependent; Kubernetes adds wrapper timestamps with `--timestamps=true`
- **Log Streaming**: `-f` follows logs from running container (useful for debugging)

---

## Exercise 1.3: Monitor Pod and Container Resource Requests and Limits

**Problem Statement:**
Your team needs to establish resource requests and limits for pods to ensure fair resource allocation and prevent pods from overwhelming node resources. Create pods with resource requests/limits, verify they are enforced, and understand the relationship between requests and actual usage.

**Learning Objectives:**

- Define resource requests for guaranteed minimum resources
- Define resource limits for maximum resource caps
- Understand QoS (Quality of Service) classes: Guaranteed, Burstable, BestEffort
- Monitor actual resource usage vs. requests/limits
- Understand admission control's role in resource enforcement

**Instructions:**

1. Create a pod with resource requests and limits:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-constrained
spec:
  containers:
    - name: app
      image: nginx
      resources:
        requests:
          cpu: 100m # Guaranteed 100 millicores
          memory: 128Mi # Guaranteed 128 mebibytes
        limits:
          cpu: 500m # Maximum 500 millicores
          memory: 512Mi # Maximum 512 mebibytes
```

Apply:

```bash
kubectl apply -f pod-resource-constrained.yaml
```

2. Verify the pod was created and check resource requests:

```bash
kubectl describe pod resource-constrained
# Look for "Requests:" and "Limits:" sections

# Get pod YAML to review resources
kubectl get pod resource-constrained -o yaml | grep -A 8 "resources:"
```

3. Create a pod with only requests (Burstable QoS):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: burstable-pod
spec:
  containers:
    - name: app
      image: nginx
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
```

Apply:

```bash
kubectl apply -f pod-burstable.yaml
```

4. Create a pod with no requests or limits (BestEffort QoS):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: besteffort-pod
spec:
  containers:
    - name: app
      image: nginx
```

Apply:

```bash
kubectl apply -f pod-besteffort.yaml
```

5. Check QoS class for each pod:

```bash
# Get all pod QoS classes
kubectl get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
# Should show: Guaranteed, Burstable, BestEffort
```

6. Compare actual usage vs. requests/limits:

```bash
# Actual usage
kubectl top pods

# Requested/Limit resources
kubectl describe pod resource-constrained | grep -A 4 "Requests:\|Limits:"
kubectl describe pod burstable-pod | grep -A 4 "Requests:\|Limits:"
kubectl describe pod besteffort-pod | grep -A 4 "Requests:\|Limits:"
```

**Verification Steps:**

```bash
# Verify requests and limits are set
kubectl get pod resource-constrained -o yaml | grep -A 4 "resources:"
# Should show: requests (cpu: 100m, memory: 128Mi), limits (cpu: 500m, memory: 512Mi)

# Verify QoS classes
kubectl get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
# resource-constrained: Guaranteed
# burstable-pod: Burstable
# besteffort-pod: BestEffort

# Verify actual usage is within limits
kubectl top pods
# All actual usage should be <= limits (if limits exist)
```

**Expected Outcomes:**

- Pod with matching requests and limits: QoS = Guaranteed
- Pod with requests but no limits: QoS = Burstable
- Pod with no requests or limits: QoS = BestEffort
- Actual usage is visible and can be compared to requests/limits
- Pods are scheduled only on nodes with enough free resources to satisfy requests

**Key Learning Concepts:**

- **Requests**: CPU/memory guaranteed to pod; used for scheduling decisions
- **Limits**: Maximum CPU/memory pod can use; enforced by kubelet (OOMKilled if exceeded)
- **QoS Classes**:
  - **Guaranteed**: request == limit (highest priority, last to be evicted)
  - **Burstable**: request < limit (medium priority)
  - **BestEffort**: no request/limit (lowest priority, first to be evicted)
- **Scheduler Behavior**: Schedules pods only on nodes with available requested resources
- **Overcommitment**: Can request less than actual usage (but still limits enforcement)
- **Node Pressure**: When node runs low on resources, pods with lower QoS are evicted first

---

## Exercise 1.4: Use Health Checks - Liveness and Readiness Probes

**Problem Statement:**
Your application pods need health checks to ensure only healthy pods receive traffic and to trigger automatic restarts of unhealthy containers. Configure liveness and readiness probes to match your application's health requirements and understand probe failure consequences.

**Learning Objectives:**

- Implement readiness probes to control traffic routing
- Implement liveness probes to enable self-healing
- Understand probe types: httpGet, exec, tcpSocket
- Interpret probe configuration (initialDelaySeconds, periodSeconds, failureThreshold)
- Debug probe failures

**Instructions:**

1. Create a pod with HTTP readiness and liveness probes:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: health-check-demo
spec:
  containers:
    - name: app
      image: nginx
      ports:
        - containerPort: 80
      readinessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 10
        failureThreshold: 3
      livenessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 15
        periodSeconds: 20
        failureThreshold: 3
```

Apply:

```bash
kubectl apply -f pod-health-checks.yaml
```

2. Check probe status:

```bash
kubectl describe pod health-check-demo
# Look for "Readiness:" and "Liveness:" probe status
# Should show "Passed" or similar

# Watch probe changes in real-time
kubectl describe pod health-check-demo --watch
```

3. Create a pod with exec-based probes:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: exec-probe-demo
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "echo ok > /tmp/healthy; sleep 3600"]
      readinessProbe:
        exec:
          command:
            - cat
            - /tmp/healthy
        initialDelaySeconds: 5
        periodSeconds: 5
      livenessProbe:
        exec:
          command:
            - cat
            - /tmp/healthy
        initialDelaySeconds: 15
        periodSeconds: 10
```

Apply:

```bash
kubectl apply -f pod-exec-probes.yaml
```

4. Create a pod with TCP socket probe:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tcp-probe-demo
spec:
  containers:
    - name: app
      image: nginx
      ports:
        - containerPort: 80
      readinessProbe:
        tcpSocket:
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 10
      livenessProbe:
        tcpSocket:
          port: 80
        initialDelaySeconds: 10
        periodSeconds: 15
```

Apply:

```bash
kubectl apply -f pod-tcp-probes.yaml
```

5. Simulate probe failure to see restart behavior:

```bash
# Exec into pod and remove the health file
kubectl exec -it exec-probe-demo -- rm /tmp/healthy

# Watch the pod restart
kubectl get pod exec-probe-demo --watch
# Pod should restart after failureThreshold probes fail

# Check restart count
kubectl describe pod exec-probe-demo | grep "Restart Count"
```

6. Check probe history in events:

```bash
kubectl describe pod health-check-demo | tail -20
# Look for probe failure events
```

**Verification Steps:**

```bash
# Verify probes are configured
kubectl get pod health-check-demo -o yaml | grep -A 10 "readinessProbe:\|livenessProbe:"

# Verify probes are passing
kubectl describe pod health-check-demo | grep -E "Readiness|Liveness"
# Should show status passing/successful

# Verify restart count (should increase after probe failure)
kubectl describe pod exec-probe-demo | grep "Restart Count"

# Verify pod recovered after restart
kubectl get pod exec-probe-demo
# Should show Ready status after restart
```

**Expected Outcomes:**

- All probes configured correctly in pod spec
- HTTP, exec, and TCP socket probe types can be verified
- Readiness probe controls whether pod receives traffic
- Liveness probe triggers pod restart on failure
- Probe failures appear in pod events and logs
- Restart count increments when liveness probe fails

**Key Learning Concepts:**

- **Readiness Probe**: Determines if pod is ready to receive traffic; failed = no traffic sent
- **Liveness Probe**: Determines if pod should restart; failed = replica set replaces it
- **Probe Types**:
  - **httpGet**: Make HTTP request; success if 200-399 status
  - **exec**: Run command; success if exit code 0
  - **tcpSocket**: Connect to port; success if port opens
- **Probe Timing**:
  - **initialDelaySeconds**: Wait before first probe (app startup time)
  - **periodSeconds**: Interval between probes
  - **failureThreshold**: Consecutive failures before considered failed
  - **timeoutSeconds**: Max time for probe to complete
- **Common Issues**: initialDelaySeconds too short (app not ready), probes too aggressive (excessive restarts)

---

## Exercise 1.5: Monitor Deployment Health and Pod Status

**Problem Statement:**
A deployment update is rolling out and you need to monitor the rollout progress, understand pod status conditions, and know when to consider the rollout successful. Use kubectl commands to monitor deployment status, check pod conditions, and understand replica readiness.

**Learning Objectives:**

- Monitor deployment rollout progress
- Understand pod status conditions (Ready, PodScheduled, Initialized, ContainersReady)
- Use `kubectl rollout status` to track deployment changes
- Interpret deployment replica counts (desired, current, updated, available, ready)
- Understand deployment conditions and their meanings

**Instructions:**

1. Create a deployment with resource constraints:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rollout-monitor
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
      spec:
        containers:
          - name: app
            image: nginx:1.19
            readinessProbe:
              httpGet:
                path: /
                port: 80
              initialDelaySeconds: 5
              periodSeconds: 5
              failureThreshold: 2
```

Apply:

```bash
kubectl apply -f deployment-rollout-monitor.yaml
```

2. Check deployment status:

```bash
# Show deployment summary
kubectl get deployment rollout-monitor
# Fields: READY 3/3, UP-TO-DATE 3, AVAILABLE 3, AGE

# Show detailed status
kubectl describe deployment rollout-monitor
# Look for "Replicas:" and "Conditions:" sections
```

3. Monitor rollout progress using watch:

```bash
# Watch deployment changes
kubectl get deployment rollout-monitor --watch
```

4. Trigger a rollout by updating the image:

```bash
kubectl set image deployment/rollout-monitor app=nginx:latest
# This triggers a rolling update
```

5. Monitor the rollout in real-time:

```bash
# Show rollout progress
kubectl rollout status deployment/rollout-monitor
# Continuously shows progress

# Get rollout history
kubectl rollout history deployment/rollout-monitor
# Shows all revisions of the deployment
```

6. Check pod status conditions during rollout:

```bash
# Get detailed pod status
kubectl get pods -o wide
# Shows pod IP, Status, Ready status

# Get status conditions for specific pod
kubectl get pod <pod-name> -o jsonpath='{.status.conditions[*]}'
# Shows all conditions with status True/False

# More readable format
kubectl describe pod <pod-name> | grep -A 10 "Conditions:"
```

7. Check deployment conditions:

```bash
# Get deployment conditions
kubectl describe deployment rollout-monitor | grep -A 20 "Conditions:"
# Shows Progressing, Available conditions
```

**Verification Steps:**

```bash
# Verify deployment exists
kubectl get deployment rollout-monitor

# Verify replicas are ready
kubectl get deployment rollout-monitor -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'
# Should show: 3/3

# Verify all pods are ready
kubectl get pods -l app=web -o custom-columns=NAME:.metadata.name,READY:.status.conditions[?(@.type=="Ready")].status
# All should show: True

# Check rollout history
kubectl rollout history deployment/rollout-monitor
# Should show multiple revisions if update occurred
```

**Expected Outcomes:**

- Deployment rolls out successfully with readiness probes
- `kubectl rollout status` shows progress of rolling update
- Pod status conditions show Ready=True for all pods
- Deployment conditions show Progressing=True (during update) then Available=True
- Replica counts match: desired, current, updated, available, ready
- Rollout history tracks multiple revisions

**Key Learning Concepts:**

- **Replica Counts**:
  - **Desired**: Number of replicas specified in spec.replicas
  - **Current**: Number of pods created (may be > desired during rolling update)
  - **Updated**: Number of pods with new template (during rollout)
  - **Available**: Number of pods ready to serve traffic
  - **Ready**: Number of pods passing readiness probes
- **Pod Status Conditions**:
  - **PodScheduled**: Pod assigned to node
  - **Initialized**: Init containers completed
  - **ContainersReady**: All containers ready (liveness/readiness probes passing)
  - **Ready**: Pod can receive traffic
- **Deployment Conditions**:
  - **Progressing**: Rollout in progress or complete
  - **Available**: All replicas available and ready
  - **ReplicaFailure**: Issues creating new replicas
- **Rollout Timing**: Readiness probe initialDelaySeconds affects rollout speed

---

## Exercise 1.6: Implement and Test Alerts Using Deployment Metrics

**Problem Statement:**
You need to understand what metrics are available for alerting on deployment health. Explore common alerting patterns based on metrics like pod restart count, failed pods, image pull errors, and pod evictions. Set up monitoring scenarios to demonstrate alert-worthy conditions.

**Learning Objectives:**

- Understand metrics suitable for alerting (restarts, failures, resource exhaustion)
- Identify unhealthy pod conditions
- Monitor deployment-level metrics
- Understand eviction and restart policies
- Document alert-worthy thresholds

**Instructions:**

1. Create a pod that will generate restart events:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restart-monitor
spec:
  containers:
    - name: unstable
      image: busybox
      command: ["sh", "-c", "sleep 10; exit 1"] # Fail after 10 seconds
  restartPolicy: Always
```

Apply:

```bash
kubectl apply -f pod-restart-monitor.yaml

# Watch it restart repeatedly
kubectl get pod restart-monitor --watch
```

2. Check restart count (alert metric):

```bash
# Get restart count
kubectl describe pod restart-monitor | grep "Restart Count"

# Continue watching as restarts increase
for i in {1..10}; do kubectl get pod restart-monitor -o jsonpath='{.status.containerStatuses[0].restartCount}'; echo; sleep 5; done
```

3. Create a deployment with failing readiness probe for alert demo:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: failing-readiness
spec:
  replicas: 3
  selector:
    matchLabels:
      app: failing
  template:
    metadata:
      labels:
        app: failing
    spec:
      containers:
        - name: app
          image: nginx
          readinessProbe:
            httpGet:
              path: /nonexistent # Intentionally fail
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 2
```

Apply:

```bash
kubectl apply -f deployment-failing-readiness.yaml
```

4. Monitor pod readiness status (alert metric):

```bash
# Get pods not ready
kubectl get pods -l app=failing -o wide
# READY column should show 0/1 for all pods

# Monitor condition
kubectl get pods -l app=failing -o custom-columns=NAME:.metadata.name,READY:.status.conditions[?(@.type=="Ready")].status
# All should show: False
```

5. Simulate resource pressure and observe pod evictions:

```bash
# Create a deployment that uses lots of memory
kubectl run memory-hog --image=progrium/stress -- stress --vm 1 --vm-bytes 512M
# This may cause other pods to be evicted depending on cluster size
```

6. Check for pod eviction reasons:

```bash
# Get evicted pods
kubectl get pods --field-selector=status.reason=Evicted

# Get eviction details
kubectl describe pod <evicted-pod-name>
# Look for "Reason: Evicted"
```

7. Document alert metrics to monitor:
   Create a monitoring checklist document:

```
Alert Metrics for Deployment Health:
- Restart Count: Alert if > 5 in 1 hour
- Pod Ready Status: Alert if < desired replicas for > 5 minutes
- Pod Phase: Alert if any pods in Failed or Unknown phase
- Image Pull Errors: Alert on ImagePullBackOff status
- Evictions: Alert on pod evictions (OOMKilled, Evicted reason)
- Liveness Probe Failures: Alert if repeated failures
- Node Pressure: Alert if node in DiskPressure or MemoryPressure state
```

**Verification Steps:**

```bash
# Verify restart count is increasing
kubectl describe pod restart-monitor | grep "Restart Count"
# Should show increasing number

# Verify failing readiness pods
kubectl get deployment failing-readiness -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'
# Should show: 0/3

# Verify pod phase
kubectl get pods restart-monitor failing-readiness-* -o wide | grep STATUS

# Check for evicted pods
kubectl get pods --field-selector=status.reason=Evicted | wc -l
```

**Expected Outcomes:**

- restart-monitor pod continuously restarts (alert condition)
- failing-readiness pods never become ready (alert condition)
- Restart count and pod ready status are key alert metrics
- Pod phase, image pull status, and eviction reasons are visible
- Clear understanding of alert thresholds and conditions

**Key Learning Concepts:**

- **Restart Count**: Indicates crashing containers; alert if high (>5-10 in hour)
- **Ready Status**: Shows pods available for traffic; alert if < desired replicas
- **Pod Phase**:
  - **Pending**: Scheduling in progress
  - **Running**: Container running
  - **Succeeded**: Container exited 0
  - **Failed**: Container exited non-zero
  - **Unknown**: State unknown
- **Common Alert Conditions**:
  - ImagePullBackOff: Image registry unreachable
  - CrashLoopBackOff: Container repeatedly crashing
  - OOMKilled: Memory limit exceeded
  - Evicted: Node ran out of resources
- **Alert Thresholds**: Depend on application; e.g., 1 restart OK, 5+ in hour = alert

---

## Exercise 1.7: Cleanup

**Problem Statement:**
Remove all monitoring and observability resources created in this exercise set to clean up the cluster.

**Instructions:**

Remove all pods and deployments:

```bash
kubectl delete pod logging-demo crash-loop multi-container-logs
kubectl delete pod resource-constrained burstable-pod besteffort-pod
kubectl delete pod health-check-demo exec-probe-demo tcp-probe-demo
kubectl delete deployment rollout-monitor failing-readiness
kubectl delete pod restart-monitor memory-hog
```

**Verification Steps:**

```bash
# Verify resources are removed
kubectl get pods
# Should show no custom pods

kubectl get deployments
# Should show no custom deployments
```

**Expected Outcomes:**

- All custom pods removed
- All custom deployments removed
- Cluster returned to clean state

---

## Module Completion Checklist

- [ ] Completed Exercise 1.1: Inspect metrics with kubectl top
- [ ] Completed Exercise 1.2: Access pod logs and debug issues
- [ ] Completed Exercise 1.3: Monitor resource requests and limits
- [ ] Completed Exercise 1.4: Use health checks (liveness/readiness)
- [ ] Completed Exercise 1.5: Monitor deployment health
- [ ] Completed Exercise 1.6: Implement alert metrics
- [ ] Completed Exercise 1.7: Cleanup

## Key Takeaways

1. **Metrics Collection**: metrics-server collects CPU/memory; `kubectl top` retrieves them
2. **Log Access**: `kubectl logs` with `-f` (follow), `-c` (container), `--previous` (crashed)
3. **Resource Management**: Requests (scheduling) vs. Limits (enforcement); QoS classes
4. **Health Checks**: Readiness (traffic), Liveness (restart); exec, httpGet, tcpSocket types
5. **Deployment Status**: Monitor replicas (desired, current, updated, available, ready)
6. **Alert Metrics**: Restart count, pod ready status, phase, evictions, image pull errors
7. **Troubleshooting**: Use `kubectl describe`, `kubectl logs`, `kubectl top` to diagnose issues

## Useful Commands Reference

```bash
# Metrics
kubectl top nodes
kubectl top pods
kubectl top pods -n <namespace> --sort-by=memory

# Logs
kubectl logs <pod>
kubectl logs <pod> -c <container>
kubectl logs <pod> --previous
kubectl logs <pod> -f
kubectl logs <pod> --tail=50
kubectl logs <pod> --since=5m

# Resource status
kubectl describe pod <pod>
kubectl get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
kubectl get pods -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")]}'

# Deployment monitoring
kubectl describe deployment <deployment>
kubectl rollout status deployment/<deployment>
kubectl rollout history deployment/<deployment>

# Debugging
kubectl get events --sort-by='.lastTimestamp'
kubectl get pods --field-selector=status.phase=Failed
kubectl get pods --field-selector=status.reason=Evicted
```

---

**Next Steps:** Proceed to Deployment Strategies exercises to complete Module 05 on operations and observability.
