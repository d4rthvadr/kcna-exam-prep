# Network Policies Exercises

## Module Overview

This exercise set covers Kubernetes NetworkPolicies—the mechanism for controlling traffic between pods and external endpoints. You'll create NetworkPolicies to allow/deny ingress and egress traffic, use label selectors for pod targeting, restrict traffic by namespace, implement CIDR-based restrictions, and test policies with traffic generation. NetworkPolicies are critical for microsegmentation and security hardening (KCNA domain: Cloud Native Security & Networking).

---

## Exercise 2.1: Create a Basic NetworkPolicy with Ingress Rules

**Problem Statement:**
You have a web application running in a pod labeled `app=web` and a database running in a pod labeled `app=database`. Network traffic in your cluster is open by default (no restrictions). Implement a NetworkPolicy to allow only web pods to access the database pod on port 5432. All other traffic to the database should be denied.

**Learning Objectives:**

- Understand NetworkPolicy structure (podSelector, ingress/egress rules)
- Implement label-based pod selection
- Create ingress rules to allow traffic from specific pods
- Understand default deny behavior

**Instructions:**

1. Create test pods for the scenario:

```bash
# Create a namespace for the exercise
kubectl create namespace network-policy-demo

# Create database pod
kubectl run database --image=postgres:latest --labels app=database -n network-policy-demo
# Note: This will fail to start (postgres needs config), but that's OK for testing traffic

# Create web pod
kubectl run web --image=nginx --labels app=web -n network-policy-demo

# Create a client pod for testing
kubectl run client --image=busybox --labels app=client -n network-policy-demo -- sleep 3600
```

2. Create a NetworkPolicy to allow only web pods to access the database:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-allow-web
  namespace: network-policy-demo
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: web
      ports:
        - protocol: TCP
          port: 5432
```

Save as `networkpolicy-database-allow-web.yaml` and apply:

```bash
kubectl apply -f networkpolicy-database-allow-web.yaml
```

3. Verify the NetworkPolicy was created:

```bash
kubectl get networkpolicy -n network-policy-demo
kubectl describe networkpolicy database-allow-web -n network-policy-demo
```

**Verification Steps:**

```bash
# Confirm NetworkPolicy exists
kubectl get networkpolicy -n network-policy-demo
# Should list: database-allow-web

# Check the policy details
kubectl get networkpolicy database-allow-web -n network-policy-demo -o yaml

# Verify podSelector matches database pods
kubectl get pods -n network-policy-demo -l app=database --show-labels
```

**Expected Outcomes:**

- NetworkPolicy `database-allow-web` created in network-policy-demo namespace
- podSelector targets pods with label `app: database`
- policyTypes includes `Ingress`
- Ingress rule allows traffic from `app: web` pods on port 5432
- Other pods (like `app: client`) are denied traffic to database pod

**Key Learning Concepts:**

- **NetworkPolicy Structure**:
  - `podSelector`: Identifies target pods (pods that the policy applies to)
  - `ingress`: Rules for inbound traffic
  - `egress`: Rules for outbound traffic
  - `policyTypes`: Specifies which types (Ingress, Egress) are handled
- **Default Deny**: Specifying a policyType implicitly denies all traffic of that type not explicitly allowed
- **Label Selectors**: Use matchLabels for simple label matching; matchExpressions for complex logic
- **Empty `from` field**: Means "allow from all pods"
- **No ingress rules**: Denies all ingress traffic
- **No egress rules**: Denies all egress traffic

---

## Exercise 2.2: Implement Egress Rules and Default Deny-All Policy

**Problem Statement:**
Your organization requires that pods can only communicate with other pods and services within the cluster (Egress). Pods should not be able to access external networks or the internet. Create a NetworkPolicy that denies all egress traffic by default and allows only pod-to-pod communication.

**Learning Objectives:**

- Understand egress rules and outbound traffic control
- Implement default-deny NetworkPolicies
- Allow cluster-internal traffic while blocking external access
- Understand the impact of egress rules on pod communication

**Instructions:**

1. Create a namespace and test pods:

```bash
kubectl create namespace egress-demo

