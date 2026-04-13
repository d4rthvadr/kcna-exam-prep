# Deployment Strategies Exercises

## Module Overview

This exercise set covers Kubernetes deployment strategies for rolling out application updates with minimal downtime. You'll implement rolling updates, canary deployments, blue-green deployments, understand rollback mechanisms, and manage deployment configuration changes. These patterns are critical for production Kubernetes deployments and directly support KCNA exam domain: Cloud Native Application Delivery (5%).

---

## Exercise 2.1: Implement Rolling Update Strategy

**Problem Statement:**
You need to update your application from version 1.19 to 1.21 with zero downtime. Configure a deployment with rolling update strategy, monitor the rollout progress, and understand how maxSurge and maxUnavailable control the update pace.

**Learning Objectives:**

- Configure rolling update strategy with maxSurge and maxUnavailable
- Understand replica management during rolling updates
- Monitor rollout progress and pod replacement
- Understand trade-offs between speed and resource usage

**Instructions:**

1. Create an initial deployment with version 1.19:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rolling-update-demo
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1 # Max 1 extra pod during update
      maxUnavailable: 0 # Never take down pods during update
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
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
```

Apply:

```bash
kubectl apply -f deployment-rolling-update.yaml
```

2. Verify initial state:

```bash
# Check deployment
kubectl get deployment rolling-update-demo
# READY should show 4/4

# Check pods
kubectl get pods -l app=web -o wide
# Should show 4 nginx:1.19 pods
```

3. Trigger rolling update by changing image:

```bash
kubectl set image deployment/rolling-update-demo app=nginx:1.21 --record
# --record adds this change to rollout history
```

4. Monitor rollout in real-time:

```bash
# Watch pods being replaced
kubectl get pods -l app=web --watch

# In another terminal, continuously check image versions
while true; do kubectl get pods -l app=web -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image | head -6; echo "---"; sleep 2; done
```

5. Check rollout status:

```bash
# Show rollout progress
kubectl rollout status deployment/rolling-update-demo

# Check actively updating pods
kubectl get pods -l app=web -o wide
```

6. Verify rollout completed:

```bash
# All pods should be running 1.21
kubectl get pods -l app=web -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image

# Check deployment
kubectl get deployment rolling-update-demo
# READY should be 4/4, UP-TO-DATE should be 4
```

7. Check rollout history:

```bash
kubectl rollout history deployment/rolling-update-demo
# Shows revisions of the deployment

# Get details of specific revision
kubectl rollout history deployment/rolling-update-demo --revision=2
```

**Verification Steps:**

```bash
# Verify initial deployment
kubectl get deployment rolling-update-demo -o jsonpath='{.spec.replicas}'
# Should show: 4

# Verify rolling update strategy
kubectl get deployment rolling-update-demo -o jsonpath='{.spec.strategy.rollingUpdate}'
# Should show: maxSurge=1, maxUnavailable=0

# Verify all pods updated
kubectl get pods -l app=web -o jsonpath='{.items[*].spec.containers[0].image}' | grep -o 'nginx:1.21' | wc -l
# Should show: 4

