# RBAC (Role-Based Access Control) Exercises

## Module Overview

This exercise set covers Kubernetes RBAC implementation—the mechanism for controlling access to API resources. You'll create ServiceAccounts, define Roles/RoleBindings for namespace-scoped access, ClusterRoles/ClusterRoleBindings for cluster-wide access, and use `kubectl auth can-i` for permission verification. RBAC is critical for multi-tenant clusters and security audits (KCNA domain: Cloud Native Application Delivery & Security).

---

## Exercise 1.1: Create and Manage ServiceAccounts

**Problem Statement:**
Your development team needs to create application-specific service accounts instead of using the default service account. Create a ServiceAccount named `app-reader` in the default namespace that will be used by a deployment. Verify it exists and inspect its associated secrets.

**Learning Objectives:**

- Understand ServiceAccount creation and purpose
- Inspect token and CA certificate associated with a ServiceAccount
- Know when to use custom ServiceAccounts vs. default

**Instructions:**

1. Create a ServiceAccount named `app-reader`:

```bash
kubectl create serviceaccount app-reader
```

2. Verify the ServiceAccount was created:

```bash
kubectl get serviceaccount app-reader
kubectl describe serviceaccount app-reader
```

3. Inspect the secret that contains the token:

```bash
# Get the secret name from the token name shown in describe output
kubectl get secret <token-secret-name> -o yaml
```

4. Extract and decode the service account token (for learning purposes):

```bash
kubectl get secret <token-secret-name> -o jsonpath='{.data.token}' | base64 -d | head -c 50
```

5. Clean up (don't delete, we'll use this ServiceAccount in Exercise 1.2).

**Verification Steps:**

```bash
# Confirm ServiceAccount exists
kubectl get serviceaccount app-reader

# Confirm token secret exists
TOKENSECRET=$(kubectl get serviceaccount app-reader -o jsonpath='{.secrets[0].name}')
kubectl get secret $TOKENSECRET

# Verify token is present
kubectl get secret $TOKENSECRET -o jsonpath='{.data.token}' | wc -c
# Should output 1356 or similar (a long encoded token)
```

**Expected Outcomes:**

- ServiceAccount `app-reader` is visible in `kubectl get serviceaccount`
- Token secret is automatically created with the ServiceAccount
- Token secret contains three keys: `ca.crt`, `namespace`, `token`
- Token decodes successfully from base64

**Key Learning Concepts:**

- ServiceAccounts are Kubernetes identities for applications/pods
- Each ServiceAccount automatically gets a token for API authentication
- ServiceAccountTokens are mounted as volumes in pods
- Default ServiceAccount is used if no ServiceAccount is specified
- Custom ServiceAccounts enable fine-grained access control

---

## Exercise 1.2: Implement a Role and RoleBinding

**Problem Statement:**
The `app-reader` service account needs permission to read Pods, Deployments, and Services in the default namespace, but should not have permission to modify or delete them. Create a Role with appropriate read-only permissions and bind it to the ServiceAccount using a RoleBinding.

**Learning Objectives:**

- Understand Role definition with verbs and API groups
- Implement RoleBinding to grant Role permissions to a ServiceAccount
- Understand namespace-scoped RBAC (Roles are namespace-specific)

**Instructions:**

1. Create a Role named `pod-reader` using a manifest or imperative command. Using manifest (recommended):

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list", "watch"]
```

Save this as `role-pod-reader.yaml` and apply:

```bash
kubectl apply -f role-pod-reader.yaml
```

2. Create a RoleBinding to bind the Role to the ServiceAccount:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-reader-pod-reader-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
  - kind: ServiceAccount
    name: app-reader
    namespace: default
```

Save as `rolebinding-app-reader.yaml` and apply:

```bash
kubectl apply -f rolebinding-app-reader.yaml
```

3. Verify the Role and RoleBinding:

```bash
kubectl get role pod-reader
kubectl get rolebinding app-reader-pod-reader-binding
kubectl describe rolebinding app-reader-pod-reader-binding
```

**Verification Steps:**