# Create pods that will communicate
kubectl run server --image=nginx --labels app=server -n egress-demo
kubectl run client --image=nicolaka/netcat --labels app=client -n egress-demo -- sleep 3600
```

2. Create a default-deny NetworkPolicy for the namespace:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: egress-demo
spec:
  podSelector: {} # Applies to all pods
  policyTypes:
    - Egress
  egress: [] # No rules = deny all egress
```

Apply:

```bash
kubectl apply -f networkpolicy-default-deny-egress.yaml
```

3. Create a NetworkPolicy to allow cluster-internal communication (DNS + pod-to-pod):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-cluster-internal
  namespace: egress-demo
spec:
  podSelector: {} # Applies to all pods
  policyTypes:
    - Egress
  egress:
    # Allow DNS to cluster DNS service
    - to:
        - podSelector:
            matchLabels:
              k8s-app: kube-dns
          namespaceSelector:
            matchLabels:
              name: kube-system
      ports:
        - protocol: UDP
          port: 53
    # Allow pod-to-pod communication within namespace
    - to:
        - podSelector: {} # Any pod in this namespace
      ports:
        - protocol: TCP
          port: 80
        - protocol: TCP
          port: 443
```

Apply:

```bash
kubectl apply -f networkpolicy-allow-cluster-internal.yaml
```

4. Verify the policies:

```bash
kubectl get networkpolicy -n egress-demo
kubectl describe networkpolicy default-deny-egress -n egress-demo
kubectl describe networkpolicy allow-cluster-internal -n egress-demo
```

**Verification Steps:**

```bash
# List all NetworkPolicies
kubectl get networkpolicy -n egress-demo

# Verify pod-to-pod communication fails initially (before allow-cluster-internal)
# (This would require actual traffic testing)

# Check that both policies are applied
kubectl get networkpolicy default-deny-egress -n egress-demo -o yaml
kubectl get networkpolicy allow-cluster-internal -n egress-demo -o yaml
```

**Expected Outcomes:**

- `default-deny-egress` created with empty egress array (denies all)
- `allow-cluster-internal` created to permit specific egress rules
- Pods can communicate with DNS for name resolution
- Pods can communicate with other pods on ports 80, 443
- External internet access is blocked

**Key Learning Concepts:**

- **Empty podSelector `{}`**: Applies policy to all pods in namespace
- **Empty egress array `[]`**: Deny all egress traffic
- **DNS Communication**: Egress to kube-dns pod on port 53 (UDP) is required for pod discovery
- **Multiple Rules**: If any rule matches, traffic is allowed (OR logic)
- **Namespace Isolation**: CIDR blocks can restrict traffic; namespaceSelector limits scope
- **Port Specification**: Can specify single port or range; omitting allows all ports
- **Principle**: Default-deny policies increase security at cost of more explicit rules

---

## Exercise 2.3: Network Policy with Namespace Selectors

**Problem Statement:**
Your cluster has multiple namespaces. A microservices application spans `app-namespace` (where app pods run) and `db-namespace` (where database pods run). Create NetworkPolicies in the `db-namespace` to allow only pods from `app-namespace` to access the database on port 5432, while denying pods from other namespaces.

**Learning Objectives:**

- Use namespaceSelector to allow traffic between namespaces
- Implement cross-namespace NetworkPolicies
- Label namespaces for network policy targeting
- Understand namespace-based segmentation

**Instructions:**

1. Create two namespaces and label them:

```bash
kubectl create namespace app-namespace
kubectl create namespace db-namespace

# Label the namespaces for selection
kubectl label namespace app-namespace name=app-namespace
kubectl label namespace db-namespace name=db-namespace
```

2. Verify namespace labels:

```bash
kubectl get namespace --show-labels
# Both should show their respective labels
```

3. Create pods in each namespace:

```bash
# App pods in app-namespace
kubectl run app-server --image=nginx --labels app=app-service -n app-namespace

# Database pod in db-namespace
kubectl run database --image=postgres:latest --labels app=database -n db-namespace

# Additional pod in different namespace to test denial
kubectl create namespace other-namespace
kubectl label namespace other-namespace name=other-namespace
kubectl run other-client --image=busybox --labels app=client -n other-namespace -- sleep 3600
```

4. Create a NetworkPolicy in db-namespace allowing only app-namespace pods:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-app-namespace
  namespace: db-namespace
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: app-namespace
      ports:
        - protocol: TCP
          port: 5432
```