# Verify rollout complete
kubectl rollout status deployment/rolling-update-demo --timeout=5m | grep "successfully rolled out"
```

**Expected Outcomes:**

- Deployment updates from nginx:1.19 to nginx:1.21 with rolling update
- maxSurge=1 allows 5 pods temporarily (4 desired + 1 surge)
- maxUnavailable=0 keeps all 4 pods running throughout update
- Old pods gradually replaced with new pods
- Rollout history shows revisions 1 and 2
- No traffic interruption during update

**Key Learning Concepts:**

- **maxSurge**: Additional replicas allowed above desired count (can be number or percentage)
  - 0 = don't create extra (slower, no resource waste)
  - 1 = 1 extra (balanced: faster with minimal resources)
  - 25% = quarter of replicas extra (default, scales with replica count)
- **maxUnavailable**: Replicas allowed to be unavailable (can be number or percentage)
  - 0 = keep all running (safe, doubles resource usage)
  - 1 = allow 1 down (faster, may cause brief downtime)
  - 25% = quarter down (default, faster rollout)
- **Trade-offs**: Fast rollout (high surge/unavailable) vs. resource efficient (low values)
- **Readiness Probes**: Critical for rolling updates to know when pod is ready to take traffic
- **Rollback**: Can revert to previous revision if issues detected

---

## Exercise 2.2: Perform Rollback to Previous Deployment Version

**Problem Statement:**
A deployment update to version 2.0 introduces bugs and causes application failures. You need to quickly rollback to the previous stable version (1.21). Perform a rollback using kubectl rollout undo and verify the application is restored.

**Learning Objectives:**

- Use `kubectl rollout undo` to revert to previous revision
- Rollback to specific revision vs. immediate previous
- Monitor rollback progress
- Understand revision history and restoration

**Instructions:**

1. Start with the completed rolling update deployment:

```bash
# Verify current state (should be nginx:1.21)
kubectl get pods -l app=web -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image | head -5

# Check rollout history
kubectl rollout history deployment/rolling-update-demo
# Should show revisions 1 and 2
```

2. First, trigger an update to buggy version 2.0 to simulate the issue:

```bash
kubectl set image deployment/rolling-update-demo app=nginx:2.0 --record
```

3. Monitor the rollout:

```bash
# Watch the update
kubectl rollout status deployment/rolling-update-demo
```

4. Check new pods are running 2.0:

```bash
kubectl get pods -l app=web -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image | head -5
```

5. Detect issue and initiate rollback (revert to revision 2):

```bash
kubectl rollout undo deployment/rolling-update-demo --to-revision=2
# This reverts to revision 2 (nginx:1.21)
```

6. Monitor rollback progress:

```bash
# Watch pods being rolled back
kubectl get pods -l app=web --watch

# Or check status
kubectl rollout status deployment/rolling-update-demo
```

7. Verify rollback completed:

```bash
# Check all pods are back to 1.21
kubectl get pods -l app=web -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image | head -5

# Check rollout history
kubectl rollout history deployment/rolling-update-demo
# Should show 3 revisions now (1=original, 2=nginx:1.21, 3=nginx:2.0 that was reverted)
```

8. Alternative: Immediate rollback (to previous revision):

```bash
# If you want to rollback without checking revision number
kubectl rollout undo deployment/rolling-update-demo
# Automatically goes back one revision
```

**Verification Steps:**

```bash
# Verify all pods back to 1.21
kubectl get pods -l app=web -o jsonpath='{.items[*].spec.containers[0].image}' | grep -o '1.21' | wc -l
# Should show: 4

# Verify deployment status
kubectl get deployment rolling-update-demo -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'
# Should show: 4/4

# Verify rollout history shows attempt to 2.0 and reversion
kubectl rollout history deployment/rolling-update-demo
# Should show revisions 1, 2, 3
```

**Expected Outcomes:**

- Deployment successfully rolls back from buggy 2.0 to stable 1.21
- Rollback uses same rolling update strategy (zero downtime)
- Rollout history shows full progression (original → 1.21 → 2.0 → 1.21 again)
- Application is restored to previous working state
- No manual pod deletion necessary

**Key Learning Concepts:**

- **Rollback Mechanism**: Creates new ReplicaSet with previous template; scales old down, new up
- **Revision Selection**: Use `--to-revision=N` to go to specific revision; omit to go back one
- **Rollout History**: Each change (image update, etc.) creates new revision
- **Speed**: Rollback uses same rolling update strategy, so takes similar time
- **When to Rollback**: Image pull errors, readiness probe failures, application panics
- **Prevention**: Thorough testing before deployment, gradual rollouts (canary), monitoring

---

## Exercise 2.3: Implement Canary Deployment Pattern

**Problem Statement:**
You want to deploy a new version to a subset of users first to validate it before full rollout. Implement a canary deployment by running two deployments (stable and canary) and routing a small percentage of traffic to the canary version using label selectors.

**Learning Objectives:**

- Understand canary deployment pattern
- Create multiple deployments for canary testing
- Route traffic using service selectors
- Monitor canary version separately
- Scale up canary when validated

**Instructions:**

1. Create a stable deployment (v1):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-stable
spec:
  replicas: 9
  selector:
    matchLabels:
      app: web
      version: stable
  template:
    metadata:
      labels:
        app: web
        version: stable
    spec:
      containers:
        - name: app
          image: nginx:1.19
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
```