```bash
# Confirm Role exists with correct verbs
kubectl get role pod-reader -o yaml

# Confirm RoleBinding references correct Role and ServiceAccount
kubectl get rolebinding app-reader-pod-reader-binding -o yaml

# Test permissions (see Exercise 1.4 for kubectl auth can-i testing)
kubectl auth can-i get pods --as=system:serviceaccount:default:app-reader
# Should return: yes
```

**Expected Outcomes:**

- Role `pod-reader` exists in default namespace
- RoleBinding `app-reader-pod-reader-binding` exists
- RoleBinding's SubjectIndex shows ServiceAccount `app-reader`
- Role has three rules for pods, deployments, and services

**Key Learning Concepts:**

- Roles are namespace-scoped; ClusterRoles are cluster-wide
- Verbs represent actions: get, list, watch (read), create, update, patch, delete, deletecollection (write)
- apiGroups: "" (empty) = core API; "apps", "batch", etc. = other groups
- RoleBinding connects (subject) ServiceAccounts/Users/Groups to (roleRef) Roles
- Multiple rules can be combined in a single Role

---

## Exercise 1.3: Implement ClusterRole and ClusterRoleBinding

**Problem Statement:**
Your monitoring service needs cluster-wide permissions to read node information, pod metrics, and cluster events from all namespaces. Create a ServiceAccount named `monitor-reader`, a ClusterRole with appropriate permissions, and a ClusterRoleBinding to grant access.

**Learning Objectives:**

- Understand ClusterRole for cluster-wide resource access
- Understand ClusterRoleBinding for cluster-wide permission grants
- Know which resources are cluster-scoped (nodes, pvc, clusterroles, etc.) vs namespace-scoped

**Instructions:**

1. Create a ServiceAccount `monitor-reader` in the default namespace:

```bash
kubectl create serviceaccount monitor-reader
```

