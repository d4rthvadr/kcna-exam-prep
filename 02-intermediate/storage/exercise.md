# Exercise: Storage - Persistent Data Management

## 📌 Problem Statement

Manage persistent data in Kubernetes using PersistentVolumes (PV), PersistentVolumeClaims (PVC), and StatefulSets. You'll learn how to decouple storage from applications, understand storage provisioning, and deploy stateful applications.

## 🎯 Learning Objectives

By completing this exercise, you will be able to:

1. Create and manage PersistentVolumes
2. Create and manage PersistentVolumeClaims
3. Mount PersistentVolumes in Pods
4. Understand different access modes
5. Deploy Deployments with persistent storage
6. Deploy StatefulSets with stable pod identity
7. Understand storage lifecycle and retention
8. Debug storage-related issues

## 📝 Exercises

### Exercise 1.1: Create PersistentVolume (Local Storage)

**Objective:** Create a PersistentVolume for local node storage.

**Prerequisites:**

```bash
# Create directories on your local machine for storage
mkdir -p /tmp/k8s-storage/pv1
mkdir -p /tmp/k8s-storage/pv2

# Permission (may not work on all OS)
chmod 777 /tmp/k8s-storage/pv*
```

**Instructions:**

1. Create a file `local-pv.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv-1
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  hostPath:
    path: /tmp/k8s-storage/pv1
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv-2
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  hostPath:
    path: /tmp/k8s-storage/pv2
```

2. Apply the manifest
3. Verify PersistentVolumes were created

**Verification Steps:**

```bash
# View PersistentVolumes
kubectl get pv

# Get detailed information
kubectl get pv -o wide

# Describe PV
kubectl describe pv local-pv-1

# Check status and capacity
kubectl get pv local-pv-1 -o jsonpath='{.status.phase}'
```

**Expected Outcomes:**

- Two PersistentVolumes created with status "Available"
- Each has capacity "1Gi"
- Access mode shows "RWO" (ReadWriteOnce)
- StorageClassName is "local-storage"
- No claims yet (Claim column empty)

**Access Modes Explained:**

- **ReadWriteOnce (RWO)**: Volume can be read-write by single node
- **ReadOnlyMany (ROX)**: Multiple nodes can read
- **ReadWriteMany (RWX)**: Multiple nodes can read-write (requires shared storage)

---

### Exercise 1.2: Create PersistentVolumeClaim

**Objective:** Request storage from PersistentVolume using a PersistentVolumeClaim.

**Instructions:**

1. Create file `local-pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 500Mi
```

2. Apply the manifest
3. Verify PVC is bound to PV

**Verification Steps:**

```bash
# View PersistentVolumeClaims
kubectl get pvc

# Get detailed info
kubectl get pvc -o wide

# Describe PVC
kubectl describe pvc app-storage

# Check binding status
kubectl get pvc app-storage -o jsonpath='{.status.phase}'

# Check which PV it's bound to
kubectl get pvc app-storage -o jsonpath='{.spec.volumeName}'

# Verify PV status changed
kubectl get pv
```

**Expected Outcomes:**

- PVC created with status "Bound" (or "Pending" if PV not available)
- PVC bound to one of the local-pv volumes
- PV status changes from "Available" to "Bound"
- Storage allocated from requested 500Mi (from 1Gi capacity)

**Binding Process:**

```
PVC request (500Mi, RWO, local-storage)
    ↓
Kubernetes scheduler finds matching PV
    ↓
PVC binds to PV (one-to-one, exclusive)
    ↓
Status: Bound
```

---

### Exercise 1.3: Mount PVC in Pod

**Objective:** Use PersistentVolumeClaim in a Pod to persist data.

**Instructions:**

1. Create file `pod-with-storage.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-pod
spec:
  containers:
    - name: app
      image: busybox:latest
      command: ["sh", "-c"]
      args:
        - |
          echo "App started at $(date)" > /data/app-log.txt
          echo "Data directory contents:"
          ls -la /data/
          sleep 3600
      volumeMounts:
        - name: storage
          mountPath: /data
  volumes:
    - name: storage
      persistentVolumeClaim:
        claimName: app-storage
```

2. Apply the manifest
3. Verify data is persisted

**Verification Steps:**

```bash
# Apply pod
kubectl apply -f pod-with-storage.yaml

# Verify pod is running
kubectl get pod storage-pod

# View logs
kubectl logs storage-pod

# Exec into pod and check files
kubectl exec storage-pod -- ls -la /data/

# Check actual filesystem (on host)
ls -la /tmp/k8s-storage/pv1/  # Should see app-log.txt

# Read file from pod
kubectl exec storage-pod -- cat /data/app-log.txt
```

**Expected Outcomes:**

- Pod runs successfully
- `/data` directory is mounted from PVC
- Files written to `/data` persist on host filesystem
- Can read files from both Pod and host

**Storage Flow:**

