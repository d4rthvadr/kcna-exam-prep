# Exercise: ConfigMaps & Secrets - Application Configuration

## 📌 Problem Statement

Manage application configuration and sensitive data in Kubernetes. ConfigMaps store non-sensitive configuration while Secrets store sensitive data like passwords and tokens. You'll learn to inject configuration into Pods using environment variables and volume mounts.

## 🎯 Learning Objectives

By completing this exercise, you will be able to:

1. Create and manage ConfigMaps (literal and file-based)
2. Create and manage Secrets (Opaque type)
3. Inject ConfigMaps as environment variables
4. Inject Secrets as environment variables
5. Mount ConfigMaps as volumes
6. Mount Secrets as volumes
7. Update configuration without redeploying
8. Understand security implications of Secrets

## 📝 Exercises

### Exercise 1.1: Create ConfigMap (Literal)

**Objective:** Create a ConfigMap with key-value pairs and inject into Pod.

**Instructions:**

1. Create ConfigMap with application settings:

   ```bash
   kubectl create configmap app-config \
     --from-literal=APP_ENV=production \
     --from-literal=LOG_LEVEL=info \
     --from-literal=DB_HOST=postgres.default.svc.cluster.local \
     --from-literal=DB_PORT=5432
   ```

2. Verify ConfigMap was created

**Verification Steps:**

```bash
# View ConfigMaps
kubectl get configmaps

# Describe ConfigMap
kubectl describe configmap app-config

# View ConfigMap as YAML
kubectl get configmap app-config -o yaml

# Get specific key
kubectl get configmap app-config -o jsonpath='{.data.APP_ENV}'
```

**Expected Outcomes:**

- ConfigMap shows 4 data keys (APP_ENV, LOG_LEVEL, DB_HOST, DB_PORT)
- Each key has its value
- Size shows the total data size
- Can retrieve values with jsonpath

---

### Exercise 1.2: Use ConfigMap as Environment Variables

**Objective:** Inject ConfigMap values into Pod environment variables.

**Instructions:**

1. Create a file `pod-with-config-env.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
spec:
  containers:
    - name: app
      image: busybox:latest
      command: ["sh", "-c"]
      args:
        - |
          echo "Environment variables from ConfigMap:"
          echo "APP_ENV: $APP_ENV"
          echo "LOG_LEVEL: $LOG_LEVEL"
          echo "DB_HOST: $DB_HOST"
          sleep 3600
      env:
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_ENV
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: LOG_LEVEL
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: DB_HOST
        - name: DB_PORT
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: DB_PORT
```

2. Apply the pod YAML
3. Check pod logs to see environment variables

**Verification Steps:**

```bash
# Apply pod
kubectl apply -f pod-with-config-env.yaml

# View pod
kubectl get pod config-pod

# View logs - should show environment variables
kubectl logs config-pod

# Exec into pod and check env
kubectl exec config-pod -- env | grep -E 'APP_ENV|LOG_LEVEL|DB'

# View pod definition
kubectl get pod config-pod -o yaml | grep -A 20 env:
```

**Expected Outcomes:**

- Pod starts and runs successfully
- Logs show environment variables with correct values from ConfigMap
- `env` command shows all injected variables
- Pod can access configuration without hardcoding

---

### Exercise 1.3: ConfigMap as Volume Mount

**Objective:** Mount ConfigMap as configuration files in Pod.

**Instructions:**

1. Create a ConfigMap with file content:

```bash
# Create app.conf file content
cat > app.conf <<EOF
server.port=8080
server.servlet.context-path=/api
logging.level=INFO
database.pool.size=10
EOF

# Create ConfigMap from file
kubectl create configmap app-conf-file --from-file=app.conf
```

2. Create pod that mounts the ConfigMap as a volume:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-volume-pod
spec:
  containers:
    - name: app
      image: busybox:latest
      command: ["cat"]
      args: ["/etc/config/app.conf"]
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
          readOnly: true
  volumes:
    - name: config-volume
      configMap:
        name: app-conf-file
```

3. Apply pod and verify configuration file is accessible

**Verification Steps:**

```bash
# Create and apply pod
kubectl apply -f config-volume-pod.yaml

# Pod will exit after cat (expected)
# View logs to see file contents
kubectl logs config-volume-pod

# Exec into a longer-running pod to test
kubectl run test-pod --image=busybox sleep 3600 &
kubectl exec -it test-pod -- cat /mnt/config/app.conf  # if mounted

# Check pod description
kubectl describe pod config-volume-pod
```

**Expected Outcomes:**

- Pod successfully mounts ConfigMap as volume
- File `/etc/config/app.conf` contains configuration
- File is readable by application
- Configuration is separated from container image

---

### Exercise 1.4: Create Secret

**Objective:** Create and manage a Secret for sensitive data.

**Instructions:**

1. Create a Secret with sensitive information:

```bash
kubectl create secret generic app-secrets \
  --from-literal=database-password=db-secret-123 \
  --from-literal=api-key=sk-abc123xyz789
