# Exercise: Jobs & CronJobs - Workload Management

## 📌 Problem Statement

Run containerized workloads to completion (Jobs) and on schedule (CronJobs). Learn how to handle batch processing, parallel execution, and scheduled tasks in Kubernetes.

## 🎯 Learning Objectives

By completing this exercise, you will be able to:

1. Create and manage Jobs for one-time workloads
2. Configure Job parallelism and completion count
3. Handle Job failures and retries
4. Create and schedule CronJobs
5. Monitor Job status and logs
6. Clean up completed Jobs
7. Understand Job controller patterns

## 📝 Exercises

### Exercise 1.1: Simple Job

**Objective:** Create a Job that runs a task to completion.

**Instructions:**

1. Create a simple job:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: hello-job
spec:
  template:
    spec:
      containers:
        - name: hello
          image: busybox:latest
          command: ["echo"]
          args: ["Hello from Job"]
      restartPolicy: Never
  backoffLimit: 3 # Retry up to 3 times
```

2. Apply job and monitor completion

**Verification Steps:**

```bash
# Apply job
kubectl apply -f hello-job.yaml

# View job
kubectl get jobs

# Detailed job info
kubectl get job hello-job -o wide

# Describe job
kubectl describe job hello-job

# Watch job progress
watch kubectl get job hello-job

# View pod created by job
kubectl get pods -l job-name=hello-job

# View job output
kubectl logs -l job-name=hello-job

# Job completion status
kubectl get job hello-job -o jsonpath='{.status.succeeded}'
```

**Expected Outcomes:**

- Job created and pod starts running
- Pod runs to completion (exit code 0)
- Job shows: Completions 1/1
- Pod shows: Completed
- Job doesn't create new pods

---

### Exercise 1.2: Job with Retries

**Objective:** Test Job retry mechanism on failure.

**Instructions:**

1. Create job that might fail:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: retry-job
spec:
  backoffLimit: 4
  template:
    spec:
      containers:
        - name: app
          image: busybox:latest
          command: ["sh", "-c"]
          args:
            - |
              echo "Attempt $(date +%s%N | cut -b1-3)"
              [ $(date +%s) % 2 -eq 0 ] && exit 1 || exit 0
      restartPolicy: Never
```

2. Monitor Job retrying on failure

**Verification Steps:**

```bash
# Apply job
kubectl apply -f retry-job.yaml

# Watch job retry
watch kubectl get job retry-job

# Check pod count (should see multiple)
watch kubectl get pods -l job-name=retry-job

# Describe job to see retry history
kubectl describe job retry-job | grep -A 10 Events

# View logs of different pods
kubectl logs -l job-name=retry-job --tail=5

# Job completes when one pod succeeds
```

**Expected Outcomes:**

- Job creates pods when previous ones fail
- Retries up to backoffLimit (4)
- If all retries fail, Job status: Failed
- If any pod succeeds, Job status: Succeeded
- Retry delays increase exponentially (backoff)

**Retry Behavior:**

```
Attempt 1: Immediate
Attempt 2: 10s wait
Attempt 3: 20s wait
Attempt 4: 40s wait
(exponential backoff)
```

---

### Exercise 1.3: Job with Parallelism

**Objective:** Run multiple pods for a job in parallel.

**Instructions:**

1. Create job with parallel pods:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-job
spec:
  completions: 6 # Need 6 successful completions
  parallelism: 2 # Run 2 pods at a time
  template:
    spec:
      containers:
        - name: worker
          image: busybox:latest
          command: ["sh", "-c"]
          args:
            - |
              echo "Worker $(hostname) starting..."
              sleep 30
              echo "Worker $(hostname) completed"
      restartPolicy: Never
  backoffLimit: 3
```

2. Monitor parallel pod creation

**Verification Steps:**

```bash
# Apply job
kubectl apply -f parallel-job.yaml

# Watch pods created in batches
watch 'kubectl get pods -l job-name=parallel-job'

# Should see:
# Batch 1: 2 pods (running)
# Batch 2: 2 pods (after batch 1 done)
# Batch 3: 2 pods (after batch 2 done)

# Check job status
kubectl describe job parallel-job

# View pod names (should show multiple)
kubectl get pods -l job-name=parallel-job -o jsonpath='{.items[*].metadata.name}'

# Monitor completion
watch kubectl get job parallel-job

