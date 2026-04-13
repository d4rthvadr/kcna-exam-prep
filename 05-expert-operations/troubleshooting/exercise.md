# Troubleshooting and Diagnostics Exercises

## Module Overview

This exercise set covers Kubernetes operational troubleshooting and diagnostics—the skills for identifying and resolving common cluster issues. You'll diagnose pod failures, connectivity problems, resource constraints, configuration errors, and node issues using kubectl commands, logs, events, and cluster inspection. These practical skills are essential for managing production clusters and supporting the KCNA exam's operational domains.

---

## Exercise 3.1: Diagnose and Fix Pod Startup Failures

**Problem Statement:**
Several pods in your application are stuck in Pending or CrashLoopBackOff state and are not starting successfully. Use kubectl diagnosis commands to identify the root causes: scheduling issues, image pull errors, missing resources, or container startup failures.

**Learning Objectives:**

- Diagnose pod status conditions and reasons
- Identify image pull errors vs. container crashes
- Understand Init container failures
- Diagnose resource constraints and node capacity issues
- Use events to understand failure sequences

**Instructions:**

1. Create a pod that will fail due to image pull error:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: image-pull-error
spec:
  containers:
    - name: app
      image: nonexistent-registry.example.com/app:1.0
      imagePullPolicy: Always # Force pull from registry
```

Apply:

```bash
kubectl apply -f pod-image-pull-error.yaml
```

2. Create a pod that crashes due to missing startup requirements:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: crash-loop
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "exit 1"] # Immediately exits with error
  restartPolicy: Always
```

Apply:

```bash
kubectl apply -f pod-crash-loop.yaml
```

3. Create a pod with unschedulable condition (too large for nodes):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: unschedulable
spec:
  containers:
    - name: app
      image: nginx
      resources:
        requests:
          cpu: 999
          memory: 999Gi # Impossible to schedule
```

Apply:

```bash
kubectl apply -f pod-unschedulable.yaml
```

4. Create a pod with init container that fails:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-failure
spec:
  initContainers:
    - name: init
      image: busybox
      command: ["sh", "-c", "exit 1"] # Init fails
  containers:
    - name: app
      image: nginx
  restartPolicy: Always
```

Apply:

```bash
kubectl apply -f pod-init-failure.yaml
```

5. Diagnose each pod to understand the failure:

**Diagnose Image Pull Error:**

```bash
# Check pod status
kubectl get pod image-pull-error
# STATUS: ImagePullBackOff

# Get detailed description
kubectl describe pod image-pull-error
# Look for "Unable to pull image" in events

# Check specific events
kubectl get events --field-selector involvedObject.name=image-pull-error
```

**Diagnose Crash Loop:**

```bash
# Check pod status
kubectl get pod crash-loop
# STATUS: CrashLoopBackOff, RESTARTS: high number

# Get container exit reason
kubectl describe pod crash-loop
# Look for "Exit Code" in Last State

# Check logs from previous restart
kubectl logs crash-loop --previous
# Should show exit was immediate
```

**Diagnose Unschedulable:**

```bash
# Check pod status
kubectl get pod unschedulable
# STATUS: Pending (not ImagePullBackOff or CrashLoopBackOff)

# Get detailed reason
kubectl describe pod unschedulable
# Look for "Pending" event with reason "Unschedulable"

# Check node capacity
kubectl describe nodes | grep -A 5 "Allocated resources"
# Shows remaining available resources
```

**Diagnose Init Container Failure:**

```bash
# Check pod status
kubectl get pod init-failure
# STATUS: Init:CrashLoopBackOff (different from app crash)

# Get init container logs
kubectl logs init-failure -c init --previous
# Shows init's exit status

# Note: Main container cannot start until init succeeds
```

**Verification Steps:**

```bash
# All problematic pods should be visible
kubectl get pods image-pull-error crash-loop unschedulable init-failure

# Image pull error should show ImagePullBackOff
kubectl get pod image-pull-error -o jsonpath='{.status.phase}'
# Output: Pending

# Crash loop should show CrashLoopBackOff
kubectl get pod crash-loop -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}'
# Output: CrashLoopBackOff

# Unschedulable should show Pending
kubectl get pod unschedulable -o jsonpath='{.status.conditions[?(@.type=="PodScheduled")]}'
# Should show: False with reason Unschedulable

# Init failure should show Init status
kubectl get pod init-failure -o jsonpath='{.status.initContainerStatuses[0].state}'
# Should show waiting.reason: CrashLoopBackOff
```

