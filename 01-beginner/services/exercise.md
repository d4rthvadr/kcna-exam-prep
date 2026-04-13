# Exercise: Services - Exposing Applications

## 📌 Problem Statement

Create and manage Services to expose Pods and Deployments. Services provide stable networking, DNS names, and load balancing for accessing applications. You'll learn the three main Service types and how they differ for different use cases.

## 🎯 Learning Objectives

By completing this exercise, you will be able to:

1. Create Services of different types (ClusterIP, NodePort, LoadBalancer)
2. Understand Service selectors and how they find backend Pods
3. Configure ports and targetPorts correctly
4. Test service connectivity from different locations
5. Understand DNS names for service discovery
6. Debug service connectivity issues

## 📝 Exercises

### Exercise 3.1: ClusterIP Service (Default)

**Objective:** Create the most common service type for internal communication.

**Prerequisites:** Deployment from Module 01 Module or create a fresh one:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web
        image: nginx:latest
        ports:
        - containerPort: 80
EOF
```

**Instructions:**

1. Create a file `clusterip-service.yaml`
2. Define a ClusterIP Service:
   - Name: `web-app-service`
   - Selector: `app: web-app` (matches deployment pods)
   - Port: `80`
   - TargetPort: `80`
   - Type: `ClusterIP` (or omit, it's default)
3. Apply the manifest

**Verification Steps:**

```bash
# View service
kubectl get services

# Get more details
kubectl get svc -o wide

# Describe service - shows selector, endpoints, ports
kubectl describe service web-app-service

# Check endpoints (should show Pod IPs)
kubectl get endpoints web-app-service

# Get service IP (ClusterIP)
kubectl get svc web-app-service -o jsonpath='{.spec.clusterIP}'

# Test service from within cluster
# Option 1: Use DNS name (pod-to-pod communication)
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -O- http://web-app-service:80

# Option 2: From within a pod
kubectl exec -it <pod-name> -- curl http://web-app-service:80

# Port forward to test from local machine
kubectl port-forward svc/web-app-service 8080:80
# Then in another terminal: curl http://localhost:8080
```

**Expected Outcomes:**

- Service is created with a stable ClusterIP (e.g., 10.96.0.100)
- Endpoints show the 3 Pod IPs and port 80
- Service is only accessible from within cluster (not from outside)
- DNS name `web-app-service` resolves inside cluster
- Requests to service IP:port are load-balanced to Pods
- curl returns nginx welcome page

**Key Learning:**

- **ClusterIP**: Internal-only, default type
- **Stable IP**: Service IP doesn't change (Pods IPs do)
- **DNS name**: `<service-name>` (same namespace), `<service-name>.<namespace>.svc.cluster.local` (any namespace)
- **Endpoints**: Real addresses service routes traffic to (Pod IPs)
- **Selector**: "Glue" connecting service to pods with matching labels

---

### Exercise 3.2: NodePort Service

**Objective:** Expose application on every node for external access.

**Instructions:**

1. Create a file `nodeport-service.yaml`
2. Define a NodePort Service for the same deployment:
   - Name: `web-app-nodeport`
   - Selector: `app: web-app`
   - Type: `NodePort`
   - Port: `80` (service port within cluster)
   - TargetPort: `80` (container port)
   - NodePort: `30080` (node port, must be 30000-32767)
3. Apply the manifest

**Verification Steps:**

```bash
# View service
kubectl get svc web-app-nodeport

# Get detailed info including node port
kubectl describe svc web-app-nodeport

# Get node(s) IP
kubectl get nodes -o wide

# Test from local machine (outside cluster)
# Replace NODE_IP with actual node IP from above
curl http://<NODE_IP>:30080

# If using Docker Desktop/minikube, get node IP differently
# Docker Desktop: localhost or 127.0.0.1
# Minikube: minikube ip
curl http://localhost:30080

# Port forward also works
kubectl port-forward svc/web-app-nodeport 8080:80
curl http://localhost:8080

# Check which pods are handling requests
kubectl logs -l app=web-app --tail=5
```

**Expected Outcomes:**

- Service shows Type=NodePort
- Endpoints section shows 3 Pod IPs and ports
- Service has both ClusterIP and NodePort
- External access via `<NodeIP>:<NodePort>` works
- Requests are load-balanced across Pods
- curl returns nginx welcome page

**NodePort in Detail:**

```
External request on port 30080 (node port)
    ↓
Node's port 30080 (open on all nodes)
    ↓
Service ClusterIP internal load balancing
    ↓
Round-robin to backend Pods on port 80
```

**Note:** NodePort service also gets a ClusterIP automatically (for internal access)

---

### Exercise 3.3: LoadBalancer Service

**Objective:** Use cloud provider load balancer for external access.

**Instructions:**

1. Create a file `loadbalancer-service.yaml`
2. Define a LoadBalancer Service:
   - Name: `web-app-lb`
   - Selector: `app: web-app`
   - Type: `LoadBalancer`
   - Port: `80`
   - TargetPort: `80`
3. Apply the manifest
4. Note: LoadBalancer type requires cloud provider support (AWS ELB, GCP LB, Azure LB, etc.)

**Verification Steps:**

```bash
# View service - note EXTERNAL-IP column
kubectl get svc web-app-lb

