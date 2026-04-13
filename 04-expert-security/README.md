# Module 04: Expert I - Security & Access Control

**Focus:** Implement fine-grained access control and secure cluster communication with RBAC and network policies.

**Duration:** 2-3 days  
**Prerequisites:** Module 01-03 completed  
**KCNA Alignment:** Container Orchestration (46%), Cloud Native Architecture (16%)

## Learning Objectives

By completing this module, you will:

- Design and implement Role-Based Access Control (RBAC)
- Create Roles, RoleBindings, ClusterRoles, and ClusterRoleBindings
- Manage ServiceAccounts and their permissions
- Implement NetworkPolicies for network segmentation
- Apply SecurityContexts to enforce Pod security policies
- Understand Kubernetes security best practices
- Troubleshoot permission and network connectivity issues

## Exercise Breakdown

| Exercise              | Topics                                                                              | Time     |
| --------------------- | ----------------------------------------------------------------------------------- | -------- |
| **rbac/**             | ServiceAccounts, Roles, RoleBindings, ClusterRoles, ClusterRoleBindings, API groups | 1.5 days |
| **network-policies/** | NetworkPolicies, traffic control, ingress/egress rules                              | 1 day    |
| **security/**         | SecurityContexts, capabilities, RunAsUser, read-only filesystems                    | 0.5 day  |

## Key Concepts

### RBAC Components

**ServiceAccount:**

- Identity for Pods to use when communicating with API server
- Automatically mounted into every Pod
- Used by kubelet to authenticate

**Role/RoleBinding:**

- Role: Set of permissions within a namespace
- RoleBinding: Connects Role to ServiceAccount/User/Group in same namespace
- Namespace-scoped

**ClusterRole/ClusterRoleBinding:**

- Cluster-scoped equivalents (access cluster-wide resources)
- Used for cluster-level permissions
- Used by Roles, non-namespaced resources, etc.

**RBAC Verbs:**

- get, list, watch (read)
- create, update, patch, delete (write)
- exec, portforward, proxy (special)
- Full list: get, create, update, patch, delete, list, watch, exec, attach, proxy

**API Groups:**

- Core: "" (pods, services, etc.)
- apps: (deployments, statefulsets, etc.)
- batch: (jobs, cronjobs, etc.)
- And many more RBAC and NetworkPolicy scenarios

### NetworkPolicies

- Control traffic flow at IP address/port level
- Works at Layer 3/4 (IP/TCP)
- Default: all traffic allowed
- Must explicitly define what is allowed

**Ingress:**

- Controls inbound traffic TO a Pod
- Based on source Pod/namespace labels or CIDR blocks

**Egress:**

- Controls outbound traffic FROM a Pod
- Based on destination Pod/namespace labels or CIDR blocks

**Selectors:**

- podSelector: Select Pods that policy applies to
- policyTypes: [Ingress] or [Egress] or both

### SecurityContext

- Enforce security standards at Pod and Container level
- runAsUser: Run container as specific UID
- fsGroup: Set filesystem group for volume ownership
- readOnlyRootFilesystem: Prevent writing to root filesystem
- capabilities: Linux capability restrictions

## Getting Started

1. Start with RBAC exercises (foundational for cluster security)
2. Progress to NetworkPolicies (network-level isolation)
3. Apply SecurityContexts to running containers
4. Combine all three concepts in security scenarios

## Tips

- **RBAC is complex** - Understand the difference between Roles, RoleBindings, ClusterRoles first
- **Test incrementally** - Create Role, then RoleBinding, then test with ServiceAccount
- **NetworkPolicies require CNI** - Not all cluster plugins support them; verify your cluster
- **Deny by default** - Use NetworkPolicies to explicitly allow traffic
- **SecurityContext inheritance** - Pod-level settings apply to all containers unless overridden

## Useful Commands (See cheatsheet.md for more)

```bash
# ServiceAccounts
kubectl get serviceaccounts
kubectl describe sa <name>
kubectl get secret <token-secret> -o yaml

# RBAC
kubectl get roles
kubectl get rolebindings
kubectl get clusterroles
kubectl get clusterrolebindings
kubectl describe role <name>

# Check permissions
kubectl auth can-i list pods --as=system:serviceaccount:default:my-sa

# NetworkPolicies
kubectl get networkpolicies
kubectl describe networkpolicy <name>
kubectl get pods -o wide  # See pod IPs for troubleshooting

# SecurityContext
kubectl get pod <name> -o yaml  # See securityContext applied
```

## Module Completion Checklist

- [ ] Created ServiceAccounts and understood their role
- [ ] Created Roles and RoleBindings
- [ ] Created ClusterRoles and ClusterRoleBindings
- [ ] Understood RBAC verbs and API groups
- [ ] Used RBAC checks to verify permissions
- [ ] Implemented NetworkPolicies for traffic control
- [ ] Applied SecurityContexts to Pods
- [ ] Can troubleshoot permission denied errors
- [ ] Can troubleshoot network connectivity issues
- [ ] Ready to move to Module 05

---

**Prerequisites:** Complete Module 01-03 first  
**Next Step:** Start with `rbac/exercise.md`