**Expected Outcomes:**

- Each pod exhibits different failure symptoms
- Image pull error: ImagePullBackOff status, registry connectivity errors in events
- Crash loop: CrashLoopBackOff, high restart count, container exit code errors
- Unschedulable: Pending status, insufficient resources event
- Init failure: Init:CrashLoopBackOff, init container failure in logs

**Key Learning Concepts:**

- **Pod Status Phases**:
  - **Pending**: Pod not yet scheduled (waiting for resources or image pull)
  - **Running**: Container is running
  - **Succeeded**: Container exited 0
  - **Failed**: Container exited non-zero
  - **Unknown**: State unknown
- **Waiting Reasons**:
  - **ImagePullBackOff**: Registry unreachable or image doesn't exist
  - **CrashLoopBackOff**: Container keeps crashing
  - **CreateContainerConfigError**: Config/secrets missing
  - **ContainerCreating**: Normal startup (give it time)
  - **Unschedulable**: Not enough resources or node constraints
- **Init Container Status**: Shows separately from app containers; must succeed first
- **Events**: Chronological record of pod state changes; critical for diagnosis

---

## Exercise 3.2: Diagnose Networking and Connectivity Issues

**Problem Statement:**
Applications deployed in your cluster are unable to communicate with each other or external services. Diagnose DNS resolution issues, service routing problems, and NetworkPolicy-related connectivity failures using various kubectl and manual testing approaches.

**Learning Objectives:**

- Diagnose DNS resolution within cluster
- Test service connectivity and endpoint resolution
- Use port-forward for testing isolated services
- Understand service discovery mechanisms
- Diagnose NetworkPolicy-related blocks

**Instructions:**

1. Create test pods and services:

```bash
# Create namespaces
kubectl create namespace test-connectivity

# Create a backend service
kubectl run backend --image=nginx --labels app=backend -n test-connectivity
kubectl expose pod backend --port=80 --name=backend-service -n test-connectivity

# Create a client pod to test connectivity
kubectl run client --image=nicolaka/netcat --labels app=client -n test-connectivity -- sleep 3600
```

2. Diagnose DNS resolution:

**Test DNS from within pod:**

```bash
# Test forward DNS (name -> IP)
kubectl exec -it client -n test-connectivity -- nslookup backend-service
# Should resolve to service IP

# Test reverse DNS (IP -> name)
SERVICE_IP=$(kubectl get svc backend-service -n test-connectivity -o jsonpath='{.spec.clusterIP}')
kubectl exec -it client -n test-connectivity -- nslookup $SERVICE_IP
# May or may not resolve (reverse DNS not always configured)

# Test DNS with FQDN
kubectl exec -it client -n test-connectivity -- nslookup backend-service.test-connectivity.svc.cluster.local
# Should resolve to service IP
```

**Check DNS service inside cluster:**

```bash
# Verify kube-dns or CoreDNS is running
kubectl get pods -n kube-system -l k8s-app=kube-dns
# or
kubectl get pods -n kube-system -l k8s-app=coredns

# Check CoreDNS logs for resolution errors
POD=$(kubectl get pod -n kube-system -l k8s-app=coredns -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD -n kube-system | grep -i error | tail -10
```

3. Diagnose service routing:

**Test service connectivity:**

```bash
# Test if service is accessible
BACKEND_IP=$(kubectl get svc backend-service -n test-connectivity -o jsonpath='{.spec.clusterIP}')
kubectl exec client -n test-connectivity -- nc -zv $BACKEND_IP 80
# Should succeed if service exists and endpoints are ready

# Check service endpoints
kubectl get endpoints backend-service -n test-connectivity
# Should show pod IPs and port

# Check service DNS name is resolvable
kubectl exec client -n test-connectivity -- nslookup backend-service.test-connectivity
# Should resolve to service IP
```

**Test pod-to-pod connectivity directly:**