```

2. Verify Secret was created
3. Note: Secrets are base64-encoded, NOT encrypted by default

**Verification Steps:**

```bash
# View Secrets
kubectl get secrets

# Describe Secret (shows keys but not values)
kubectl describe secret app-secrets

# View Secret as YAML
kubectl get secret app-secrets -o yaml

# Decode base64 to see actual value
kubectl get secret app-secrets -o jsonpath='{.data.database-password}' | base64 -d

# Security note: Anyone with kubectl access can decode secrets!
# Use encryption at rest in production
```

**Expected Outcomes:**

- Secret created with sensitive data
- Values are base64-encoded in YAML
- Can decode with base64 (but not truly encrypted)
- Type shows "Opaque" (default secret type)

**Important:** Base64 is encoding, NOT encryption. Anyone with cluster access can decode!

---

### Exercise 1.5: Use Secret as Environment Variables

**Objective:** Inject Secret values as environment variables.

**Instructions:**

1. Create pod with Secret environment variables:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-env-pod
spec:
  containers:
    - name: app
      image: busybox:latest
      command: ["sh", "-c"]
      args:
        - |
          echo "API Key: $API_KEY"
          echo "Database Password Length: ${#DB_PASSWORD}"
          sleep 3600
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-password
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: api-key
```

2. Apply pod and verify secret values are available as env vars

**Verification Steps:**

```bash
# Apply pod
kubectl apply -f secret-env-pod.yaml

# View logs
kubectl logs secret-env-pod

# Exec and check environment
kubectl exec secret-env-pod -- env | grep -E 'DB_PASSWORD|API_KEY'

# Verify secrets are not in pod logs by default
kubectl logs secret-env-pod | grep -i "secret"  # Should show nothing
```

**Expected Outcomes:**

- Pod runs with Secret values as environment variables
- Secrets can be used by application
- Logs don't accidentally expose secret values (good practice)
- Application can access secrets needed for operation

---

### Exercise 1.6: Secret as Volume Mount

**Objective:** Mount Secret as files in Pod filesystem.

**Instructions:**

1. Create pod that mounts Secret as volume:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-pod
spec:
  containers:
    - name: app
      image: busybox:latest
      command: ["sh", "-c"]
      args:
        - |
          echo "Mounted secret files:"
          ls -la /etc/secrets/
          echo ""
          echo "Database password from file:"
          cat /etc/secrets/database-password
          sleep 3600
      volumeMounts:
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
  volumes:
    - name: secret-volume
      secret:
        secretName: app-secrets
        defaultMode: 0400 # Read-only for owner
```

2. Apply and verify Secret files are mounted

**Verification Steps:**

```bash
# Apply pod
kubectl apply -f secret-volume-pod.yaml

# View logs showing mounted files
kubectl logs secret-volume-pod

# Exec and list files
kubectl exec secret-volume-pod -- ls -la /etc/secrets/

# Read secret file
kubectl exec secret-volume-pod -- cat /etc/secrets/database-password

# Check file permissions (0400 = read-only)
kubectl exec secret-volume-pod -- stat /etc/secrets/database-password
```

**Expected Outcomes:**

- Secret files mounted at `/etc/secrets/`
- Each key becomes a separate file
- File content contains the secret value (not base64)
- Files are read-only (mode 0400)
- Application can read secrets from files

**Use Case:** Applications that read from config files instead of environment variables

---

### Exercise 1.7: Update ConfigMap and Observe Impact

**Objective:** Understand that Pod env vars don't update automatically, but volumes do.

**Instructions:**

1. Update the ConfigMap:

   ```bash
   kubectl patch configmap app-config -p '{"data":{"LOG_LEVEL":"debug"}}'
   ```

2. Check if Pod environment variables update (they won't)
3. Check if Pod with volume mount updates (it will)

**Verification Steps:**

```bash
# Update ConfigMap
kubectl patch configmap app-config -p '{"data":{"LOG_LEVEL":"debug"}}'

# Verify ConfigMap updated
kubectl get configmap app-config -o jsonpath='{.data.LOG_LEVEL}'

# Check config-pod (env var pod) - won't update
kubectl exec config-pod -- sh -c 'echo $LOG_LEVEL'  # Still shows "info"