# Job completes when 6 pods succeed
```

**Expected Outcomes:**

- Job creates pods in batches of `parallelism`
- As pods complete, new ones start
- Continues until `completions` pods finish
- Useful for distributed workloads

**Parallelism Scenarios:**

```
completions: 10, parallelism: 1  # Sequential: 1 pod at a time
completions: 10, parallelism: 3  # 3 pods in parallel
completions: 5, parallelism: 0   # No pods (use for manual control)
```

---

### Exercise 1.4: Job Suspension and Resumption

**Objective:** Pause and resume running jobs.

**Instructions:**

1. Create a job with long-running pods:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: can-suspend-job
spec:
  completions: 5
  parallelism: 2
  suspend: false # Job is NOT suspended
  template:
    spec:
      containers:
        - name: worker
          image: busybox:latest
          command: ["sleep"]
          args: ["300"] # 5 minute sleep
      restartPolicy: Never
```

2. Start job, then suspend it
3. Resume and continue

**Verification Steps:**

```bash
# Apply job
kubectl apply -f can-suspend-job.yaml

# Pods start running
kubectl get pods -l job-name=can-suspend-job

# Suspend the job
kubectl patch job can-suspend-job -p '{"spec":{"suspend":true}}'

# Pods terminate
watch kubectl get pods -l job-name=can-suspend-job

# Job shows suspended
kubectl get job can-suspend-job

# Resume the job
kubectl patch job can-suspend-job -p '{"spec":{"suspend":false}}'

# Pods start again
watch kubectl get pods -l job-name=can-suspend-job

# Job continues to completion
kubectl get job can-suspend-job
```

**Expected Outcomes:**

- Job suspended: Running pods terminated
- Job resumed: Pods restart (from beginning, not resumed)
- Useful for: Maintenance windows, resource constraints, cost optimization

---

### Exercise 1.5: Simple CronJob

**Objective:** Schedule jobs to run on a schedule.

**Instructions:**

1. Create a CronJob:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello-cronjob
spec:
  schedule: "*/2 * * * *" # Every 2 minutes
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: hello
              image: busybox:latest
              command:
                - /bin/sh
                - -c
                - echo "$(date): Hello from CronJob"
          restartPolicy: OnFailure
  successfulJobsHistoryLimit: 3 # Keep last 3 successful jobs
  failedJobsHistoryLimit: 1 # Keep last 1 failed job
```

2. Monitor scheduled job execution

**Verification Steps:**

```bash
# Apply cronjob
kubectl apply -f hello-cronjob.yaml

# View cronjob
kubectl get cronjobs

# Describe cronjob
kubectl describe cronjob hello-cronjob

# Watch jobs being created
watch kubectl get jobs

# Jobs created on schedule
kubectl get jobs -l job-name~=hello-cronjob

# View logs of latest job
LATEST_JOB=$(kubectl get jobs -l job-name~=hello-cronjob -o jsonpath='{.items[-1].metadata.name}')
kubectl logs -l job-name=$LATEST_JOB

# View next schedule
kubectl get cronjob hello-cronjob -o jsonpath='{.status.lastScheduleTime}'
```

**Expected Outcomes:**

- CronJob creates Jobs on schedule (every 2 minutes)
- Each Job creates a Pod
- Pod runs to completion
- Keep old jobs based on history limits
- Can see when next run is scheduled

**Cron Schedule Format:**

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
│ │ │ │ │
* * * * *
```

**Examples:**

- `0 0 * * *` - Every day at midnight
- `*/5 * * * *` - Every 5 minutes
- `0 2 * * 0` - Every Monday at 2 AM
- `30 3 * * MON-FRI` - Weekdays at 3:30 AM

---

### Exercise 1.6: CronJob with Timezone

**Objective:** Schedule CronJobs in specific timezone.

**Instructions:**

1. Create CronJob with timezone:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: timezone-cronjob
spec:
  timeZone: "America/New_York" # Set timezone
  schedule: "0 9 * * MON" # 9 AM Monday EST
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: app
              image: busybox:latest
              command:
                - /bin/sh
                - -c
                - date
          restartPolicy: OnFailure
```

2. Verify scheduling uses correct timezone

**Verification Steps:**

```bash
# Apply cronjob
kubectl apply -f timezone-cronjob.yaml

# Check status
kubectl describe cronjob timezone-cronjob

# View job template
kubectl get cronjob timezone-cronjob -o yaml
```

---

### Exercise 1.7: CronJob Concurrency Control

**Objective:** Control how CronJobs handle overlapping runs.

**Instructions:**

1. Create CronJob with short interval but long-running task:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: long-running-cronjob
spec:
  schedule: "*/5 * * * *" # Every 5 minutes
  concurrencyPolicy: Forbid # Don't run if previous still running
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: app
              image: busybox:latest
              command:
                - sleep
                - "600" # 10 minute sleep
          restartPolicy: OnFailure
```