Apply:

```bash
kubectl apply -f networkpolicy-allow-from-app-namespace.yaml
```

5. Verify the policy:

```bash
kubectl get networkpolicy -n db-namespace
kubectl describe networkpolicy allow-from-app-namespace -n db-namespace
```

**Verification Steps:**

```bash
# Confirm NetworkPolicy was created
kubectl get networkpolicy -n db-namespace

# Verify namespace labels
kubectl get namespace --show-labels | grep -E "app-namespace|db-namespace|other-namespace"

# Check the policy details
kubectl get networkpolicy allow-from-app-namespace -n db-namespace -o yaml
# Should show namespaceSelector with name=app-namespace
```

**Expected Outcomes:**

- Both namespaces created and labeled appropriately
- Database pod created in db-namespace
- App pod created in app-namespace
- NetworkPolicy allows pods from app-namespace (by label selector)
- NetworkPolicy denies pods from other-namespace
- Traffic from app-namespace pods to database is allowed on port 5432

**Key Learning Concepts:**

- **namespaceSelector**: Target pods by their namespace's labels
- **Namespace Labeling**: Namespaces must be labeled for selection (not auto-labeled)
- **Cross-Namespace Access**: Combine podSelector and namespaceSelector in `from` clause
- **Deny Other Namespaces**: Not explicitly allowing them means they're denied
- **Common Patterns**:
  - Separate database namespace from application namespace
  - Use consistent namespace labels (e.g., `name=<namespace-name>`)
  - Allow ingress from specific namespaces; default-deny others

---

## Exercise 2.4: Advanced Ingress/Egress with CIDR Blocks

**Problem Statement:**
Your organization has external API servers that pods need to access (e.g., external SaaS APIs). You want to allow pods to access these external services via egress rules, but restrict access to specific IP ranges (CIDR blocks) for security. Create a NetworkPolicy with CIDR-based egress rules and a corresponding ingress policy for external traffic.

**Learning Objectives:**

- Use CIDR blocks in NetworkPolicy rules
- Implement egress rules for external service access
- Understand the difference between podSelector and ipBlock
- Control traffic to/from external networks

**Instructions:**

1. Create a test namespace:

```bash
kubectl create namespace external-api-demo
```

2. Create a pod that needs external access:

```bash
kubectl run app --image=nicolaka/netcat --labels app=app-service -n external-api-demo -- sleep 3600
```

3. Create a NetworkPolicy allowing egress to an external API (example: publicly known IP range):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-api
  namespace: external-api-demo
spec:
  podSelector:
    matchLabels:
      app: app-service
  policyTypes:
    - Egress
  egress:
    # Allow DNS for service discovery
    - to:
        - namespaceSelector:
            matchLabels:
              name: kube-system
      ports:
        - protocol: UDP
          port: 53
    # Allow traffic to external API (example: 8.8.8.0/24)
    - to:
        - ipBlock:
            cidr: 8.8.8.0/24
            except:
              - 8.8.8.1/32 # Block specific IPs if needed
      ports:
        - protocol: TCP
          port: 443
        - protocol: TCP
          port: 80
```

Apply:

```bash
kubectl apply -f networkpolicy-allow-external-api.yaml
```

4. Also allow outbound to other pods in cluster (if needed):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-internal-egress
  namespace: external-api-demo
spec:
  podSelector:
    matchLabels:
      app: app-service
  policyTypes:
    - Egress
  egress:
    # Allow pod-to-pod communication
    - to:
        - podSelector: {}
```

Apply:

```bash
kubectl apply -f networkpolicy-allow-internal-egress.yaml
```

5. Verify the policies:

```bash
kubectl get networkpolicy -n external-api-demo
kubectl describe networkpolicy allow-external-api -n external-api-demo
```

**Verification Steps:**

```bash
# Confirm NetworkPolicies created
kubectl get networkpolicy -n external-api-demo

# Check CIDR block in policy
kubectl get networkpolicy allow-external-api -n external-api-demo -o yaml
# Should show ipBlock with CIDR 8.8.8.0/24

# Check except clause (excluded IPs)
kubectl get networkpolicy allow-external-api -n external-api-demo -o yaml
# Should show except: ["8.8.8.1/32"]
```

**Expected Outcomes:**

