# kubectl Cheatsheet for KCNA Exam Prep

Quick reference for commonly used kubectl commands organized by domain.

## 🔧 Cluster & Configuration

```bash
# Context and cluster info
kubectl cluster-info
kubectl config view
kubectl config current-context
kubectl config use-context <context-name>
kubectl get nodes
kubectl describe node <node-name>

# API info
kubectl api-versions
kubectl api-resources
```

## 📦 Core Objects (Pods, Deployments, Services)

### Pods

```bash
# View pods
kubectl get pods
kubectl get pods -n <namespace>
kubectl get pods --all-namespaces
kubectl get pods -l app=nginx
kubectl get pods -o wide
kubectl get pods -o yaml

# Create and manage pods
kubectl apply -f pod.yaml
kubectl run nginx --image=nginx:latest
kubectl describe pod <pod-name>
kubectl delete pod <pod-name>

# Pod debugging
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --previous  # Logs from crashed container
kubectl exec -it <pod-name> -- /bin/sh
kubectl port-forward pod/<pod-name> 8080:80
```

### Deployments

```bash
# View deployments
kubectl get deployments
kubectl get deployment <name> -o yaml
kubectl describe deployment <name>

# Create and update
kubectl apply -f deployment.yaml
kubectl create deployment nginx --image=nginx:latest
kubectl set image deployment/<name> <container>=<image>
kubectl edit deployment <name>

# Scaling
kubectl scale deployment <name> --replicas=5
kubectl autoscale deployment <name> --min=2 --max=10 --cpu-percent=80

# Rolling updates
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout undo deployment/<name> --to-revision=2

# Delete deployments
kubectl delete deployment <name>
```

### ReplicaSets

```bash
kubectl get replicasets
kubectl describe replicaset <name>
kubectl delete replicaset <name> --cascade=foreground
```

### Services

```bash
# View services
kubectl get services
kubectl get svc
kubectl describe service <name>
kubectl get endpoints

# Create services
kubectl apply -f service.yaml
kubectl expose deployment <name> --type=ClusterIP --port=80 --target-port=8080
kubectl expose deployment <name> --type=NodePort --port=80 --target-port=8080
kubectl expose deployment <name> --type=LoadBalancer --port=80 --target-port=8080

# Networking
kubectl port-forward svc/<service-name> 8080:80
kubectl get svc -A  # All namespaces
```

## ⚙️ Configuration (ConfigMaps & Secrets)

```bash
# ConfigMaps
kubectl create configmap <name> --from-literal=key=value
kubectl create configmap <name> --from-file=config.txt
kubectl get configmaps
kubectl describe configmap <name>
kubectl edit configmap <name>
kubectl apply -f configmap.yaml

# Secrets
kubectl create secret generic <name> --from-literal=password=mypass
kubectl create secret generic <name> --from-file=tls.crt=cert.pem --from-file=tls.key=key.pem
kubectl get secrets
kubectl describe secret <name>
kubectl get secret <name> -o yaml
kubectl apply -f secret.yaml

# Encoding/decoding
echo -n 'password' | base64
echo 'YmFzZTY0ZW5jb2RlZg==' | base64 -d
```

## 💾 Storage (Volumes & Persistence)

```bash
# PersistentVolumes
kubectl get pv
kubectl describe pv <name>
kubectl delete pv <name>

# PersistentVolumeClaims
kubectl get pvc
kubectl describe pvc <name>
kubectl delete pvc <name>

# Storage Classes
kubectl get storageclass
kubectl describe storageclass <name>

# StatefulSets
kubectl get statefulsets
kubectl describe statefulset <name>
kubectl scale statefulset <name> --replicas=5
kubectl delete statefulset <name> --cascade=foreground
```

## 📋 Scheduling (Labels, Affinity, Taints)

```bash
# Labels and selectors
kubectl label nodes <node-name> disktype=ssd
kubectl label pod <pod-name> app=frontend
kubectl get nodes --show-labels
kubectl get pods -l app=nginx
kubectl get pods -L env,tier
kubectl describe node <node-name> | grep Taints

# Taints and tolerations
kubectl taint nodes <node-name> key=value:NoSchedule
kubectl taint nodes <node-name> key=value:NoExecute
kubectl taint nodes <node-name> key=value:NoSchedule-  # Remove taint

# Resource usage
kubectl top nodes
kubectl top pods
kubectl describe node <node-name> | grep -A 5 Allocatable
```