```bash
# If service fails, test pod directly
POD_IP=$(kubectl get pod backend -n test-connectivity -o jsonpath='{.status.podIP}')
kubectl exec client -n test-connectivity -- nc -zv $POD_IP 80
# Tests if pod is accessible (bypasses service)
```

4. Diagnose NetworkPolicy blocks (if applicable):

**Check NetworkPolicies in namespace:**

```bash
# List NetworkPolicies
kubectl get networkpolicy -n test-connectivity
# Should be empty (no policies means allow all)

# Create a blocking policy
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: test-connectivity
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF

# Test connectivity (should now fail)
kubectl exec client -n test-connectivity -- nc -zv $BACKEND_IP 80
# Should timeout (traffic blocked)

# Describe policy to understand rules
kubectl describe networkpolicy deny-all-ingress -n test-connectivity
```

**Fix by allowing necessary traffic:**

```bash
# Allow traffic from client to backend
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-client-to-backend
  namespace: test-connectivity
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: client
    ports:
    - protocol: TCP
      port: 80
EOF

# Test connectivity again (should pass now)
kubectl exec client -n test-connectivity -- nc -zv $BACKEND_IP 80
# Should succeed
```

5. Use port-forward for isolated testing:

```bash
# Port-forward to test service without DNS/network complexity
kubectl port-forward svc/backend-service 8080:80 -n test-connectivity &
# (runs in background)

# Test localhost:8080 directly (requires curl/wget in your shell)
# Or test from another pod that has port access to your node

# Kill port-forward
jobs  # Find job number
kill %1  # Kill background job
```

**Verification Steps:**

```bash
# Verify DNS resolution works
kubectl exec client -n test-connectivity -- nslookup backend-service.test-connectivity
# Should show: Address: <service-IP>

# Verify service has endpoints
kubectl get endpoints backend-service -n test-connectivity
# Should list pod IP and port 80

# Verify direct pod connectivity
POD_IP=$(kubectl get pod backend -n test-connectivity -o jsonpath='{.status.podIP}')
kubectl exec client -n test-connectivity -- nc -zv $POD_IP 80
# Should be successful

# Verify service connectivity
SERVICE_IP=$(kubectl get svc backend-service -n test-connectivity -o jsonpath='{.spec.clusterIP}')
kubectl exec client -n test-connectivity -- nc -zv $SERVICE_IP 80
# Should be successful (if no NetworkPolicy blocks)
```

**Expected Outcomes:**

- DNS resolution of service names works within cluster
- Service IPs are routable
- Pod IPs are directly reachable
- NetworkPolicy-based connectivity issues are identifiable and fixable
- Port-forward provides alternative access method for testing

**Key Learning Concepts:**

- **Service Discovery**: Kubernetes DNS resolves service names automatically
- **FQDN Format**: `<service>.<namespace>.svc.cluster.local` is fully qualified name
- **Endpoints**: Service routes traffic using iptables rules matching pod IPs
- **Troubleshooting Order**:
  1. Check DNS resolution (nslookup)
  2. Verify service exists and has endpoints (kubectl get svc, endpoints)
  3. Test direct pod connectivity (pod IP)
  4. Test service connectivity (service IP)
  5. Check NetworkPolicy if traffic blocked
  6. Check kube-proxy logs if routing fails
- **Tools**: nslookup (DNS), nc (connectivity), port-forward (isolated testing)

---

## Exercise 3.3: Investigate Resource Pressure and Node Issues

**Problem Statement:**
Your cluster is experiencing performance degradation and pods are being evicted. Investigate node resource pressure (CPU, memory, disk), check kubelet status, review node conditions, and understand pod eviction policies.

**Learning Objectives:**

- Check node resource pressure conditions
- Understand eviction thresholds and evictions
- Monitor node disk pressure and inode pressure
- Check kubelet status and logs
- Understand QoS-based eviction priority

**Instructions:**

1. Check node conditions:

```bash
# Get detailed node status
kubectl describe nodes
# Look for "Conditions:" section

# Show specific conditions
kubectl get nodes -o custom-columns=NAME:.metadata.name,MEMORY-PRESSURE:.status.conditions[?(@.type=="MemoryPressure")].status,DISK-PRESSURE:.status.conditions[?(@.type=="DiskPressure")].status

# Check node allocatable resources
kubectl describe node <node-name> | grep -A 10 "Allocatable:"
# Shows maximum resources available on node
```