- NetworkPolicy `allow-external-api` created with ipBlock rules
- ipBlock specifies CIDR 8.8.8.0/24
- except clause blocks 8.8.8.1/32
- Pods can access external APIs on ports 80, 443
- DNS resolution works (port 53)
- Communication restricted to specified IP ranges

**Key Learning Concepts:**

- **ipBlock**: For external IP ranges (not pod labels)
- **except Clause**: Exclude specific IPs from CIDR block
- **DNS Requirement**: Pods still need DNS access (port 53 UDP) to kube-dns
- **Egress Defaults**: If egress policyType is set, must explicitly allow needed traffic
- **CIDR Notation**: /24 = 256 IPs, /32 = single IP, /0 = entire internet (dangerous)
- **Common Mistakes**: Forgetting to allow DNS, using /0 for entire internet (should be specific ranges)

---

## Exercise 2.5: NetworkPolicy Debugging and Traffic Testing

**Problem Statement:**
A developer reports that their pod can't communicate with a service they expect to reach. Use NetworkPolicy debugging techniques to identify whether the issue is related to network policies or other connectivity problems. Create scenarios with intentionally restrictive policies and debug them.

**Learning Objectives:**

- Debug NetworkPolicy issues with kubectl commands
- Use port-forward for testing
- Understand how to trace traffic using pod logs
- Identify common NetworkPolicy mistakes

**Instructions:**

1. Create a test namespace and pods:

```bash
kubectl create namespace debug-demo
kubectl run server --image=nginx --labels app=server -n debug-demo
kubectl run client --image=nicolaka/netcat --labels app=client -n debug-demo -- sleep 3600
```

2. Create an initially restrictive NetworkPolicy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-all
  namespace: debug-demo
spec:
  podSelector: {} # All pods
  policyTypes:
    - Ingress
  ingress: [] # No rules = deny all
```

Apply:

```bash
kubectl apply -f networkpolicy-restrict-all.yaml
```

3. Test connectivity (should fail):

```bash
# Get the server pod's IP
SERVER_IP=$(kubectl get pod server -n debug-demo -o jsonpath='{.status.podIP}')

# Try to reach the server from client (should fail/timeout)
kubectl exec -it client -n debug-demo -- nc -zv $SERVER_IP 80
# Expected: timeout or connection refused
```

4. Debug the issue:

```bash
# Check which NetworkPolicies apply to the server pod
kubectl get networkpolicy -n debug-demo

# Check the server pod's labels
kubectl get pod server -n debug-demo --show-labels

# Check the policy details
kubectl describe networkpolicy restrict-all -n debug-demo
```

5. Fix the policy by allowing ingress from client pods:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-all
  namespace: debug-demo
spec:
  podSelector: {} # All pods
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
```

Apply the fix:

```bash
kubectl apply -f networkpolicy-restrict-all.yaml
```

6. Test connectivity again (should now succeed):

```bash
# Try to reach the server from client (should now work)
kubectl exec -it client -n debug-demo -- nc -zv $SERVER_IP 80
# Expected: successfully connected or response from nginx
```

**Verification Steps:**

```bash
# Before fix: connection denied
SERVER_IP=$(kubectl get pod server -n debug-demo -o jsonpath='{.status.podIP}')
kubectl exec -it client -n debug-demo -- timeout 5 nc -zv $SERVER_IP 80
# Should timeout or fail

# After fix: connection succeeds
kubectl exec -it client -n debug-demo -- timeout 5 nc -zv $SERVER_IP 80
# Should show: succeeded or Connection succeeded

# Verify pod labels match the policy
kubectl get pod client -n debug-demo --show-labels
# Should show: app=client
```

**Expected Outcomes:**

- First connectivity test fails (NetworkPolicy denies traffic)
- Debugging identifies restrict-all policy with no ingress rules
- Updating policy to allow app=client pods fixes connectivity
- Second connectivity test succeeds
- Client can reach server on port 80

**Key Learning Concepts:**

- **Debugging Process**:
  1. Check which NetworkPolicies exist in the namespace: `kubectl get networkpolicy`
  2. Check pod labels: `kubectl get pod --show-labels`
  3. Check policy details: `kubectl describe networkpolicy`
  4. Test connectivity: `kubectl exec pod -- nc` or `curl`
  5. Review policy rules for gaps

