# Exercise: Deployments - Declarative Pod Management

## 📌 Problem Statement

Create and manage Deployments - the standard way to run applications in Kubernetes. You'll learn how Deployments ensure high availability, handle updates, and automatically manage underlying ReplicaSets. This is the most common resource in practice.

## 🎯 Learning Objectives

By completing this exercise, you will be able to:

1. Create a Deployment and understand how it manages Pods
2. Scale Deployments up and down
3. Update Deployment images and specifications
4. Understand and perform rolling updates
5. Rollback a failed deployment
6. Monitor Deployment status and events

## 📝 Exercises

### Exercise 2.1: Create a Basic Deployment

**Objective:** Create and verify a Deployment with replicas.

**Instructions:**

1. Create a file `nginx-deployment.yaml`
2. Define a Deployment:
   - Name: `nginx-deployment`
   - Replicas: `3`
   - Selector: `app: nginx`
   - Container name: `web`
   - Image: `nginx:1.21`
   - Container port: `80`
3. Apply the manifest

**Verification Steps:**

```bash
# View deployment
kubectl get deployments

# Get detailed status
kubectl get deployment nginx-deployment -o wide

# Describe deployment - shows replica status, conditions
kubectl describe deployment nginx-deployment

# View ReplicaSets (created automatically by Deployment)
kubectl get replicasets

# View Pods managed by the deployment
kubectl get pods -l app=nginx

# Watch the deployment create pods
watch kubectl get pods -l app=nginx
```

**Expected Outcomes:**

- Deployment shows: Desired=3, Current=3, Up-to-date=3, Available=3
- Three Pods are created with names like `nginx-deployment-<random>`
- ReplicaSet is created with name like `nginx-deployment-<hash>`
- All Pods are in "Running" state
- Deployment has status "Progressing" → "Available"

**Key Learning:**

- Deployment doesn't create Pods directly
- Deployment creates a ReplicaSet
- ReplicaSet creates and manages Pods
- If you delete a Pod, ReplicaSet automatically recreates it

---

### Exercise 2.2: Rolling Update - Change Image

**Objective:** Update the application image and observe rolling update behavior.

**Instructions:**

1. Using the nginx-deployment from Exercise 2.1
2. Update the image from `nginx:1.21` to `nginx:1.22`
3. Observe Pods being replaced gradually
4. Verify all Pods running new version

**Verification Steps:**

```bash
# Check current image
kubectl get deployment nginx-deployment -o yaml | grep image:

# Method 1: Update deployment directly (not recommended for production)
kubectl set image deployment/nginx-deployment web=nginx:1.22 --record

# Method 2: Edit deployment YAML (preferred)
kubectl edit deployment nginx-deployment
# Find spec.template.spec.containers[0].image and change to nginx:1.22

# Check rollout status (real-time)
kubectl rollout status deployment/nginx-deployment

# Watch pods rolling update in real-time
watch kubectl get pods -l app=nginx

# Verify all running new image
kubectl get pods -l app=nginx -o jsonpath='{.items[*].spec.containers[0].image}'

# Check rollout history
kubectl rollout history deployment/nginx-deployment
```

**Expected Outcomes:**

- Old Pods are terminated one by one
- New Pods with updated image start up
- At all times, at least 2 Pods are serving (if deployment has maxUnavailable: 1)
- Final state: 3 Pods all running nginx:1.22
- Rollout history shows 2 revisions
- Service continues with no downtime

**Rolling Update Parameters (in deployment spec):**

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1 # Max pods that can be unavailable
    maxSurge: 1 # Max extra pods created during update
```

---

### Exercise 2.3: Rollback a Failed Deployment

**Objective:** Understand how to revert a bad deployment.

**Instructions:**

1. Intentionally deploy a broken image
2. Observe the issues
3. Rollback to previous working version
4. Verify recovery

**Instructions (Detailed):**

```bash
# Start with working version (nginx:1.22 from previous exercise)

# Deploy a broken image version
kubectl set image deployment/nginx-deployment web=nginx:broken-version --record

# Or edit and save bad image version

# Watch what happens
watch kubectl get pods -l app=nginx
kubectl get deployment nginx-deployment
```

**Verification Steps:**

```bash
# Check rollout history
kubectl rollout history deployment/nginx-deployment

# View details of specific revision
kubectl rollout history deployment/nginx-deployment --revision=2

# Check deployment status (will show issues)
kubectl describe deployment nginx-deployment

# Check pod events and status
kubectl get pods -l app=nginx
kubectl describe pod <pod-name>

# Rollback to previous revision
kubectl rollout undo deployment/nginx-deployment

# Or rollback to specific revision
kubectl rollout undo deployment/nginx-deployment --to-revision=1

# If revision 1 was the original working version, this restores it

# Check rollout status
kubectl rollout status deployment/nginx-deployment

# Verify pods running working image again
kubectl get pods -l app=nginx -o jsonpath='{.items[0].spec.containers[0].image}'
```

**Expected Outcomes:**

- After rollback, deployment reverts to last known good state
- Pods terminate with broken image
- Pods start with working image
- Deployment goes through rolling update again
- Final state: 3 Pods all running working version

**Key Learning:**

- Deployment keeps history of revisions
- `--record` flag adds comment about what changed (good practice)
- Can rollback to any previous revision
- Rollback is another rolling update (gradual, maintains availability)

---

### Exercise 2.4: Manual Scaling

**Objective:** Scale Deployment replicas up and down.

**Instructions:**

1. Using the working deployment from Exercise 2.3
2. Scale up to 5 replicas
3. Observe new Pods created
4. Scale down to 2 replicas
5. Observe old Pods removed

**Verification Steps:**

```bash
# Current status
kubectl get deployment nginx-deployment