Apply:

```bash
kubectl apply -f deployment-web-stable.yaml
```

2. Create a service that routes to both stable and canary:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web # Routes to any pod with app: web label
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

Apply:

```bash
kubectl apply -f service-web.yaml
```

3. Create canary deployment (v2) with 1 replica initially:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-canary
spec:
  replicas: 1 # Start with 1 canary pod
  selector:
    matchLabels:
      app: web
      version: canary
  template:
    metadata:
      labels:
        app: web
        version: canary
    spec:
      containers:
        - name: app
          image: nginx:1.21 # New version
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
```

Apply:

```bash
kubectl apply -f deployment-web-canary.yaml
```

4. Verify traffic distribution:

```bash
# Check pods created
kubectl get pods -l app=web -o wide
# Should show 9 stable (1.19) + 1 canary (1.21)

# Check service endpoints
kubectl get endpoints web-service
# Should list all 10 pods (both stable and canary)
```

5. Simulate traffic and verify both versions receive traffic:

```bash
# Generate traffic to the service
# Using a test pod that hits the service 100 times and logs which version responds
kubectl run -i --tty load-test --image=busybox --restart=Never -- sh -c \
  'for i in {1..100}; do wget -O- http://web-service/ 2>/dev/null | head -1; done'
```

6. Monitor canary metrics:

```bash
# Check if canary pod is receiving traffic
kubectl top pods -l app=web

# Check canary logs to confirm receiving requests
CANARY_POD=$(kubectl get pod -l app=web,version=canary -o jsonpath='{.items[0].metadata.name}')
kubectl logs $CANARY_POD | tail -20
```

7. If canary is stable, scale it up and stable down:

```bash
# Increase canary replicas
kubectl scale deployment web-canary --replicas=5

# Decrease stable replicas
kubectl scale deployment web-stable --replicas=5

# Check distribution
kubectl get pods -l app=web -o custom-columns=NAME:.metadata.name,VERSION:.metadata.labels.version | head -15
```

8. Complete the rollout when confident:

```bash
# Scale canary to full
kubectl scale deployment web-canary --replicas=10

# Scale stable to zero
kubectl scale deployment web-stable --replicas=0

# Verify
kubectl get pods -l app=web | wc -l
# Should show 10 canary pods
```

**Verification Steps:**

```bash
# Verify stable and canary coexist
kubectl get deployments web-stable web-canary -o custom-columns=NAME:.metadata.name,REPLICAS:.spec.replicas,IMAGE:.spec.template.spec.containers[0].image

# Verify traffic goes to both
kubectl get endpoints web-service | wc -l
# Should show multiple IPs

# Verify canary pod is running
kubectl get pods -l version=canary
# Should show 1+ canary pods with 1.21