# If you have cloud provider support:
# - EXTERNAL-IP will be assigned (e.g., 203.0.113.25)
# - Test: curl http://<EXTERNAL-IP>

# If running locally (minikube, Docker Desktop):
# - EXTERNAL-IP will be stuck in <pending>
# - Use port-forward instead

# Describe service
kubectl describe svc web-app-lb

# Port forward if no external IP assigned
kubectl port-forward svc/web-app-lb 8080:80
curl http://localhost:8080
```

**Expected Outcomes (with cloud provider):**

- Service shows Type=LoadBalancer
- EXTERNAL-IP shows cloud provider's load balancer IP
- Can access service from anywhere on that IP

**Expected Outcomes (local cluster):**

- Service shows Type=LoadBalancer
- EXTERNAL-IP is `<pending>` (normal, no cloud provider to provision)
- service still accessible via port-forward or NodePort
- You can still verify functionality locally

**LoadBalancer Details:**

```
Cloud Load Balancer (e.g., AWS ELB) on port 80
    ↓ (public IP, cloud provider manages)
Every Node's high port (e.g., 30123)
    ↓
Service ClusterIP internal load balancing
    ↓
Backend Pods on port 80
```

**Key Learning:**

- LoadBalancer creates NodePort automatically
- Requires cloud load balancer provisioning
- Most expensive option (cloud provider charges)
- Commonly used in production for public APIs

---

### Exercise 3.4: Service Discovery via DNS

**Objective:** Understand how Services enable DNS-based discovery.

**Instructions:**

1. Use existing web-app service and deployment
2. Create a test pod
3. Use different DNS names to access service

**Verification Steps:**

```bash
# Create a test pod in default namespace
kubectl run test-client --image=busybox --command sleep 3600 --rm -it

# From within the test pod, try different DNS names

# Short name (same namespace)
nslookup web-app-service

# Fully qualified (any namespace)
nslookup web-app-service.default.svc.cluster.local

# Try curl with DNS name
wget -O- http://web-app-service:80

# Try with full DNS name
wget -O- http://web-app-service.default.svc.cluster.local:80

# Exit pod
exit
```

**Expected Outcomes:**

- `nslookup` returns service IP (ClusterIP)
- Both short and fully-qualified DNS names work
- Pods can reach service by name without knowing IP
- Service name is stable (IP can change, name doesn't)

**DNS Behavior:**

- **Short name** (`web-app-service`): Works only from same namespace
- **FQDN** (`web-app-service.default.svc.cluster.local`): Works from any namespace
- **IP address**: Service's ClusterIP, assigned at creation
- **Resolution**: CoreDNS component (usually in kube-system namespace)

---

### Exercise 3.5: Port and TargetPort Configuration

**Objective:** Understand port vs targetPort mapping.

**Instructions:**

1. Create a file `port-mapping-service.yaml`
2. Create a service with different port and targetPort:
   - Port: `8080` (service port in cluster)
   - TargetPort: `80` (application port in containers)
3. This allows accessing nginx on port 8080

**Create the service:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-portmap
spec:
  selector:
    app: web-app
  type: ClusterIP
  ports:
    - name: http
      port: 8080 # What clients use
      targetPort: 80 # What app listens on
      protocol: TCP
```

**Verification Steps:**

```bash
# Apply service
kubectl apply -f port-mapping-service.yaml

# Check service
kubectl get svc web-app-portmap

# Describe to see port mapping
kubectl describe svc web-app-portmap

# Test from a pod - use port 8080
kubectl run test --image=busybox --rm -it -- wget -O- http://web-app-portmap:8080

# Port forward on different ports
kubectl port-forward svc/web-app-portmap 9090:8080
curl http://localhost:9090
```

**Expected Outcomes:**

- Service Port is 8080 (service network)
- TargetPort is 80 (application)
- Clients connect to port 8080
- Service automatically routes to port 80 on Pods
- Works without any changes to application

**Port Mapping Analogy:**

```
Client (cluster) request to web-app-portmap:8080
    ↓
Service receives on port 8080
    ↓
Service forwards to Pod on port 80
    ↓
Application listens on port 80
```

**Use Case:** When you want to expose on different ports than application uses

---

### Exercise 3.6: Label Mismatches and Debugging

**Objective:** Troubleshoot when services can't find Pods.

**Instructions:**

1. Create a service with incorrect selector
2. Observe no endpoints
3. Fix the selector
4. Verify endpoints appear

**Verification Steps:**