## 🛡️ RBAC (Access Control)

```bash
# ServiceAccounts
kubectl get serviceaccounts
kubectl describe serviceaccount <name>
kubectl create serviceaccount <name>

# Roles
kubectl get roles
kubectl describe role <name>
kubectl create role <name> --verb=get,list --resource=pods
kubectl edit role <name>

# RoleBindings
kubectl get rolebindings
kubectl describe rolebinding <name>
kubectl create rolebinding <name> --role=<role-name> --serviceaccount=default:<sa-name>

# ClusterRoles
kubectl get clusterroles
kubectl describe clusterrole <name>

# ClusterRoleBindings
kubectl get clusterrolebindings
kubectl describe clusterrolebinding <name>

# Check permissions
kubectl auth can-i list pods
kubectl auth can-i list pods --as=system:serviceaccount:default:my-sa
kubectl auth can-i get deployments --as=system:serviceaccount:kube-system:admin
```

## 🔗 Network & Security

```bash
# NetworkPolicies
kubectl get networkpolicies
kubectl describe networkpolicy <name>
kubectl apply -f networkpolicy.yaml

# Security context
kubectl get pod <name> -o yaml | grep -A 10 securityContext

# Pod-to-pod connectivity
kubectl exec -it <pod1> -- curl http://<pod2-ip>:8080
kubectl exec -it <pod1> -- ping <pod2-ip>
kubectl exec -it <pod1> -- nslookup <service-name>
```

## ⏱️ Jobs & CronJobs

```bash
# Jobs
kubectl get jobs
kubectl describe job <name>
kubectl logs job/<name>
kubectl delete job <name>
kubectl get pods -l job-name=<job-name>

# CronJobs
kubectl get cronjobs
kubectl describe cronjob <name>
kubectl delete cronjob <name>
kubectl create job <name> --from=cronjob/<cronjob-name>  # Manual trigger
```

## 📊 Observability & Troubleshooting

```bash
# Events
kubectl get events
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -n <namespace>

# Metrics and monitoring
kubectl top nodes
kubectl top pods
kubectl get --raw=/apis/metrics.k8s.io/v1beta1/nodes
kubectl get --raw=/apis/metrics.k8s.io/v1beta1/pods

# General debugging
kubectl describe pod <name>
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --previous
kubectl exec -it <pod-name> -- /bin/bash
kubectl get events --field-selector involvedObject.name=<pod-name>

# Network debugging
kubectl debug node/<node-name> -it --image=ubuntu

# View API request details
kubectl apply -f file.yaml --v=8
```

## 🗂️ Namespaces

```bash
kubectl get namespaces
kubectl create namespace <name>
kubectl delete namespace <name>
kubectl config set-context --current --namespace=<namespace>
kubectl get pods -n <namespace>
kubectl get pods --all-namespaces
kubectl apply -f resource.yaml -n <namespace>
```

## Resource Management

```bash
# Viewing resource definitions
kubectl get -o yaml
kubectl get -o json
kubectl explain pod
kubectl explain pod.spec.containers

# Applying and managing resources
kubectl apply -f file.yaml
kubectl apply -f directory/
kubectl create -f file.yaml
kubectl replace -f file.yaml
kubectl delete -f file.yaml
kubectl delete <resource-type> <name>

# Dry-run
kubectl apply -f file.yaml --dry-run=client
kubectl apply -f file.yaml --dry-run=server
```

## Common Troubleshooting Patterns

```bash
# Pod won't start
kubectl describe pod <name>  # Look for events
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# Service not working
kubectl get endpoints <service-name>
kubectl describe service <service-name>
kubectl exec -it <pod> -- curl http://<service-name>:80

# Permission denied
kubectl auth can-i <verb> <resource>
kubectl get rolebinding -n default -o yaml

# High resource usage
kubectl top pod <name>
kubectl describe node
kubectl get nodes --sort-by=.status.capacity.memory
```

---

**Pro Tips:**

- Use `--dry-run=client -o yaml` to preview what will be created
- Use short flags: `kubectl get po`, `kubectl get svc`, `kubectl get pvc`
- Use `watch` to monitor: `watch kubectl get pods`
- Set alias: `alias k=kubectl` for faster typing
- Use `--help` for any command: `kubectl get --help`