2. Check actual resource usage vs. requested:

```bash
# Get node resource requests
kubectl describe node <node-name> | grep -A 20 "Non-terminated Pods:"
# Shows pods running on node with their resource constraints

# Get actual usage
kubectl top nodes
# Shows actual CPU and memory usage

# Compare requested vs. actual
echo "=== Requested ==="
kubectl describe node <node-name> | grep -A 5 "cpu\|memory" | head -10
echo "=== Actual ==="
kubectl top nodes
```

3. Investigate evicted pods:

```bash
# Find evicted pods
kubectl get pods --all-namespaces --field-selector=status.reason=Evicted

# Check evicted pod details
kubectl describe pod <evicted-pod-name>
# Look for "Reason: Evicted" and eviction details

# Get eviction reason
kubectl get pod <evicted-pod-name> -o jsonpath='{.status.reason}'
# Should show: Evicted

# Get eviction message
kubectl get pod <evicted-pod-name> -o jsonpath='{.status.message}'
# Shows detailed eviction reason (e.g., "Pod evicted: node had condition: MemoryPressure")
```

4. Create scenario with memory pressure:

```bash
# Create a memory-hog deployment to simulate pressure
kubectl create namespace pressure-demo
kubectl run memory-hog --image=progrium/stress -n pressure-demo -- stress --vm 1 --vm-bytes 256M --vm-hang 3600

# Monitor memory usage
kubectl top pod -n pressure-demo --watch

# Create QoS test pods to see which get evicted
# BestEffort pod (highest priority to evict)
kubectl run be-pod --image=busybox -n pressure-demo -- sleep 3600

# Burstable pod (medium priority)
kubectl run bu-pod --image=busybox -n pressure-demo -c app --image=busybox -- sleep 3600 \
  --resource-limits cpu=100m,memory=100Mi

# Guaranteed pod (lowest priority to evict)
kubectl run gu-pod --image=busybox -n pressure-demo \
  --resource-requests cpu=100m,memory=100Mi \
  --resource-limits cpu=100m,memory=100Mi -- sleep 3600
```

5. Check kubelet logs for eviction events:

```bash
# SSH into node (if accessible) and check kubelet logs
# On managed clusters, use:
kubectl logs -n kube-system -l component=kubelet
# May not work on all clusters (depends on logging setup)

# Or check via nodeName in events
kubectl get events --all-namespaces | grep Evicted | tail -10

# Get detailed eviction events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | grep -i evict | tail -10
```

6. Check kube-reserved and system-reserved:

```bash
# Check kubelet configuration for resource reservation
# This typically requires SSH to node or viewing node status
kubectl describe node <node-name> | grep -A 5 "Reserved:"
# Shows resources reserved for kubelet and system

# Check available resources
kubectl describe node <node-name> | grep "Allocatable:" -A 10
# Resources available for pods
```

**Verification Steps:**

```bash
# Verify node conditions
kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[?(@.status=="True")].type

# Verify no pressure conditions (if healthy)
kubectl get nodes -o custom-columns=NAME:.metadata.name,MEMORY:.status.conditions[?(@.type=="MemoryPressure")].status,DISK:.status.conditions[?(@.type=="DiskPressure")].status
# Should show False or empty

# Verify evicted pods are listed
kubectl get pods --all-namespaces --field-selector=status.reason=Evicted | wc -l
# Should show 0 if resources are available

# Verify pod QoS classes
kubectl get pods -n pressure-demo -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
# Should show BestEffort, Burstable, Guaranteed
```

**Expected Outcomes:**

- Node conditions show resource pressure states (MemoryPressure: False/True)
- Evicted pods can be identified and their eviction reasons reviewed
- QoS classes correlate with eviction priority (BestEffort evicted first)
- Node resource allocation visible (requested, actual, available)
- Kubelet configuration affects eviction thresholds

**Key Learning Concepts:**