# Scale to 5 replicas
kubectl scale deployment/nginx-deployment --replicas=5

# Watch pods being created
kubectl get pods -l app=nginx --watch

# Or get repeatedly
watch kubectl get pods -l app=nginx

# Verify 5 pods running
kubectl get pods -l app=nginx | wc -l

# Check desired count matches
kubectl get deployment nginx-deployment

# Scale down to 2
kubectl scale deployment/nginx-deployment --replicas=2

# Watch pods being terminated
watch kubectl get pods -l app=nginx

# Verify only 2 remain
kubectl get pods -l app=nginx
```

**Expected Outcomes:**

- When scaling up: New Pods created and transition to Running
- When scaling down: Pods are gracefully terminated
- ReplicaSet immediately recognizes desired count doesn't match
- Pods removed are selected somewhat randomly (not in specific order)
- Deployment status updates to reflect new desired state

**Note:**

- Manual scaling is useful for testing
- For production, use HorizontalPodAutoscaler (covered in Module 05)
- Scaling is immediate (no rolling update needed)

---

### Exercise 2.5: Deployment Manifest Management

**Objective:** Update deployment using YAML file edits.

**Instructions:**

1. Create a more complete deployment manifest
2. Update multiple fields at once
3. Apply changes and verify

**Create file `complete-deployment.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: v1
    spec:
      containers:
        - name: app
          image: nginx:1.22
          ports:
            - containerPort: 80
```

**Then update the file:**

```bash
# Apply initial version
kubectl apply -f complete-deployment.yaml

# Edit the file and add:
# - Change replicas to 2
# - Update image to latest
# - Add environment variable
# - Add resource requests/limits

# Use kubectl apply to update (idempotent)
kubectl apply -f complete-deployment.yaml

# Check what changed
kubectl describe deployment app-deployment
```

**Verification Steps:**

```bash
# Check current spec
kubectl get deployment app-deployment -o yaml

# Verify changes applied
kubectl get deployment app-deployment

# Describe to see all changes
kubectl describe deployment app-deployment

# Verify pods updated
kubectl get pods -l app=myapp
```

**Expected Outcomes:**

- All changes from YAML applied to deployment
- Deployment updated without recreating from scratch
- Pods reflect new specifications

---

### Exercise 2.6: Delete Deployment

**Objective:** Properly clean up Deployments and their owned resources.

**Instructions:**

1. Delete all deployments created in this exercise

**Verification Steps:**

```bash
# Delete by manifest
kubectl delete -f nginx-deployment.yaml
kubectl delete -f complete-deployment.yaml

# Or delete by name
kubectl delete deployment nginx-deployment
kubectl delete deployment app-deployment

# Verify deletion
kubectl get deployments
kubectl get replicasets
kubectl get pods

# All should be empty or none from our exercises
```

**Expected Outcomes:**

- Deployments deleted
- ReplicaSets deleted (cascading delete)
- Pods deleted (cascading delete)
- `kubectl get` commands return no results

---

## 🧠 Key Concepts Explained

### Deployment Architecture

```
Deployment
  └── ReplicaSet (manages Pod count)
      ├── Pod 1
      ├── Pod 2
      └── Pod 3
```

- **Deployment**: Declarative spec for desired state
- **ReplicaSet**: Created and controlled by Deployment, manages Pod replicas
- **Pods**: Actual running containers

### Why this hierarchy?

- Deployment manages version/revision history via ReplicaSets
- Each update creates new ReplicaSet with new hash
- Old ReplicaSets kept for rollback
- ReplicaSet ensures desired replica count always running

### Rolling Update Strategy

- **maxUnavailable**: How many Pods can be down during update
- **maxSurge**: How many extra Pods can exist during update
- Balance between capacity and availability

Example: 3 replicas, maxUnavailable=1, maxSurge=1

- Step 1: Kill 1 Pod (2 running), create 1 new (2+1=3 running)
- Step 2: Kill 1 old Pod (2 running), create 1 new (2+1=3 running)
- Step 3: Kill 1 old Pod (2 running), create 1 new (2+1=3 running)
- Result: All 3 Pods now on new version, never below 2 running

---

## 💡 Debugging Tips

| Issue                                | Solution                                                  |
| ------------------------------------ | --------------------------------------------------------- |
| Pods not starting                    | `kubectl describe deployment <name>` - check Events       |
| Update stuck in progress             | `kubectl rollout history` - check what revision you're on |
| Want to see previous running version | `kubectl rollout history deployment/<name> --revision=N`  |
| Need to stop ongoing rollout         | `kubectl rollout pause deployment/<name>`                 |
| Need to resume paused rollout        | `kubectl rollout resume deployment/<name>`                |

---

## ✅ Exercise Completion Checklist

- [ ] Created Deployment with 3 replicas
- [ ] Verified ReplicaSet creates Pods
- [ ] Performed image update (rolling update)
- [ ] Rolled back failed deployment
- [ ] Scaled deployment up and down
- [ ] Updated deployment via YAML file
- [ ] Cleaned up all Deployments
- [ ] Understand Deployment manages Pods reliably
- [ ] Understand rolling update strategy
- [ ] Ready to move to Services

---

## 🎓 Next Steps

Once complete, move to `services/exercise.md` to learn how to expose Deployments to clients.

## 📚 Reference Templates

Check `/templates/deployment-template.yaml` for boilerplate structure.