2. Monitor behavior with overlapping schedules

**Verification Steps:**

```bash
# Apply cronjob
kubectl apply -f long-running-cronjob.yaml

# Watch jobs - should see one job per slot
# If next schedule arrives before job completes:
# - Forbid: Skip that run
# - Allow: Create new job (same job running twice)
# - Replace: Cancel previous, start new

kubectl describe cronjob long-running-cronjob | grep -A 5 Events
```

**Concurrency Policies:**

- `Allow`: Multiple jobs can run simultaneously
- `Forbid`: Skip run if previous job still running (default)
- `Replace`: Cancel previous job, start new one

---

### Exercise 1.8: Job and CronJob Status & Cleanup

**Objective:** Monitor and clean up jobs.

**Instructions:**

1. Create various jobs and monitor status

**Verification Steps:**

```bash
# View all jobs
kubectl get jobs

# Get detailed status
kubectl get job <name> -o wide

# Check job completion time
kubectl get job <name> -o jsonpath='{.status.completionTime}'

# View job conditions
kubectl get job <name> -o jsonpath='{.status.conditions}'

# Manual job trigger from cronjob
kubectl create job <name> --from=cronjob/<cronjob-name>

# Delete finished jobs
kubectl delete job hello-job
kubectl delete job retry-job

# Delete cronjob (and its jobs)
kubectl delete cronjob hello-cronjob

# Delete old jobs matching pattern
kubectl delete job -l job-name~=hello-cronjob

# Clean all jobs
kubectl delete job --all

# Verify cleanup
kubectl get jobs
kubectl get cronjobs
```

---

## 🧠 Key Concepts Explained

### Job Status Flow

```
Created
  ↓
Active (pods running)
  ↓
Succeeded (desired completions reached) or Failed
```

**Job Conditions:**

- `type: Complete` - All desired pods completed
- `type: Failed` - Job failed (exceeded backoffLimit)
- `type: Suspended` - Job is suspended

### Job vs Deployment vs StatefulSet

| Resource        | Purpose                | Pod Count | Restart         |
| --------------- | ---------------------- | --------- | --------------- |
| **Job**         | Task to completion     | Variable  | Only on failure |
| **Deployment**  | Always running service | Fixed     | Always          |
| **StatefulSet** | Stateful service       | Fixed     | Always          |

### CronJob Structure

```
CronJob (schedule + concurrency)
  ↓ (creates on schedule)
Job (completions + parallelism)
  ↓ (creates pods)
Pods (runs to completion)
```

### Parallelism Patterns

**1. Simple Queue Pattern**

```yaml
completions: 5
parallelism: 1 # Process one item at a time
```

**2. Distributed Processing**

```yaml
completions: 10
parallelism: 4 # Process 4 items in parallel
```

**3. Single Run**

```yaml
completions: 1
parallelism: 1 # Just run once
```

---

## 💡 Best Practices

✅ **DO:**

- Always set `restartPolicy: Never` for Jobs (unless special case)
- Set appropriate `backoffLimit` (usually 3-6)
- Use `parallelism` for distributed work
- Set `successfulJobsHistoryLimit` to avoid clutter
- Monitor CronJob status regularly

❌ **DON'T:**

- Use Jobs for always-running services (use Deployment)
- Set extremely large parallelism (overload cluster)
- Forget to clean up old jobs (consume storage)
- Use too short cron schedule (can overlap)
- Assume CronJob runs on exact schedule (can be delayed)

---

## ✅ Exercise Completion Checklist

- [ ] Created simple Job to completion
- [ ] Observed Job retry mechanism
- [ ] Ran Job with parallelism
- [ ] Suspended and resumed a Job
- [ ] Created and tested CronJob
- [ ] Scheduled job on specific time/day
- [ ] Controlled CronJob concurrency
- [ ] Monitored Job and CronJob status
- [ ] Cleaned up completed jobs
- [ ] Understand Job patterns and use cases
- [ ] Ready to move to Module 04 (Security)

---

## 🎓 Next Steps

Once complete, move to **Module 04** (`04-expert-security/rbac/exercise.md`) to learn access control.

## 📚 Reference Templates

Check `/templates/job-template.yaml` and `/templates/cronjob-template.yaml` for boilerplate.
