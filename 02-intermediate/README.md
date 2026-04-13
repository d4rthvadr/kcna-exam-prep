# Module 02: Intermediate - Configuration & State Management

**Focus:** Master application configuration, secrets management, and persistent data storage in Kubernetes.

**Duration:** 2-3 days  
**Prerequisites:** Module 01 completed  
**KCNA Alignment:** Container Orchestration (46%), Cloud Native Architecture (16%)

## 📚 Learning Objectives

By completing this module, you will:

- Create and use ConfigMaps for application configuration
- Manage sensitive data with Secrets
- Understand storage concepts (PersistentVolumes, PersistentVolumeClaims, StorageClasses)
- Deploy StatefulSets for applications requiring stable identity
- Inject configuration and secrets into Pods
- Understand volume lifecycle and data persistence

## 📂 Exercise Breakdown

| Exercise                | Topics                                                                 | Time  |
| ----------------------- | ---------------------------------------------------------------------- | ----- |
| **configmaps-secrets/** | ConfigMaps, Secrets, environment variables, volume mounting            | 1 day |
| **storage/**            | PersistentVolumes, PersistentVolumeClaims, StatefulSets, local storage | 1 day |

## 🎯 Key Concepts

### ConfigMaps

- Store non-sensitive configuration data as key-value pairs
- Decouple configuration from Pod definitions
- Support file-based and literal data
- Mounted as environment variables or volumes

### Secrets

- Store sensitive data (tokens, passwords, certificates)
- Three types: Opaque (default), kubernetes.io/service-account-token, kubernetes.io/dockercfg
- Base64 encoded (not encrypted by default!)
- Same usage patterns as ConfigMaps (env vars or volume mounting)

### Storage

- **PersistentVolume (PV)**: Storage resource provisioned by cluster admin
- **PersistentVolumeClaim (PVC)**: Storage request by a Pod
- **StorageClass**: Defines how PVs are dynamically provisioned
- **Volumes**: Temporary (emptyDir) or persistent (hostPath, NFS, cloud storage, etc.)

### StatefulSets

- Like Deployments but provides stable pod identity
- Pods have ordinal identities (web-0, web-1, etc.)
- Enables persistent storage per Pod
- Suitable for databases, caches, message queues (but limited in Kubernetes learning)

## 🚀 Getting Started

1. Complete configmaps-secrets exercises first (configuration fundamentals)
2. Move to storage exercises (builds on configuration knowledge)
3. Deploy StatefulSet only after understanding PVC and storage concepts
4. Test each concept independently before combining

## 💡 Tips

- **ConfigMaps first** - Start with environment variables, then progress to volume mounting
- **Secrets are encoded, not encrypted** - Understand the security implications
- **Test with Deployments first** - Use StatefulSets only when you need persistent identity
- **Local storage limitations** - Understand why local storage isn't suitable for production
- **Cleanup PVCs carefully** - By default PVCs are retained when Pods delete

## 📖 Useful Commands (See cheatsheet.md for more)

```bash
# ConfigMaps and Secrets
kubectl create configmap <name> --from-literal=key=value
kubectl create secret generic <name> --from-literal=password=mypass
kubectl get configmaps
kubectl get secrets
kubectl describe configmap <name>

# Storage
kubectl get pv
kubectl get pvc
kubectl describe pvc <pvc-name>
kubectl describe storageclass

# StatefulSets
kubectl get statefulsets
kubectl get pod -l app=web    # Find pods by label
kubectl delete statefulset <name> --cascade=foreground  # Delete StatefulSet with Pods
```

## ✅ Module Completion Checklist

- [ ] Created ConfigMaps and used them in Pods
- [ ] Created Secrets and injected them as environment variables
- [ ] Mounted ConfigMaps and Secrets as volumes
- [ ] Created PersistentVolumes and PersistentVolumeClaims
- [ ] Deployed application using PersistentVolume storage
- [ ] Created StatefulSet with persistent storage
- [ ] Understand when to use ConfigMaps vs Secrets
- [ ] Understand volume lifecycle and retention policies
- [ ] Ready to move to Module 03

---

**Prerequisites:** Complete Module 01 first  
**Next Step:** Start with `configmaps-secrets/exercise.md`
