# Exercise: Pods - Fundamentals

## 📌 Problem Statement

Create and manage individual Pods in Kubernetes. This exercise covers the basics of Pod lifecycle, multi-container Pods, and debugging techniques. You'll learn that Pods are ephemeral and how to inspect their state using kubectl.

## 🎯 Learning Objectives

By completing this exercise, you will be able to:

1. Create a single-container Pod from a YAML manifest
2. Create a multi-container Pod and understand shared namespaces
3. Execute commands inside a running Pod
4. View Pod logs and troubleshoot basic issues
5. Understand Pod lifecycle and restart policies
6. Clean up Pods properly

## 📝 Exercises

### Exercise 1.1: Create a Simple Pod

**Objective:** Create a basic nginx Pod and verify it's running.

**Instructions:**

1. Create a file `nginx-pod.yaml` based on the pod template in `/templates/pod-template.yaml`
2. Simplify the template - remove resource limits/requests for now, just keep:
   - Pod name: `nginx-simple`
   - Container name: `web`
   - Image: `nginx:latest`
   - Container port: `80`
3. Apply the manifest: `kubectl apply -f nginx-pod.yaml`
4. Verify Pod is running

**Verification Steps:**

```bash
# List all pods
kubectl get pods

# Get more details (including IP)
kubectl get pods -o wide

# Describe the pod (shows events, status details)
kubectl describe pod nginx-simple

# Check pod status
kubectl get pod nginx-simple -o yaml | grep -A 5 status
```

**Expected Outcomes:**

- Pod appears in `kubectl get pods` with status "Running"
- Pod has been assigned an IP address (visible in `kubectl get pods -o wide`)
- `kubectl describe pod` shows no errors in Events section
- Container ready count is 1/1

**Success Criteria:**
✅ Pod is in "Running" state  
✅ Container is "Ready"  
✅ No restart count (restarts should be 0)

---

### Exercise 1.2: Access Pod Logs

**Objective:** Understand how to view and follow Pod logs for debugging.

**Instructions:**

1. Using the nginx-pod from Exercise 1.1, view its logs
2. Try to make an HTTP request to the Pod to generate logs
3. Observe log entries

**Verification Steps:**

```bash
# View all logs from container
kubectl logs nginx-simple

# Follow logs in real-time (like tail -f)
kubectl logs nginx-simple -f

# With timestamp
kubectl logs nginx-simple --timestamps=true

# From previous container (if it crashed and restarted)
kubectl logs nginx-simple --previous
```

**Expected Outcomes:**

- `kubectl logs` shows nginx startup messages
- nginx listens on port 80 (shown in logs)
- No error messages in logs

---

### Exercise 1.3: Execute Commands in a Pod (Pod Shell Access)

**Objective:** Learn to exec into a running Pod to inspect and debug applications.

**Instructions:**

1. Connect to the nginx Pod
2. Check nginx is actually running inside
3. Test curl to localhost:80 from inside Pod
4. Exit the Pod connection

**Verification Steps:**

```bash
# Open an interactive shell in the pod
kubectl exec -it nginx-simple -- /bin/sh

# From inside the pod, verify nginx is running
ps aux | grep nginx

# Test nginx is serving (from inside pod)
curl http://localhost:80

# Exit the shell
exit
```

**Expected Outcomes:**

- You can successfully connect to the Pod shell
- `ps aux` shows nginx master and worker processes
- `curl localhost:80` returns the default nginx welcome page (HTML)

---

### Exercise 1.4: Multi-Container Pod

**Objective:** Create a Pod with two containers that share network namespace.

**Instructions:**

1. Create a file `multi-container-pod.yaml`
2. Define a Pod with TWO containers:
   - Container 1: `web` - nginx:latest, port 80
   - Container 2: `sidecar` - busybox:latest
3. The sidecar container should run: `sleep 3600` (stay alive for 1 hour)
4. Apply the manifest
5. Exec into the sidecar and test connectivity to nginx

**Verification Steps:**

```bash
# View the pod
kubectl get pod multi-container-pod -o yaml | grep -A 2 containers:

# Describe pod - should show 2 containers
kubectl describe pod multi-container-pod

# Check logs from web container
kubectl logs multi-container-pod -c web

# Check logs from sidecar container
kubectl logs multi-container-pod -c sidecar

# Exec into sidecar container
kubectl exec -it multi-container-pod -c sidecar -- /bin/sh

# From inside sidecar, test nginx is accessible on localhost:80
curl http://localhost:80

# Exit
exit
```

**Expected Outcomes:**

- Pod has status "Running" with 2/2 containers ready
- Both containers share the same network namespace (can reach localhost)
- `curl localhost:80` from sidecar successfully returns nginx welcome page