```
Pod writes to /data/app-log.txt
    ↓
VolumeMount maps /data to PVC
    ↓
PVC references hostPath /tmp/k8s-storage/pv1
    ↓
File appears on host filesystem
```

---

### Exercise 1.4: Delete Pod, Verify Data Persists

**Objective:** Demonstrate that data survives Pod deletion.

**Instructions:**

1. Delete the storage-pod
2. Create a new pod mounting same PVC
3. Verify files from previous pod still exist

**Verification Steps:**

```bash
# Delete pod
kubectl delete pod storage-pod

# Verify pod is gone
kubectl get pods

# Verify PVC still exists and is bound
kubectl get pvc app-storage
kubectl get pv | grep app-storage

# Create new pod with same PVC
cat > pod-with-storage-2.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: storage-pod-2
spec:
  containers:
  - name: app
    image: busybox:latest
    command: ['sh']
    args: ['-c', 'sleep 3600']
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: app-storage
EOF

kubectl apply -f pod-with-storage-2.yaml

# Check files from old pod still exist
kubectl exec storage-pod-2 -- cat /data/app-log.txt

# Files should contain data from first pod
```

**Expected Outcomes:**

- Old Pod deleted
- PVC remains bound (data not deleted)
- New Pod can access files from old Pod
- Data persists across Pod lifecycle

**Key Learning:** Storage lifecycle is independent from Pod lifecycle

---

### Exercise 1.5: PVC Retention Policy

**Objective:** Understand what happens when PVC is deleted.

**Instructions:**

1. Delete the PVC
2. Observe what happens to PV
3. Check if data still exists on host

**Verification Steps:**

```bash
# Note PV name before deletion
kubectl get pvc app-storage -o jsonpath='{.spec.volumeName}'  # Should be local-pv-1 or local-pv-2

# Delete PVC
kubectl delete pvc app-storage

# Check PVC status
kubectl get pvc app-storage  # Should be gone

# Check PV status
kubectl get pv
# PV status should be "Released" (not Available, not Bound)

# Check host filesystem
ls -la /tmp/k8s-storage/pv1/  # Files still there!

# This is because PV reclaim policy is "Retain" (default)
# Check PV details
kubectl get pv local-pv-1 -o yaml | grep -A 3 persistentVolumeReclaimPolicy
```

**Expected Outcomes:**

- PVC deleted
- PV transitions to "Released" state (not immediately available)
- Data still exists on host filesystem
- PV can't be reused immediately

**Reclaim Policies:**

- **Retain** (default): Keep PV and data after PVC deleted
- **Delete**: Delete PV and data after PVC deleted
- **Recycle** (deprecated): Wipe data, make PV available again

---

### Exercise 1.6: StatefulSet with Persistent Storage

**Objective:** Deploy StatefulSet where each Pod gets its own storage.

**Prerequisites:**
Create a third PV:

```bash
mkdir -p /tmp/k8s-storage/pv3
# Add to local-pv.yaml and reapply:
# apiVersion: v1
# kind: PersistentVolume
# metadata:
#   name: local-pv-3
```

**Instructions:**

1. Create file `statefulset.yaml`:

```yaml
apiVersion: v1
kind: StorageClass
metadata:
  name: local
provisioner: kubernetes.io/no-provisioner
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 2
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: busybox:latest
          command:
            - sh
            - -c
            - |
              echo "Pod $(hostname)" > /var/lib/mysql/pod-info.txt
              echo "Started at $(date)" >> /var/lib/mysql/pod-info.txt
              sleep 3600
          volumeMounts:
            - name: data
              mountPath: /var/lib/mysql
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: local
        resources:
          requests:
            storage: 500Mi
```

2. Apply the manifest
3. Verify each Pod has its own PVC

**Verification Steps:**

```bash
# Create service first
kubectl create service clusterip mysql --clusterip=None

# Apply StatefulSet
kubectl apply -f statefulset.yaml

# View StatefulSet
kubectl get statefulset

# View Pods (should have ordinal names)
kubectl get pods -l app=mysql
# Should see: mysql-0, mysql-1

# View PVCs created
kubectl get pvc
# Should see: data-mysql-0, data-mysql-1

# Verify each Pod has different storage
kubectl exec mysql-0 -- cat /var/lib/mysql/pod-info.txt
kubectl exec mysql-1 -- cat /var/lib/mysql/pod-info.txt
# Should show different pod names

# Delete Pod, verify identity preserved
kubectl delete pod mysql-0

# Watch pod recreate
watch kubectl get pods -l app=mysql

# New mysql-0 will have SAME name and SAME storage
kubectl exec mysql-0 -- cat /var/lib/mysql/pod-info.txt
# Should match the old mysql-0 data (unless pod timing affected it)
```

**Expected Outcomes:**

- StatefulSet creates Pods with ordinal names (mysql-0, mysql-1)
- Each Pod gets its own PVC (data-mysql-0, data-mysql-1)
- Pods have stable identity (name, storage, network)
- If Pod deleted, new Pod gets same storage
- Data survives Pod recreation