- **Node Conditions**:
  - **MemoryPressure**: Running low on available memory
  - **DiskPressure**: Running low on available disk space
  - **PIDPressure**: Running low on available process IDs
  - **Ready**: Node healthy and accepting pods
  - **NetworkUnavailable**: Network not configured
- **Eviction Process**: kubelet monitors resources; when threshold hit, evicts pods
- **Eviction Priority**: QoS-based → BestEffort (first) → Burstable (second) → Guaranteed (last)
- **Thresholds**: Default memory eviction at 100Mi, disk at 5%; configurable via kubelet flag
- **Pod Disruption**: Evicted pods freed immediately (no graceful termination in some cases)

---

## Exercise 3.4: Diagnose Configuration and API Errors

**Problem Statement:**
Your deployments are failing to apply due to API validation errors, deprecated fields, or misconfiguration. Use kubectl dry-run and kubectl explain to validate configurations before applying and understand what fields are available.

**Learning Objectives:**

- Use `kubectl apply --dry-run=client` for client-side validation
- Use `kubectl apply --dry-run=server` for server-side validation
- Use `kubectl explain` to understand resource schemas
- Diagnose API validation errors
- Understand deprecations and API versions

**Instructions:**

1. Create a manifest with errors:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: bad-config
  labels:
    app: web
spec:
  containers:
    - name: app
      image: nginx
      invalidField: value # This field doesn't exist
      resources:
        limits:
          cpu: invalid # Invalid CPU format
          memory: 512MB # Should be Mi not MB
```

2. Try to apply it (will fail):

```bash
# Try to apply
kubectl apply -f pod-bad-config.yaml
# Error: error validating data... unknown field...
```

3. Use dry-run for client-side validation:

```bash
# Dry-run client-side validation
kubectl apply --dry-run=client -f pod-bad-config.yaml
# Shows validation errors early

# Output shows which fields are invalid
```

4. Use dry-run server-side validation:

```bash
# Dry-run server-side validation
kubectl apply --dry-run=server -f pod-bad-config.yaml
# Server validates against current cluster's CRDs and OpenAPI spec
```

5. Use kubectl explain to understand valid fields:

```bash
# Explain Pod structure
kubectl explain pods
# Shows Pod description and key fields

# Explain specific field
kubectl explain pods.spec.containers
# Shows container spec fields with descriptions

# Explain resource limits
kubectl explain pods.spec.containers.resources.limits
# Shows what resource formats are allowed

# Get detailed explanation
kubectl explain pods.spec.containers.resources --recursive
# Shows full structure recursively
```

6. Check API documentation for field names:

```bash
# Find field description
kubectl explain deployment.spec.strategy
# Shows RollingUpdateDeployment strategy fields

# List all valid fields for resources
kubectl explain deployment.spec.template.spec.containers.env
# Shows environment variable structure
```

7. Create correct configuration using explain as reference:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: good-config
  labels:
    app: web
spec:
  containers:
    - name: app
      image: nginx
      resources:
        limits:
          cpu: 500m # Correct format
          memory: 512Mi # Correct format (Mi not MB)
        requests:
          cpu: 100m
          memory: 128Mi
```

8. Validate and apply the correct configuration:

```bash
# Dry-run to validate
kubectl apply --dry-run=server -f pod-good-config.yaml
# Should show no errors

# Apply
kubectl apply -f pod-good-config.yaml
# Should succeed
```

9. Check for deprecated API versions:

```bash
# List available API versions for a resource
kubectl api-resources | grep pod
# Shows API version (e.g., v1)

# Test creating with deprecated version
# Some resources have multiple versions (e.g., apps/v1 vs extensions/v1beta1)

# Explain available versions
kubectl api-versions | grep -v "/$"
# Shows all available API versions in cluster
```

**Verification Steps:**

```bash
# Verify dry-run shows errors
kubectl apply --dry-run=client -f pod-bad-config.yaml | grep -i error
# Should show validation errors

# Verify corrected config passes validation
kubectl apply --dry-run=server -f pod-good-config.yaml
# Should show no errors and print generated object

# Verify pod was created successfully
kubectl get pod good-config
# Should show running pod

# Verify explain works for various resources
kubectl explain deployment.spec.replicas
# Should show: 'number of desired pods'
```