# Verify service routes correctly
kubectl get service web-service -o jsonpath='{.spec.selector}'
# Should show: app: web
```

**Expected Outcomes:**

- Stable deployment with 9 nginx:1.19 replicas
- Canary deployment with 1 nginx:1.21 replica
- Service routes to both using label selector `app: web`
- Traffic distributed approximately 90% to stable, 10% to canary (proportional to replicas)
- Canary can be monitored separately
- Can scale canary up and stable down gradually
- Clean traffic transfer without disruption

**Key Learning Concepts:**

- **Canary Pattern**: Small rollout to percentage of users first; validates without full exposure
- **Service Selector**: Routes to any pod matching labels; both deployments match `app: web`
- **Traffic Distribution**: Proportional to replica counts (9 stable → 90% traffic)
- **Rollback**: Reverse scaling (scale canary to 0) if issues detected
- **Monitoring**: Separate monitoring of canary metrics for validation
- **Duration**: Typical canary runs for hours or days before full rollout
- **Limitations**: Without service mesh, traffic split is only proportional (not exact percentages like 5%)

---

## Exercise 2.4: Implement Blue-Green Deployment Pattern

**Problem Statement:**
You want a safer deployment where you can run two completely independent environments (blue=current, green=new) and switch traffic instantly with zero downtime. Implement blue-green deployment using two separate deployments and switch traffic by updating the service selector.

**Learning Objectives:**

- Understand blue-green deployment pattern
- Run two independent environments simultaneously
- Switch traffic by changing service selector
- Understand instant cutover vs. gradual (compareto canary)
- Rollback capability by switching back

**Instructions:**

1. Create blue deployment (current production):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
      deployment: blue
  template:
    metadata:
      labels:
        app: web
        deployment: blue
    spec:
      containers:
        - name: app
          image: nginx:1.19
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
```

Apply:

```bash
kubectl apply -f deployment-web-blue.yaml
```

2. Create a service initially pointing to blue:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
    deployment: blue # Points to blue deployment
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

Apply:

```bash
kubectl apply -f service-web-blue-green.yaml
```

3. Verify blue is receiving traffic:

```bash
# Check service endpoints point to blue pods
kubectl get endpoints web
# Should show only blue deployment pods

# Check pods
kubectl get pods -l deployment=blue
# Should show 3 pods
```

4. Deploy green environment (new version) with no traffic:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
      deployment: green
  template:
    metadata:
      labels:
        app: web
        deployment: green
    spec:
      containers:
        - name: app
          image: nginx:1.21 # New version
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
```

Apply:

```bash
kubectl apply -f deployment-web-green.yaml
```

5. Verify green is running but not receiving traffic:

```bash
# Check service endpoints (should still be blue only)
kubectl get endpoints web

# Verify green pods exist
kubectl get pods -l deployment=green
# Should show 3 pods running

# Verify green is not in service
kubectl get service web -o jsonpath='{.spec.selector}'
# Should show: deployment: blue
```

6. Test green environment independently (direct to green pods):

```bash
# Get a green pod IP
GREEN_POD_IP=$(kubectl get pod -l deployment=green -o jsonpath='{.items[0].status.podIP}')

# Create a test pod that directly tests green
kubectl run test --image=busybox --rm -it -- \
  wget -O- http://$GREEN_POD_IP/ 2>/dev/null | head -1
```

7. Switch traffic from blue to green:

```bash
# Update service selector to point to green
kubectl patch service web -p '{"spec":{"selector":{"deployment":"green"}}}'
```

8. Verify traffic is now on green:

```bash
# Check service endpoints (should now point to green)
kubectl get endpoints web
# Should show only green pods

# Verify service selector changed
kubectl get service web -o jsonpath='{.spec.selector}'
# Should show: deployment: green
```

9. Rollback if needed (switch back to blue):

```bash
# Switch back to blue
kubectl patch service web -p '{"spec":{"selector":{"deployment":"blue"}}}'

# Verify blue is active again
kubectl get endpoints web
# Should show only blue pods
```

**Verification Steps:**

```bash
# Verify blue is active initially
kubectl get service web -o jsonpath='{.spec.selector}'
# Should show: app: web, deployment: blue

# Verify green pods exist
kubectl get pods -l deployment=green | wc -l
# Should show: 4 (3 running + header)

# Verify traffic switches
kubectl get endpoints web
# Before switch: blue pods only
# After patch: green pods only