```bash
# Create a service with WRONG selector
cat > wrong-selector-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: wrong-service
spec:
  selector:
    app: nonexistent-app  # Wrong label!
  ports:
  - port: 80
    targetPort: 80
EOF

kubectl apply -f wrong-selector-service.yaml

# View service - note Endpoints
kubectl get svc wrong-service
kubectl describe svc wrong-service  # Shows "Endpoints: <none>"

# This is the problem - no pods match the selector

# Fix by updating selector to correct label
kubectl patch service wrong-service -p '{"spec":{"selector":{"app":"web-app"}}}'

# Or edit manually
kubectl edit svc wrong-service

# Now endpoints should appear
kubectl describe svc wrong-service

# Endpoints section should show pod IPs now
kubectl get endpoints wrong-service
```

**Expected Outcomes:**

- Initially: Service exists but Endpoints is empty
- Service works but requests fail (no pods to send to)
- After fix: Endpoints populated with pod information
- Service then works normally

**Debugging Checklist:**

```bash
# 1. Check service exists and has correct selector
kubectl describe svc <name>

# 2. Check endpoints populated
kubectl get endpoints <name>

# 3. Check pods with correct labels exist
kubectl get pods -l app=web-app

# 4. Check ports match (service port to pod containerPort)
kubectl get svc <name> -o yaml | grep port
kubectl get pods -o yaml | grep containerPort

# 5. Check network policy rules (if applicable)
kubectl get networkpolicies
```

---

### Exercise 3.7: Cleanup

**Objective:** Delete services properly.

**Verification Steps:**

```bash
# Delete all services created
kubectl delete svc web-app-service
kubectl delete svc web-app-nodeport
kubectl delete svc web-app-lb
kubectl delete svc web-app-portmap
kubectl delete svc wrong-service

# Delete the deployment
kubectl delete deployment web-app

# Verify cleanup
kubectl get svc
kubectl get deployments
kubectl get pods
```

**Expected Outcomes:**

- All services and deployments removed
- No resources remaining

---

## 🧠 Key Concepts Explained

### Service Types Comparison

| Type            | ClusterIP     | NodePort                  | LoadBalancer                         |
| --------------- | ------------- | ------------------------- | ------------------------------------ |
| **Scope**       | Internal only | Internal + Node           | Internal + External                  |
| **Access From** | Other pods    | Pods + Nodes + External\* | Pods + Nodes + External IP           |
| **IP Type**     | Cluster IP    | Cluster IP + Node port    | Cluster IP + Node port + External IP |
| **Cost**        | Free          | Free                      | Paid (cloud LB)                      |
| **Use Case**    | Internal APIs | Dev/test                  | Production APIs                      |

\*External access to NodePort depends on network access to nodes

### How Service Load Balancing Works

```
Service (10.96.0.5) port 80
  ↓ (round-robin)
  ├→ Pod A (10.244.0.1:80) - 25% of requests
  ├→ Pod B (10.244.0.2:80) - 25% of requests
  └→ Pod C (10.244.0.3:80) - 25% of requests
```

- By default: round-robin
- Can change with sessionAffinity (sticky sessions)

### Service Discovery Methods

**DNS (preferred):**

```bash
# From within cluster
curl http://service-name:port
curl http://service-name.namespace.svc.cluster.local:port
```

**Environment Variables:**

```bash
# Kubernetes injects into every Pod
# Format: <SERVICE_NAME>_SERVICE_HOST and SERVICE_PORT
curl http://$WEB_APP_SERVICE_SERVICE_HOST:$WEB_APP_SERVICE_SERVICE_PORT
```

DNS is preferred (service can be created after pods).

---

## 💡 Debugging Tips

| Issue                    | Debug Command                                                    |
| ------------------------ | ---------------------------------------------------------------- |
| Service has no endpoints | `kubectl get endpoints <svc>` - should list pod IPs              |
| Requests to service fail | `kubectl describe svc <svc>` - verify selector labels            |
| Can't reach from outside | `kubectl get svc` - check Type and External IP                   |
| Port not accessible      | `kubectl describe svc` - verify port and targetPort              |
| Connection refused       | Check if app is listening on targetPort: `kubectl logs <pod>`    |
| Slow requests            | Check endpoints - possible uneven distribution or network issues |

---

## ✅ Exercise Completion Checklist

- [ ] Created ClusterIP service and tested internal access
- [ ] Created NodePort service and tested from outside cluster
- [ ] Created LoadBalancer service (understand pending state)
- [ ] Tested DNS service discovery
- [ ] Used different port/targetPort mappings
- [ ] Debugged services with empty endpoints
- [ ] Cleaned up all services
- [ ] Understand service selectors match pods to backends
- [ ] Understand three service types and use cases
- [ ] Ready to move to Module 02

---

## 🎓 Next Steps

Once complete, move to **Module 02** (`02-intermediate/configmaps-secrets/exercise.md`) to learn configuration management.

## 📚 Reference Templates

Check `/templates/service-template.yaml` for boilerplate with all three service types.