**Expected Outcomes:**

- Bad configuration detected by client-side validation (--dry-run=client)
- Server-side validation catches field and format errors
- kubectl explain provides field descriptions
- Corrected configuration passes both validations
- Pod is successfully created from valid configuration

**Key Learning Concepts:**

- **Client-Side Validation**: Quick local check; uses kubectl's bundled OpenAPI spec
- **Server-Side Validation**: Full validation against live cluster API; catches more issues
- **Invalid Fields**: Typos or non-existent fields caught immediately
- **Format Errors**: Resource units (CPU: m/n, Memory: Mi/Gi/Ki), port ranges, etc.
- **kubectl explain**: Shows all valid fields, their types, and descriptions
- **API Versions**: Different versions may have different fields; use latest stable v1 when possible
- **Deprecations**: Older API versions may be removed; migrate to newer versions proactively

---

## Exercise 3.5: Cleanup

**Problem Statement:**
Remove all diagnostic resources created in this exercise set to clean up the cluster.

**Instructions:**

Remove problematic pods:

```bash
kubectl delete pod image-pull-error crash-loop unschedulable init-failure
```

Remove test namespace:

```bash
kubectl delete namespace test-connectivity pressure-demo
```

Remove good-config pod:

```bash
kubectl delete pod good-config
```

**Verification Steps:**

```bash
# Verify all problematic pods are removed
kubectl get pods image-pull-error crash-loop unschedulable init-failure 2>/dev/null
# Should show "not found" errors

# Verify namespaces are deleted
kubectl get namespace | grep -E "test-connectivity|pressure-demo"
# Should show nothing
```

**Expected Outcomes:**

- All diagnostic pods removed
- Test namespaces deleted
- Cluster returned to clean state

---

## Module Completion Checklist

- [ ] Completed Exercise 3.1: Diagnose pod startup failures
- [ ] Completed Exercise 3.2: Diagnose networking and connectivity
- [ ] Completed Exercise 3.3: Investigate resource pressure
- [ ] Completed Exercise 3.4: Diagnose configuration errors
- [ ] Completed Exercise 3.5: Cleanup

## Key Takeaways

1. **Pod Failure Diagnosis**: Check status phase, exit codes, events, and logs
2. **Image Pull Errors**: Registry issues, credentials, image existence
3. **Crash Loops**: Container exiting; check logs and cmd/startup requirements
4. **Unschedulable**: Resource constraints; check node capacity and requests
5. **Network Issues**: DNS resolution, service endpoints, NetworkPolicy rules
6. **Resource Pressure**: Node conditions, eviction thresholds, QoS priority
7. **Configuration Errors**: Use dry-run and kubectl explain for validation
8. **Systematic Approach**: Describe → Events → Logs → Manual testing

## Useful Commands Reference

```bash
# Pod diagnosis
kubectl describe pod <name>
kubectl logs <pod> [-c container] [--previous]
kubectl get events --field-selector involvedObject.name=<pod>

# Container status
kubectl get pod <name> -o jsonpath='{.status.containerStatuses[0].state}'
kubectl get pod <name> -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.conditions[?(@.type=="Ready")].status

# Node diagnosis
kubectl describe nodes
kubectl get nodes -o custom-columns=NAME:.metadata.name,MEMORY:.status.conditions[?(@.type=="MemoryPressure")].status
kubectl top nodes

# Network diagnosis
kubectl exec <pod> -- nslookup <service-name>
kubectl exec <pod> -- nc -zv <ip> <port>
kubectl get endpoints <service>

# Evicted pods
kubectl get pods --field-selector=status.reason=Evicted --all-namespaces

# Configuration validation
kubectl apply --dry-run=client -f file.yaml
kubectl apply --dry-run=server -f file.yaml
kubectl explain <resource>.<field>

# Port forwarding
kubectl port-forward <pod|svc> <local>:<remote>

# Resource info
kubectl describe node <name> | grep -A 10 "Allocated resources"
kubectl top pods -n <namespace>
```

---

**Completion:** Module 05 exercises are now complete. All three exercise files cover observability, deployment strategies, and troubleshooting—the critical operational skills for KCNA exam success and production Kubernetes management.