2. Create a ClusterRole named `monitor-viewer` for cluster-wide read access:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitor-viewer
rules:
  - apiGroups: [""]
    resources: ["nodes", "events"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["metrics.k8s.io"]
    resources: ["pods", "nodes"]
    verbs: ["get", "list"]
```

Apply:

```bash
kubectl apply -f clusterrole-monitor-viewer.yaml
```

3. Create a ClusterRoleBinding to bind the ClusterRole to the ServiceAccount:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitor-reader-viewer-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: monitor-viewer
subjects:
  - kind: ServiceAccount
    name: monitor-reader
    namespace: default
```

Apply:

```bash
kubectl apply -f clusterrolebinding-monitor-reader.yaml
```

4. Verify ClusterRole and ClusterRoleBinding:

```bash
kubectl get clusterrole monitor-viewer
kubectl get clusterrolebinding monitor-reader-viewer-binding
```

**Verification Steps:**

```bash
# ClusterRole should exist and not be namespaced
kubectl get clusterrole monitor-viewer

# ClusterRoleBinding should exist
kubectl get clusterrolebinding monitor-reader-viewer-binding

# Test permissions across namespaces
kubectl auth can-i get nodes --as=system:serviceaccount:default:monitor-reader
# Should return: yes

kubectl auth can-i list pods --as=system:serviceaccount:default:monitor-reader -n kube-system
# Should return: yes (cluster-wide)
```

**Expected Outcomes:**

- ServiceAccount `monitor-reader` exists in default namespace
- ClusterRole `monitor-viewer` exists cluster-wide (no namespace shown)
- ClusterRoleBinding `monitor-reader-viewer-binding` exists
- Permissions are enforced across all namespaces

**Key Learning Concepts:**

- ClusterRoles can grant access to cluster-scoped resources (nodes, clusterroles, clusterrolebindings, namespaces)
- ClusterRoles can also grant access to namespace-scoped resources across all namespaces
- ClusterRoleBindings bind to ClusterRoles but can target ServiceAccounts in any namespace
- Combination of ClusterRole + ClusterRoleBinding = cluster-wide access
- Combination of Role + RoleBinding = namespace-scoped access

---

## Exercise 1.4: Verify Permissions with kubectl auth can-i

**Problem Statement:**
After implementing Roles and ClusterRoles, you need a way to verify that permissions are correctly assigned. Use `kubectl auth can-i` to check if users/service accounts have specific permissions, and use it to troubleshoot denied access attempts.

**Learning Objectives:**

- Use `kubectl auth can-i` to verify RBAC permissions
- Understand permission checking for different verbs and resources
- Diagnose permission issues using auth can-i

**Instructions:**

1. Create a test scenario with restrictive permissions. Create a Role named `deployer` that can only create and update deployments:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer
  namespace: default
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["create", "update", "patch"]
```

Apply:

```bash
kubectl apply -f role-deployer.yaml
```

2. Create a ServiceAccount and RoleBinding:

```bash
kubectl create serviceaccount app-deployer
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-deployer-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deployer
subjects:
  - kind: ServiceAccount
    name: app-deployer
    namespace: default
```

Apply:

```bash
kubectl apply -f rolebinding-app-deployer.yaml
```

3. Test various permissions using `kubectl auth can-i`:

```bash
# Test allowed action
kubectl auth can-i create deployments --as=system:serviceaccount:default:app-deployer
# Should return: yes

# Test denied action
kubectl auth can-i delete deployments --as=system:serviceaccount:default:app-deployer
# Should return: no

# Test other denied actions
kubectl auth can-i get pods --as=system:serviceaccount:default:app-deployer
# Should return: no

# Test with --list flag to see all permissions
kubectl auth can-i --list --as=system:serviceaccount:default:app-deployer
# Should show only create/update/patch on deployments
```

**Verification Steps:**

```bash
# Create should be allowed
kubectl auth can-i create deployments --as=system:serviceaccount:default:app-deployer
# Output: yes

# Delete should be denied
kubectl auth can-i delete deployments --as=system:serviceaccount:default:app-deployer
# Output: no

# List all permissions
kubectl auth can-i --list --as=system:serviceaccount:default:app-deployer
# Should show limited permissions for deployments only
```

**Expected Outcomes:**

- `kubectl auth can-i create deployments` returns `yes` for app-deployer
- `kubectl auth can-i delete deployments` returns `no` for app-deployer
- `kubectl auth can-i get pods` returns `no` for app-deployer
- `kubectl auth can-i --list` shows only the three allowed verbs on deployments

**Key Learning Concepts:**

- `kubectl auth can-i <verb> <resource>` checks if identity can perform action
- Use `--as=system:serviceaccount:<namespace>:<name>` to test ServiceAccount permissions
- `--list` flag shows all allowed actions for an identity
- Use for debugging before running actual API calls
- RBAC evaluation: if any Role/ClusterRole grants permission, it's allowed (ALLOW-only policy)

---

## Exercise 1.5: Understand RBAC Verbs and API Groups

**Problem Statement:**
You're reviewing a set of RBAC policies and need to understand what each verb permission allows. Create multiple Roles with different verbs (get, list, watch, create, update, patch, delete) and test the implications of each.

**Learning Objectives:**

- Understand RBAC verb categories (read: get/list/watch; write: create/update/patch; admin: delete/deletecollection)
- Know which verbs are needed for common operations
- Understand apiGroups and how they map to Kubernetes API groups

**Instructions:**

1. Create a Role named `read-only-pods` with read verbs:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: read-only-pods
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

2. Create a Role named `pod-writer` with write verbs:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-writer
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["create", "update", "patch"]
```

3. Create two ServiceAccounts:

```bash
kubectl create serviceaccount reader
kubectl create serviceaccount writer
```

4. Bind the Roles:

```bash
kubectl create rolebinding reader-binding --clusterrole=read-only-pods --serviceaccount=default:reader
# Note: This won't work directly as read-only-pods is a Role, not ClusterRole
# Instead, use manifest:
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: reader-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: read-only-pods
subjects:
  - kind: ServiceAccount
    name: reader
    namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: writer-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-writer
subjects:
  - kind: ServiceAccount
    name: writer
    namespace: default
```

5. Test verb permissions:

```bash
# Read permission (get): reader can get individual pod
kubectl auth can-i get pods --as=system:serviceaccount:default:reader
# Should return: yes

# Read permission (list): reader can list pods
kubectl auth can-i list pods --as=system:serviceaccount:default:reader
# Should return: yes

# Write permission: writer can create pods
kubectl auth can-i create pods --as=system:serviceaccount:default:writer
# Should return: yes

# Denied: reader cannot create
kubectl auth can-i create pods --as=system:serviceaccount:default:reader
# Should return: no

# Denied: writer cannot delete
kubectl auth can-i delete pods --as=system:serviceaccount:default:writer
# Should return: no
```

**Verification Steps:**

```bash
# Verify roles were created with correct verbs
kubectl get role read-only-pods -o yaml
kubectl get role pod-writer -o yaml

# Test each verb type
kubectl auth can-i get pods --as=system:serviceaccount:default:reader  # yes
kubectl auth can-i list pods --as=system:serviceaccount:default:reader  # yes
kubectl auth can-i create pods --as=system:serviceaccount:default:reader  # no
kubectl auth can-i update pods --as=system:serviceaccount:default:writer  # yes
kubectl auth can-i delete pods --as=system:serviceaccount:default:writer  # no
```

**Expected Outcomes:**

- Role with `get, list, watch` allows reading but not modifying
- Role with `create, update, patch` allows creation and modification
- Role without `delete` verb denies deletion attempts
- apiGroups: "" (empty string) = core API group

**Key Learning Concepts:**

- **Read verbs**: get (single resource), list (multiple), watch (stream changes)
- **Write verbs**: create (new), update (full replace), patch (partial)
- **Admin verbs**: delete, deletecollection, exec, logs, portforward
- **apiGroups**: "" = core, "apps" = deployments/statefulsets, "batch" = jobs/cronjobs, "rbac.authorization.k8s.io" = roles, "metrics.k8s.io" = metrics
- Principle of least privilege: grant only needed verbs

---

## Exercise 1.6: Advanced RBAC - Resource Names and Sub-Resources

**Problem Statement:**
You need to create a Role that grants permissions to specific resources by name (e.g., only allow access to a specific ConfigMap) or sub-resources (e.g., allow `kubectl logs` but not `kubectl exec`). Create a Role with resourceNames and test access to specific pod logs.

**Learning Objectives:**

- Understand resourceNames for granular resource-level access control
- Understand sub-resources (logs, exec, portforward) and their permissions
- Know when to use resourceNames vs. label selectors for access control

**Instructions:**

1. Create a test pod to work with:

```bash
kubectl run test-pod --image=nginx
```

2. Create a Role with specific resourceNames (logs access only):

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-logs-reader
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods/log"]
    resourceNames: ["test-pod"]
    verbs: ["get"]
```

Save and apply:

```bash
kubectl apply -f role-pod-logs-reader.yaml
```

3. Create a ServiceAccount and RoleBinding:

```bash
kubectl create serviceaccount logs-reader
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: logs-reader-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-logs-reader
subjects:
  - kind: ServiceAccount
    name: logs-reader
    namespace: default
```

4. Test permissions:

```bash
# Should be allowed: logs-reader can get logs from test-pod
kubectl auth can-i get pods/log --as=system:serviceaccount:default:logs-reader

# Should be denied: cannot get logs from other pods
kubectl auth can-i get pods/log --as=system:serviceaccount:default:logs-reader
# Note: This tests resource-name-agnostic behavior; name checking happens at API level

# Create a more comprehensive role for comparison
```

**Verification Steps:**

```bash
# Verify Role with resourceNames
kubectl get role pod-logs-reader -o yaml
# Should show resourceNames: ["test-pod"]

# List all permissions
kubectl auth can-i --list --as=system:serviceaccount:default:logs-reader
# Should show get on pods/log
```

**Expected Outcomes:**

- Role `pod-logs-reader` created with `resourceNames: ["test-pod"]`
- ServiceAccount `logs-reader` can access logs from `test-pod`
- Sub-resource `pods/log` is correctly specified
- Permissions are appropriately granular

**Key Learning Concepts:**

- **resourceNames**: Limits access to specific named resources (e.g., only pod "test-pod")
- **Sub-resources**: `pods/log`, `pods/exec`, `pods/attach`, `pods/portforward`
- Each sub-resource requires separate permission
- `pods/log` differs from `pods` (watching pod state)
- Useful for privilege isolation in shared clusters

---

## Exercise 1.7: Troubleshoot and Audit RBAC Decisions

**Problem Statement:**
A developer reports that their ServiceAccount cannot access certain resources. Troubleshoot the RBAC configuration to identify the issue and use Kubernetes audit logs to understand what permissions were checked. Review and fix permission gaps.

**Learning Objectives:**

- Use `kubectl describe rolebinding/role` to inspect RBAC configuration
- Understand how RBAC decisions are logged and audited
- Identify common RBAC misconfiguration issues
- Use kubectl commands to diagnose permission problems

**Instructions:**

1. Create a problematic RBAC setup (intentionally misconfigured):

```bash
kubectl create serviceaccount developer
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: incomplete-permissions
  namespace: default
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get"] # Only get, missing create/update
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: incomplete-permissions
subjects:
  - kind: ServiceAccount
    name: developer
    namespace: default
```

Apply both:

```bash
kubectl apply -f role-incomplete-permissions.yaml
kubectl apply -f rolebinding-developer-binding.yaml
```

2. Troubleshoot the developer's access (they should be able to create and update deployments):

```bash
# Check what developer can do
kubectl auth can-i --list --as=system:serviceaccount:default:developer
# Should show only "get" on deployments - this is the problem!

# Test specific actions
kubectl auth can-i get deployments --as=system:serviceaccount:default:developer
# Returns: yes

kubectl auth can-i create deployments --as=system:serviceaccount:default:developer
# Returns: no (this is the issue)
```

3. Identify the issue by describing the RoleBinding:

```bash
kubectl describe rolebinding developer-binding
# Shows the roleRef points to incomplete-permissions Role

kubectl describe role incomplete-permissions
# Shows only "get" verb is granted
```

4. Fix the issue by updating the Role:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: incomplete-permissions
  namespace: default
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
```

Apply the fix:

```bash
kubectl apply -f role-incomplete-permissions.yaml
```

5. Verify the fix:

```bash
kubectl auth can-i create deployments --as=system:serviceaccount:default:developer
# Should now return: yes
```

**Verification Steps:**

```bash
# Show the diagnostic output before fix
kubectl auth can-i create deployments --as=system:serviceaccount:default:developer
# Should return: no initially

# Show RoleBinding details
kubectl get rolebinding developer-binding -o yaml

# Show Role details
kubectl get role incomplete-permissions -o yaml

# After fix, verify
kubectl auth can-i create deployments --as=system:serviceaccount:default:developer
# Should return: yes
```

**Expected Outcomes:**

- Initial auth can-i check reveals the permission issue
- `kubectl describe` shows the role is missing `create` verb
- Updating the Role adds the missing verbs
- Second auth can-i check confirms the fix works

**Key Learning Concepts:**

- **Troubleshooting workflow**: `kubectl auth can-i` → `kubectl describe role/rolebinding` → identify gap → update RBAC policy
- **Common issues**: Missing verbs, wrong apiGroups, wrong role kind (Role vs ClusterRole)
- RBAC changes take effect immediately (no pod restart needed)
- Use `kubectl describe` to inspect RoleBinding's roleRef
- Use `kubectl describe` to see all rules in a Role

---

## Exercise 1.8: Cleanup

**Problem Statement:**
Remove all RBAC resources created in this exercise set to clean up the cluster.

**Instructions:**

Remove ServiceAccounts:

```bash
kubectl delete serviceaccount app-reader
kubectl delete serviceaccount monitor-reader
kubectl delete serviceaccount app-deployer
kubectl delete serviceaccount reader
kubectl delete serviceaccount writer
kubectl delete serviceaccount logs-reader
kubectl delete serviceaccount developer
```

Remove Roles:

```bash
kubectl delete role pod-reader
kubectl delete role deployer
kubectl delete role read-only-pods
kubectl delete role pod-writer
kubectl delete role pod-logs-reader
kubectl delete role incomplete-permissions
```

Remove RoleBindings:

```bash
kubectl delete rolebinding app-reader-pod-reader-binding
kubectl delete rolebinding app-reader-binding
kubectl delete rolebinding app-deployer-binding
kubectl delete rolebinding reader-binding
kubectl delete rolebinding writer-binding
kubectl delete rolebinding logs-reader-binding
kubectl delete rolebinding developer-binding
```

Remove ClusterRole and ClusterRoleBinding:

```bash
kubectl delete clusterrole monitor-viewer
kubectl delete clusterrolebinding monitor-reader-viewer-binding
```

Remove test pod:

```bash
kubectl delete pod test-pod
```

**Verification Steps:**

```bash
# Verify all ServiceAccounts are gone (default should remain)
kubectl get serviceaccount
# Should show only: default

# Verify no custom Roles exist
kubectl get role
# Should show none or only system roles

# Verify no custom RoleBindings exist
kubectl get rolebinding
# Should show none or only system bindings

# Verify custom ClusterRole is gone
kubectl get clusterrole | grep monitor-viewer
# Should return nothing
```

**Expected Outcomes:**

- All custom ServiceAccounts removed
- All custom Roles removed
- All custom RoleBindings removed
- All custom ClusterRoles removed
- All custom ClusterRoleBindings removed
- Default namespace is clean (except default ServiceAccount)

---

## Module Completion Checklist

- [ ] Completed Exercise 1.1: ServiceAccount creation and token inspection
- [ ] Completed Exercise 1.2: Role and RoleBinding for namespace-scoped access
- [ ] Completed Exercise 1.3: ClusterRole and ClusterRoleBinding for cluster-wide access
- [ ] Completed Exercise 1.4: Verified permissions using `kubectl auth can-i`
- [ ] Completed Exercise 1.5: Understood RBAC verbs and API groups
- [ ] Completed Exercise 1.6: Implemented resource-name and sub-resource permissions
- [ ] Completed Exercise 1.7: Troubleshot and fixed RBAC misconfigurations
- [ ] Completed Exercise 1.8: Cleaned up all RBAC resources

## Key Takeaways

1. **RBAC Components**: ServiceAccounts (identity), Roles (permissions), RoleBindings (connection)
2. **Scope Matters**: Roles/RoleBindings = namespace; ClusterRoles/ClusterRoleBindings = cluster-wide
3. **Verbs Are Atomic**: Must explicitly grant each verb (get, create, delete, etc.)
4. **apiGroups Are Specific**: "" (core), "apps", "batch", "rbac.authorization.k8s.io", etc.
5. **Least Privilege**: Only grant necessary permissions; use resourceNames when possible
6. **Testing Tools**: `kubectl auth can-i` is your primary diagnostic tool
7. **Best Practices**: Use ClusterRoles for common permissions, RoleBindings to assign; avoid over-permissioning

## Useful Commands Reference

```bash
# Create resources
kubectl create serviceaccount <name>
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml

# Get RBAC resources
kubectl get serviceaccount
kubectl get role
kubectl get rolebinding
kubectl get clusterrole
kubectl get clusterrolebinding

# Inspect RBAC resources
kubectl describe serviceaccount <name>
kubectl describe role <name>
kubectl describe rolebinding <name>
kubectl get <resource> -o yaml

# Test permissions
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<namespace>:<sa-name>
kubectl auth can-i --list --as=system:serviceaccount:<namespace>:<sa-name>

# Delete resources
kubectl delete serviceaccount <name>
kubectl delete role <name>
kubectl delete rolebinding <name>
kubectl delete clusterrole <name>
kubectl delete clusterrolebinding <name>
```

---

**Next Steps:** Proceed to Network Policies exercises to complete Module 04 on security and access control.