# Verify instant cutover (no downtime)
# Watch continuous requests - they should instantly switch to green without interruption
```

**Expected Outcomes:**

- Blue deployment with 3 nginx:1.19 replicas initially receives all traffic
- Green deployment with 3 nginx:1.21 replicas deployed with zero traffic
- Service selector can be instantly changed to route to green
- Traffic switches at network layer (service selector update)
- Instant rollback possible by switching back to blue
- No gradual traffic shift (unlike canary)

**Key Learning Concepts:**

- **Blue-Green Pattern**: Two complete environments; switch one selector
- **Advantages**: Instant cutover, easy rollback, test full environment before switching
- **Disadvantages**: Double resource usage (2x deployment running), more complex
- **Service Selector**: Single label change switches all traffic instantly
- **Ready Check**: Green should be fully ready before switching (all pods ready)
- **Monitoring**: Monitor green under real traffic after switch before removing blue
- **Cleanup**: Once green is stable, can scale down blue to free resources
- **Better Than Canary**: Zero partial outage; all traffic switches instantly

---

## Exercise 2.5: Understand Deployment Pause and Rollout Controls

**Problem Statement:**
During a rolling update, you need to pause the rollout to monitor intermediate state, make manual adjustments, or wait for external system updates. Implement pause/resume controls to manage deployment rollouts with precision.

**Learning Objectives:**

- Use `kubectl rollout pause` to pause rolling updates
- Use `kubectl rollout resume` to resume paused rollouts
- Understand stopped state of deployments
- Controlled phased rollouts with pause/resume
- Manual validation during rollout

**Instructions:**

1. Create a deployment for phased rollout:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: phased-rollout
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
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
```

Apply:

```bash
kubectl apply -f deployment-phased-rollout.yaml
```

2. Verify initial state:

```bash
# Check all pods are 1.19
kubectl get pods -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image | head -8
```

3. Start rolling update:

```bash
kubectl set image deployment/phased-rollout app=nginx:1.21 --record
```

4. Immediately pause the rollout (before it completes):

```bash
# Wait a moment for rolling update to start
sleep 5

# Pause the rollout
kubectl rollout pause deployment/phased-rollout
```

5. Check paused state:

```bash
# Some pods should be 1.19, some 1.21
kubectl get pods -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image

# Check that rollout is paused
kubectl get deployment phased-rollout -o jsonpath='{.spec.progressDeadlineSeconds}'

# Check replica counts (some updated, some old)
kubectl get deployment phased-rollout -o jsonpath='{.status.conditions[?(@.reason=="ProgressDeadlineExceeded")]}'
```

6. Perform validation or external coordination:

```bash
# Simulate validation delay
echo "Waiting for external system to update..."
sleep 10

# Check pod logs or metrics during pause
kubectl logs -l app=web --tail=1 | head -3
```

7. Resume the rollout:

```bash
kubectl rollout resume deployment/phased-rollout
```

8. Monitor completion:

```bash
# Watch remaining update
kubectl rollout status deployment/phased-rollout

# All pods should now be 1.21
kubectl get pods -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image | head -8
```

**Verification Steps:**

```bash
# Verify pause was successful
kubectl get deployment phased-rollout -o jsonpath='{.status.conditions[?(@.type=="Progressing")]}'
# Should show Reason: "NewReplicaSetAvailable" or similar (paused state)

# Verify mixed state during pause
kubectl get pods -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image | grep -c '1.19'
# Should show at least 1 (paused, not all updated)

# Verify resume completes update
kubectl get pods -o jsonpath='{.items[*].spec.containers[0].image}' | grep -o '1.21' | wc -l
# Should show: 6 (all updated after resume)
```

**Expected Outcomes:**

- Rollout pauses mid-update with mixed pod versions
- Some pods remain at 1.19, others updated to 1.21
- Pause state visible in deployment status
- Rollout resumes and completes normally
- Final state has all pods at 1.21