**Key Learning:**

- Containers in same Pod share network namespace = can reach each other via localhost
- Each container needs `-c` flag to specify which container when using logs/exec
- Containers can have different images and purposes

---

### Exercise 1.5: Pod Restart Policy

**Objective:** Understand how Pod restart policies work.

**Instructions:**

1. Create a file `crash-pod.yaml`
2. Create a Pod that:
   - Image: `busybox:latest`
   - Command: `sh -c "echo 'Pod started'; sleep 5; exit 1"` (will crash after 5 seconds)
   - Name: `crash-demo`
   - Restart policy: `Always` (default)
3. Apply and watch what happens
4. Observe the restart count increasing

**Verification Steps:**

```bash
# Apply and immediately watch (opens new terminal)
kubectl apply -f crash-pod.yaml

# In another terminal, continuously watch the pod
watch kubectl get pods

# Or get status once
kubectl get pod crash-demo

# Check restart count and events
kubectl describe pod crash-demo

# View logs - see multiple startup attempts
kubectl logs crash-demo --all-containers=true
```

**Expected Outcomes:**

- Pod starts, runs for 5 seconds, exits with error code 1
- Status shows "CrashLoopBackOff" (backing off from constant restarts)
- Restart count increases (0, 1, 2, 3...)
- `kubectl describe` shows multiple "Killing container" events
- kubelet exponentially backs off restart attempts (5s, 10s, 20s, 40s, 80s, 160s)

**Key Learning:**

- `Always` restart policy = container is always restarted, even if exit code is 0
- `OnFailure` = container restarted only on non-zero exit
- `Never` = container never restarted
- CrashLoopBackOff = normal behavior when apps keep crashing

---

### Exercise 1.6: Cleanup

**Objective:** Properly delete resources.

**Instructions:**

1. Delete all Pods you created in this exercise

**Verification Steps:**

```bash
# Delete pods by filename
kubectl delete -f nginx-pod.yaml
kubectl delete -f multi-container-pod.yaml
kubectl delete -f crash-pod.yaml

# Or delete by name
kubectl delete pod nginx-simple
kubectl delete pod multi-container-pod
kubectl delete pod crash-demo

# Verify all are deleted
kubectl get pods
```

**Expected Outcomes:**

- All Pods are removed from cluster
- `kubectl get pods` returns empty (or just headers)

---

## 🧠 Key Concepts Explained

### What is a Pod?

- Smallest deployable unit in Kubernetes
- Wraps one or more containers (usually one)
- Containers in same Pod share:
  - Network namespace (same IP address, localhost access)
  - Storage volumes
  - Specifications (e.g., restart policy)

### Pod Lifecycle States

- **Pending**: Pod created, container image being pulled
- **Running**: All containers started and running
- **Succeeded**: All containers exited successfully (job pods)
- **Failed**: At least one container exited with error
- **CrashLoopBackOff**: Container keeps crashing and restarting
- **ImagePullBackOff**: Can't pull container image

### Restart Policies

- **Always** (default): Restart container if it exits, regardless of exit code
- **OnFailure**: Restart only if exit code is non-zero
- **Never**: Never restart

### Ephemeral Nature

- Pods are temporary - not meant to be long-lived
- If Pod dies, it's gone (no automatic resurrection)
- For long-lived applications, use Deployments (next exercise)
- Each Pod gets unique IP address when created, different IP when recreated

---

## 💡 Debugging Tips

| Issue                | Command to Debug                                      |
| -------------------- | ----------------------------------------------------- |
| Pod won't start      | `kubectl describe pod <name>` - check Events section  |
| App crashing         | `kubectl logs <name>` - see application errors        |
| Can't see app output | Check if app logs to stdout (not files)               |
| Pod stuck in Pending | Check `kubectl describe pod` for resource constraints |
| Need shell access    | `kubectl exec -it <pod> -- /bin/sh`                   |

---

## ✅ Exercise Completion Checklist

- [ ] Created and ran nginx-simple Pod
- [ ] Viewed logs with `kubectl logs`
- [ ] Executed interactive shell with `kubectl exec -it`
- [ ] Created multi-container Pod
- [ ] Verified multi-container sharing network namespace
- [ ] Observed restart policy in action
- [ ] Cleaned up all Pods
- [ ] Understand Pod is ephemeral
- [ ] Ready to move to Deployments

---

## 🎓 Next Steps

Once complete, move to `deployments/exercise.md` to learn how Deployments manage Pods reliably.

## 📚 Reference Templates

Check `/templates/pod-template.yaml` for boilerplate structure.