# Check config-volume-pod (volume mount pod) - will update
# Need to recreate pod to see file:
kubectl delete pod config-volume-pod
kubectl apply -f config-volume-pod.yaml
kubectl logs config-volume-pod
```

**Expected Outcomes:**

- ConfigMap update is immediate
- Environment Variable Pods: Changes don't take effect (static at pod creation)
- Volume Mount Pods: Changes visible immediately (file updated)
- To get env var updates: Must recreate Pod

**Key Learning:** Volume mounts are better for configuration that changes because files are updated in-place

---

### Exercise 1.8: Create Secret from File

**Objective:** Create Secret from existing file (e.g., certificates, keys).

**Instructions:**

1. Create a certificate file:

   ```bash
   # Create a dummy cert (real ones would be from 'openssl genkey' etc)
   cat > tls.crt <<EOF
   -----BEGIN CERTIFICATE-----
   MIICljCCAX4CCQDPzn...
   -----END CERTIFICATE-----
   EOF

   cat > tls.key <<EOF
   -----BEGIN PRIVATE KEY-----
   MIIEvQIBADANBgkq...
   -----END PRIVATE KEY-----
   EOF
   ```

2. Create Secret from files:

   ```bash
   kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key
   ```

3. Verify and use in Pod

**Verification Steps:**

```bash
# View Secret
kubectl get secret tls-secret -o yaml

# Create pod using certificate
kubectl run tls-pod --image=busybox -- sleep 3600

# Mount secret
kubectl set env pod/tls-pod --from=secret/tls-secret

# Or edit pod to mount as volume
```

**Expected Outcomes:**

- Secret created with tls.crt and tls.key
- Type shows "kubernetes.io/tls"
- Can be used by TLS-enabled applications

---

### Exercise 1.9: Cleanup

**Objective:** Delete ConfigMaps and Secrets.

**Verification Steps:**

```bash
# Delete ConfigMaps
kubectl delete configmap app-config
kubectl delete configmap app-conf-file

# Delete Secrets
kubectl delete secret app-secrets
kubectl delete secret tls-secret

# Delete pods
kubectl delete pod config-pod
kubectl delete pod config-volume-pod
kubectl delete pod secret-env-pod
kubectl delete pod secret-volume-pod

# Verify cleanup
kubectl get configmaps
kubectl get secrets
kubectl get pods
```

**Expected Outcomes:**

- All ConfigMaps and Secrets removed
- All test Pods removed

---

## 🧠 Key Concepts Explained

### ConfigMap vs Secret

| Feature    | ConfigMap                  | Secret                   |
| ---------- | -------------------------- | ------------------------ |
| Purpose    | Non-sensitive config       | Sensitive data           |
| Encoding   | Plain text                 | Base64 (not encrypted)   |
| Size limit | 1MB                        | 1MB                      |
| Use case   | App settings, config files | Passwords, tokens, certs |
| Visibility | Visible to all             | Should be restricted     |

### ConfigMap Types

**Literal (key-value):**

```bash
kubectl create configmap name --from-literal=key=value
```

**From File:**

```bash
kubectl create configmap name --from-file=filename
# File content becomes the value, filename becomes the key
```

**From Directory:**

```bash
kubectl create configmap name --from-file=/path/to/dir/
# Each file in directory becomes a key
```

### Injection Methods

**Environment Variables:**

- Statically set when Pod created
- Don't update if ConfigMap/Secret changes
- Simple for small configs

**Volume Mount:**

- Files dynamically mounted
- Update in-place if source changes
- Better for large configs or certificates

### Secret Types

- **Opaque** (default): Arbitrary user-defined data
- **kubernetes.io/service-account-token**: Auto-generated ServiceAccount tokens
- **kubernetes.io/dockercfg**: Docker registry credentials
- **kubernetes.io/dockerconfigjson**: Docker registry config
- **kubernetes.io/basic-auth**: Basic authentication (deprecated, use Opaque)
- **kubernetes.io/ssh-auth**: SSH key credentials
- **kubernetes.io/tls**: TLS certificate and key
- **bootstrap.kubernetes.io/token**: Bootstrap token

---

## 💡 Security Best Practices

✅ **DO:**

- Use Secrets for sensitive data (passwords, API keys, certificates)
- Use RBAC to limit who can read Secrets
- Use encryption at rest in production
- Rotate secrets regularly
- Keep secrets out of version control
- Use temporary credentials when possible

❌ **DON'T:**

- Store secrets in ConfigMaps (no encryption)
- Commit secrets to git
- Log sensitive environment variables
- Use default Secret storage (no encryption by default)
- Assume base64 encoding is secure (it's not)
- Hardcode credentials in application code

---

## ✅ Exercise Completion Checklist

- [ ] Created ConfigMap with literal key-value pairs
- [ ] Injected ConfigMap as environment variables
- [ ] Mounted ConfigMap as configuration files
- [ ] Created Secret with sensitive data
- [ ] Injected Secret as environment variables
- [ ] Mounted Secret as files in filesystem
- [ ] Understood difference between env var and volume mount updates
- [ ] Created Secret from files (certificates)
- [ ] Cleaned up all ConfigMaps and Secrets
- [ ] Understand ConfigMap vs Secret purposes
- [ ] Ready to move to Storage exercises

---

## 🎓 Next Steps

Once complete, move to `storage/exercise.md` to learn about persistent data storage.

## 📚 Reference Templates

Check `/templates/configmap-template.yaml` and `/templates/secret-template.yaml` for boilerplate.