**Key Learning Concepts:**

- **Pause Mechanism**: Stops ReplicaSet scaling; existing pods continue running
- **Use Cases**: Coordinate with external systems, validate before full rollout, prevent unintended updates
- **Resumed Update**: Continues from paused state using same strategy
- **Deadline**: progressDeadlineSeconds (default 600s) is timer for rollout; pause doesn't stop this
- **Replica Sets**: Old and new ReplicaSets exist during pause (manual cleanup available)

---

## Exercise 2.6: Configure Deployment Revision History and Limits

**Problem Statement:**
Your cluster has accumulated many deployment revisions over time, consuming storage and making history management difficult. Configure revision history limits and understand how Kubernetes manages ReplicaSet versions.

**Learning Objectives:**

- Understand revisionHistoryLimit
- Configure history limit in deployment spec
- Clean up old revisions while keeping recent ones
- Understand ReplicaSet lifecycle and storage implications

**Instructions:**

1. Create a deployment with explicit revision history limit:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: history-limited
spec:
  replicas: 2
  revisionHistoryLimit: 3 # Keep only last 3 revisions
  strategy:
    type: RollingUpdate
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
```

Apply:

```bash
kubectl apply -f deployment-history-limited.yaml
```

2. Perform multiple updates to create revision history:

```bash
# Update 1
kubectl set image deployment/history-limited app=nginx:1.20 --record
sleep 10

# Update 2
kubectl set image deployment/history-limited app=nginx:1.21 --record
sleep 10

# Update 3
kubectl set image deployment/history-limited app=nginx:latest --record
sleep 10

# Update 4 (this should cause revision 1 to be cleaned up)
kubectl set image deployment/history-limited app=nginx:1.22 --record
sleep 10
```

3. Check revision history:

```bash
# Show all revisions
kubectl rollout history deployment/history-limited
# Should show only last 3 revisions (1 removed due to revisionHistoryLimit: 3)

# Show specific revision
kubectl rollout history deployment/history-limited --revision=2
```

4. Check ReplicaSets created:

```bash
# List all ReplicaSets for this deployment
kubectl get rs -l app=web
# Should show only active and recent (old ones cleaned up)

# Check which ReplicaSet is active
kubectl get rs -l app=web -o custom-columns=NAME:.metadata.name,REPLICAS:.status.replicas,READY:.status.readyReplicas,IMAGE:.spec.template.spec.containers[0].image
```

5. Create a deployment without history limit (keep all):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: history-unlimited
spec:
  replicas: 2
  revisionHistoryLimit: 10 # Keep more revisions
  selector:
    matchLabels:
      app: web-unlimited
  template:
    metadata:
      labels:
        app: web-unlimited
    spec:
      containers:
        - name: app
          image: nginx:1.19
```

Apply and trigger multiple updates:

```bash
kubectl apply -f deployment-history-unlimited.yaml

for i in {20..25}; do
  kubectl set image deployment/history-unlimited app=nginx:1.$i --record
  sleep 5
done
```

6. Compare revision counts:

```bash
# Limited history
echo "Limited history:"
kubectl rollout history deployment/history-limited | tail -1

# Unlimited history
echo "Unlimited history:"
kubectl rollout history deployment/history-unlimited | tail -1
```

**Verification Steps:**

```bash
# Verify revisionHistoryLimit is set
kubectl get deployment history-limited -o jsonpath='{.spec.revisionHistoryLimit}'
# Should show: 3

# Verify old revisions are cleaned up
kubectl rollout history deployment/history-limited | wc -l
# Should show around 4 (3 revisions + header)

# Verify ReplicaSets match limit
kubectl get rs -l app=web | wc -l
# Should show only recent ones (approximately revisionHistoryLimit + 1 including active)

# Verify current image matches latest update
kubectl get deployment history-limited -o jsonpath='{.spec.template.spec.containers[0].image}'
# Should show: nginx:1.22
```