- **Testing Tools**:
  - `nc -zv <ip> <port>`: Test TCP connectivity
  - `curl http://<ip>`: Test HTTP connectivity
  - `kubectl logs pod`: Check application logs
  - `kubectl exec pod -- ping`: Test ICMP (not usually allowed by NetworkPolicy)

- **Common Issues**:
  - Pod labels don't match podSelector in policy
  - Policy specifies wrong ports or protocols
  - Namespace labels missing on target namespace
  - DNS not allowed (port 53 UDP to kube-dns)
  - Missing allow-all Egress (implicit deny assumes policyType=Egress)

---

## Exercise 2.6: Deny-All and Selective Allow Patterns

**Problem Statement:**
Your organization wants to implement a zero-trust security model where all traffic is denied by default and only explicitly allowed communication is permitted. Implement a namespace-wide default-deny NetworkPolicy and then selectively allow specific pod-to-pod communication.

**Learning Objectives:**

- Implement default-deny patterns for security
- Use multiple NetworkPolicies to build complex authorization
- Understand pod service discovery under deny-all
- Apply principle of least privilege at network level

**Instructions:**

1. Create a test namespace with multiple tiers:

```bash
kubectl create namespace zero-trust-demo

# Create frontend pods
kubectl run frontend --image=nginx --labels tier=frontend -n zero-trust-demo

# Create backend pods
kubectl run backend --image=nginx --labels tier=backend -n zero-trust-demo

# Create database pods
kubectl run database --image=postgres:latest --labels tier=database -n zero-trust-demo
```

2. Create a default-deny for all ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: zero-trust-demo
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

Apply:

```bash
kubectl apply -f networkpolicy-default-deny-ingress.yaml
```

3. Create NetworkPolicy allowing frontend-to-backend communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: zero-trust-demo
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              tier: frontend
      ports:
        - protocol: TCP
          port: 80
```

Apply:

```bash
kubectl apply -f networkpolicy-allow-frontend-to-backend.yaml
```

4. Create NetworkPolicy allowing backend-to-database communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: zero-trust-demo
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              tier: backend
      ports:
        - protocol: TCP
          port: 5432
```

Apply:

```bash
kubectl apply -f networkpolicy-allow-backend-to-database.yaml
```

5. Verify the policies:

```bash
kubectl get networkpolicy -n zero-trust-demo
kubectl describe networkpolicy default-deny-ingress -n zero-trust-demo
```

**Verification Steps:**

```bash
# List all NetworkPolicies
kubectl get networkpolicy -n zero-trust-demo

# Confirm default-deny-ingress has no ingress rules
kubectl get networkpolicy default-deny-ingress -n zero-trust-demo -o yaml
# Should show: ingress: [] (empty array)

# Confirm allow policies are created
kubectl get networkpolicy allow-frontend-to-backend -n zero-trust-demo
kubectl get networkpolicy allow-backend-to-database -n zero-trust-demo

# Verify tier labels on pods
kubectl get pods -n zero-trust-demo --show-labels
```

**Expected Outcomes:**

- Default-deny-ingress applied to all pods (no ingress rules)
- Frontend-to-backend communication allowed on port 80
- Backend-to-database communication allowed on port 5432
- Frontend cannot access database directly
- Database cannot initiate connections to other tiers
- Zero-trust security model enforced

**Key Learning Concepts:**

- **Default-Deny Pattern**: Start with deny-all, whitelist allowed traffic
- **Multiple Policies**: Multiple allow policies are combined (OR logic)
- **No Implicit Trust**: Communication must be explicitly allowed in both directions if egress is also restricted
- **Tier-Based Access**: Can model multi-tier architectures (frontend → backend → database)
- **Security Benefits**: Reduced attack surface, clear policies, easier auditing
- **Complexity Trade-off**: More policies to maintain, requires careful planning

---

## Exercise 2.7: Cleanup

**Problem Statement:**
Remove all NetworkPolicies and test namespaces created in this exercise set to clean up the cluster.

**Instructions:**

Remove all test namespaces (this automatically removes NetworkPolicies and pods in each namespace):