**StatefulSet vs Deployment:**

- **StatefulSet**: Stable pod identity (mysql-0, mysql-1)
- **Deployment**: Random pod names (mysql-xyz, mysql-abc)
- Each StatefulSet Pod gets dedicated PVC
- Useful for: databases, message queues, caches (any stateful app)

---

### Exercise 1.7: Storage Troubleshooting

**Objective:** Debug common storage issues.

**Scenarios:**

**Scenario 1: PVC won't bind**

```bash
# Create PVC with 2Gi but PV only has 1Gi
kubectl create pvc test-pvc --size=2Gi

# Result: PVC status "Pending"

# Debug:
kubectl describe pvc test-pvc  # Shows description of failure
kubectl get pv  # Check available capacity
kubectl get pvc test-pvc -o jsonpath='{.status.conditions}'
```

**Scenario 2: Pod can't mount PVC**

```bash
# Try mounting PVC with wrong access mode
kubectl describe pod storage-pod  # Check Events section
kubectl get pvc  # Verify PVC is Bound
```

**Scenario 3: Out of storage**

```bash
# Check available space on PV
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,AVAILABLE:.status.allocatable

# Check Pod attempt:
kubectl describe pod <name>  # Look for "FailedMount"
```

---

### Exercise 1.8: Cleanup

**Objective:** Clean up all storage resources.

**Verification Steps:**

```bash
# Delete StatefulSet
kubectl delete statefulset mysql

# Delete PVCs
kubectl delete pvc --all

# Delete PVs
kubectl delete pv --all

# Delete remaining pods
kubectl delete pod --all

# Verify cleanup
kubectl get pv
kubectl get pvc
kubectl get pods

# Verify host filesystem still has data
ls -la /tmp/k8s-storage/pv*  # Files still there (PV is Retain policy)
```

**Expected Outcomes:**

- All Kubernetes storage objects deleted
- Actual files on host persist (because Reclaim policy is Retain)
- In production, decide cleanup strategy carefully

---

## 🧠 Key Concepts Explained

### Storage Architecture

```
Pod
  ↓ (volumeMount)
PersistentVolumeClaim
  ↓ (binding)
PersistentVolume
  ↓ (backend)
Actual Storage (hostPath, NFS, EBS, etc.)
```

### PersistentVolume Lifecycle

```
1. Provisioning - PV created (static or dynamic)
2. Binding - PVC requests matches PV
3. Using - Pod uses PVC, PV holds data
4. Releasing - PVC deleted
5. Reclaiming - Reclaim policy applied (Retain/Delete/Recycle)
```

### Access Modes

| Mode                    | Single Node | Multiple Nodes | Use Case                      |
| ----------------------- | ----------- | -------------- | ----------------------------- |
| **RWO** (ReadWriteOnce) | Read-Write  | Read-only      | Single app needs read-write   |
| **ROX** (ReadOnlyMany)  | Read-Write  | Read-only      | Data shared, read-only        |
| **RWX** (ReadWriteMany) | Read-Write  | Read-Write     | Shared filesystem, multi-node |

### Dynamic vs Static Provisioning

**Static (Manual):**

- Admin creates PVs manually
- User creates PVC requesting matching PV
- Used for local/NFS storage

**Dynamic (Automatic):**

- StorageClass defines provisioning rules
- PVC created automatically provisions PV
- Cloud providers use this (AWS EBS, GCP, Azure)

### Storage Classes

StorageClass is a template for provisioning PVs:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: kubernetes.io/aws-ebs # AWS specific
parameters:
  type: gp3
  iops: "1000"
```

---

## 💡 Best Practices

✅ **DO:**

- Use PVC to decouple storage from Pods
- Use StatefulSets for stateful applications
- Set reclaim policy intentionally (Retain or Delete)
- Monitor storage usage
- Plan capacity ahead

❌ **DON'T:**

- Use local hostPath for production (nodes can fail)
- Assume PV reclaim policy default (it's Retain)
- Store data in Pod filesystem (ephemeral)
- Forget to delete PVCs when done
- Use Deployments for databases (use StatefulSet)

---

## ✅ Exercise Completion Checklist

- [ ] Created PersistentVolumes (local storage)
- [ ] Created PersistentVolumeClaim
- [ ] Verified PVC bound to PV
- [ ] Mounted PVC in Pod
- [ ] Verified data persists across Pod deletion
- [ ] Observed PV reclaim policy
- [ ] Deployed StatefulSet with persistent storage
- [ ] Verified each StatefulSet Pod gets own PVC
- [ ] Understood storage architecture and lifecycle
- [ ] Ready to move to Module 03

---

## 🎓 Next Steps

Once complete, move to **Module 03** (`03-advanced/scheduling/exercise.md`) to learn pod scheduling and affinity.

## 📚 Reference Templates

Check `/templates/pvc-template.yaml` and see storage configuration patterns.