**Expected Outcomes:**

- Deployment with revisionHistoryLimit: 3 keeps only 3 recent revisions
- Old ReplicaSets are cleaned up automatically
- Rollback is possible only to kept revisions
- UnlimitedHistory keeps all revisions (more storage)
- Storage impact is visible when comparing limited vs. unlimited

**Key Learning Concepts:**

- **revisionHistoryLimit**: Default is 10; controls how many ReplicaSets to keep
- **Storage Efficiency**: Lower limits save cluster storage, higher limits allow deeper rollback
- **ReplicaSet Cleanup**: Old ReplicaSets are scaled to 0 but not immediately deleted; cleanup is lazy
- **Rollback Limitation**: Can only rollback to kept revisions; older ones are removed
- **Best Practice**: Balance between storage and rollback depth (typically 5-10 revisions)

---

## Exercise 2.7: Cleanup

**Problem Statement:**
Remove all deployment strategy resources created in this exercise set to clean up the cluster.

**Instructions:**

Remove deployments:

```bash
kubectl delete deployment rolling-update-demo
kubectl delete deployment web-stable web-canary
kubectl delete service web-service
kubectl delete deployment web-blue web-green
kubectl delete service web
kubectl delete deployment phased-rollout
kubectl delete deployment history-limited history-unlimited
kubectl delete pod load-test test
```

**Verification Steps:**

```bash
# Verify all deployments removed
kubectl get deployments
# Should show none

# Verify all services removed
kubectl get services | grep -v kubernetes
# Should show only defaults
```

**Expected Outcomes:**

- All custom deployments removed
- All custom services removed
- Cluster returned to clean state

---

## Module Completion Checklist

- [ ] Completed Exercise 2.1: Rolling update strategy
- [ ] Completed Exercise 2.2: Rollback to previous version
- [ ] Completed Exercise 2.3: Canary deployment pattern
- [ ] Completed Exercise 2.4: Blue-green deployment pattern
- [ ] Completed Exercise 2.5: Pause/resume rollout controls
- [ ] Completed Exercise 2.6: Revision history configuration
- [ ] Completed Exercise 2.7: Cleanup

## Key Takeaways

1. **Rolling Update**: Gradually replaces pods using maxSurge/maxUnavailable
2. **Rollback**: Revert to previous working revision with `kubectl rollout undo`
3. **Canary**: Small percentage rollout for validation before full deployment
4. **Blue-Green**: Two complete environments; instant traffic switch via selector
5. **Pause/Resume**: Controlled phased rollouts with manual validation points
6. **Revision History**: Limited by revisionHistoryLimit; balance storage vs. rollback depth
7. **Strategy Selection**:
   - **Rolling Update**: Default, gradual, safe but slow
   - **Canary**: Percentage-based rollout, longer duration
   - **Blue-Green**: Instant switch, double resources, easy rollback

## Useful Commands Reference

```bash
# Image updates
kubectl set image deployment/<name> <container>=<image>:<tag> --record

# Rollout status
kubectl rollout status deployment/<name>

# Rollout history
kubectl rollout history deployment/<name>
kubectl rollout history deployment/<name> --revision=<N>

# Rollback
kubectl rollout undo deployment/<name>
kubectl rollout undo deployment/<name> --to-revision=<N>

# Pause/resume
kubectl rollout pause deployment/<name>
kubectl rollout resume deployment/<name>

# Scaling
kubectl scale deployment/<name> --replicas=<N>

# Manual patch (for service selectors)
kubectl patch service/<name> -p '{"spec":{"selector":{"key":"value"}}}'

# Check revision history limit
kubectl get deployment/<name> -o jsonpath='{.spec.revisionHistoryLimit}'

# View ReplicaSets
kubectl get rs -l <label-selector>
```

---

**Next Steps:** Complete Module 05 troubleshooting exercises, then begin Step 7 (add global resources like exam tips and mock scenarios).