```bash
kubectl delete namespace network-policy-demo
kubectl delete namespace egress-demo
kubectl delete namespace app-namespace
kubectl delete namespace db-namespace
kubectl delete namespace other-namespace
kubectl delete namespace external-api-demo
kubectl delete namespace debug-demo
kubectl delete namespace zero-trust-demo
```

If you prefer to remove individual resources:

```bash
# Remove NetworkPolicies from network-policy-demo
kubectl delete networkpolicy database-allow-web -n network-policy-demo

# Remove namespaces
kubectl delete namespace network-policy-demo egress-demo app-namespace db-namespace other-namespace external-api-demo debug-demo zero-trust-demo
```

**Verification Steps:**

```bash
# Verify namespaces are gone
kubectl get namespace | grep -E "network-policy-demo|egress-demo|app-namespace|db-namespace|other-namespace|external-api-demo|debug-demo|zero-trust-demo"
# Should return nothing

# Confirm NetworkPolicies are removed
kubectl get networkpolicy --all-namespaces
# Should show no custom policies
```

**Expected Outcomes:**

- All test namespaces removed
- All custom NetworkPolicies removed
- All test pods removed
- Cluster returned to clean state

---

## Module Completion Checklist

- [ ] Completed Exercise 2.1: Basic NetworkPolicy with ingress rules
- [ ] Completed Exercise 2.2: Egress rules and default-deny policies
- [ ] Completed Exercise 2.3: Namespace selectors for cross-namespace traffic
- [ ] Completed Exercise 2.4: CIDR blocks and external API access
- [ ] Completed Exercise 2.5: NetworkPolicy debugging and traffic testing
- [ ] Completed Exercise 2.6: Deny-all and selective allow patterns
- [ ] Completed Exercise 2.7: Cleanup

## Key Takeaways

1. **NetworkPolicy Structure**:
   - `podSelector`: Defines target pods (pods the policy applies to)
   - `ingress`/`egress`: Traffic rules
   - `policyTypes`: Specifies direction (Ingress, Egress, or both)

2. **Selection Options**:
   - `podSelector`: By pod labels in same namespace
   - `namespaceSelector`: By namespace labels
   - `ipBlock`: By external CIDR blocks

3. **Default Behavior**:
   - No NetworkPolicy = allow all traffic
   - NetworkPolicy with empty rules = deny traffic of specified policyType
   - Multiple policies on same pod = combined (OR logic)

4. **Best Practices**:
   - Implement default-deny for security-sensitive namespaces
   - Use selectors instead of CIDR for internal pods (labels are more maintainable)
   - Allow DNS (port 53 UDP) when restricting egress
   - Document traffic expectations clearly
   - Test policies before rolling out

5. **Common Patterns**:
   - Default-deny-all + whitelist allowed traffic
   - Tier-based segmentation (frontend → backend → database)
   - Cross-namespace access via namespaceSelector
   - External API access via ipBlock

6. **Testing & Debugging**:
   - Use `kubectl exec -- nc` to test connectivity
   - Check pod labels match policy selectors: `kubectl get pod --show-labels`
   - Review policy rules: `kubectl describe networkpolicy`
   - Test before/after to validate policy changes

## Useful Commands Reference

```bash
# Create NetworkPolicy
kubectl apply -f networkpolicy.yaml

# Get NetworkPolicies
kubectl get networkpolicy
kubectl get networkpolicy -n <namespace>

# Describe NetworkPolicy
kubectl describe networkpolicy <name> -n <namespace>

# Get detailed YAML
kubectl get networkpolicy <name> -n <namespace> -o yaml

# Delete NetworkPolicy
kubectl delete networkpolicy <name> -n <namespace>

# Test connectivity from pod
kubectl exec -it <pod> -n <namespace> -- nc -zv <ip> <port>
kubectl exec -it <pod> -n <namespace> -- curl http://<ip>:<port>

# Get pod IP for testing
kubectl get pod <name> -n <namespace> -o jsonpath='{.status.podIP}'

# Check pod labels
kubectl get pod <name> -n <namespace> --show-labels

# Check namespace labels
kubectl get namespace <name> --show-labels

# Label namespace (required for namespaceSelector)
kubectl label namespace <name> <key>=<value>
```

---

**Next Steps:** Complete Module 04 RBAC exercises, then proceed to Module 05 (Expert II - Operations & Observability).
