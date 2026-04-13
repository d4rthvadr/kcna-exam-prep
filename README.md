# CKNA Exam Preparation - Progressive Learning Path

This repository is a structured learning guide for **KCNA (Kubernetes and Cloud Native Associate)** exam preparation. Through hands-on exercises organized by difficulty level, you'll build practical expertise in Kubernetes and cloud-native technologies.

## 📋 Exam Overview

The KCNA certification validates foundational knowledge across five domains:
- **25%** Kubernetes Fundamentals (pods, deployments, services, namespaces)
- **46%** Container Orchestration (scaling, updates, self-healing, networking)
- **16%** Cloud Native Architecture (patterns, microservices, 12-factor apps)
- **8%** Cloud Native Observability (logging, metrics, tracing)
- **5%** Cloud Native Application Delivery (deployments, rollovers, rollbacks)

## 🚀 Getting Started

### Prerequisites
- Kubernetes intermediate experience (kubectl basics, familiar with deployments/services)
- Local Kubernetes cluster (minikube, kind, or Docker Desktop)
- kubectl installed
- Basic shell scripting knowledge

### Setup
1. **Initialize your cluster:**
   ```bash
   chmod +x setup/cluster-setup.sh
   ./setup/cluster-setup.sh
   ```

2. **Verify cluster is ready:**
   ```bash
   chmod +x setup/verify-setup.sh
   ./setup/verify-setup.sh
   ```

## 📚 Learning Modules

Work through modules sequentially. Each module builds on previous knowledge.

| Module | Focus | Topics | Time |
|--------|-------|--------|------|
| **01-beginner** | Core K8s Objects | Pods, Deployments, Services, ReplicaSets | 2-3 days |
| **02-intermediate** | Configuration & State | ConfigMaps, Secrets, PersistentVolumes, StatefulSets | 2-3 days |
| **03-advanced** | Scheduling & Lifecycle | Labels, Affinity, Taints, Resource Limits, Probes, CronJobs | 2-3 days |
| **04-expert-security** | Access Control & Security | RBAC, ServiceAccounts, NetworkPolicies, SecurityContexts | 2-3 days |
| **05-expert-operations** | Operations & Observability | Rollouts, Scaling (HPA/VPA), Metrics, Troubleshooting | 2-3 days |

## 📖 How to Use This Repository

### Exercise Structure

Each exercise follows this format:

1. **Problem Statement** - What you need to build/configure
2. **Objectives** - Key learning outcomes
3. **Verification Steps** - kubectl commands to validate your solution
4. **Expected Outcomes** - What success looks like

### Your Workflow

1. **Read** the exercise problem statement and objectives
2. **Write** YAML manifests based on requirements (use templates for boilerplate)
3. **Deploy** your solution: `kubectl apply -f your-manifest.yaml`
4. **Verify** using provided kubectl commands
5. **Troubleshoot** if needed - inspect pods, events, logs with kubectl
6. **Move on** once all verification steps pass

### Tips

- **Use templates** in `/templates` directory as starting points
- **Refer to cheatsheet.md** for common kubectl commands
- **Test locally first** - deploy to your local cluster before reviewing
- **Learn from failures** - use `kubectl describe` and `kubectl logs` to understand issues
- **Group related resources** - create directories per exercise for organized YAML files

## 🛠️ Resources

- **templates/** - Boilerplate YAML files to accelerate exercise completion
- **cheatsheet.md** - Quick kubectl command reference organized by domain
- **setup/** - Scripts for cluster initialization and verification
- **Each module's README** - Module-specific objectives and guidance

## ⏱️ Timeline Suggestion

For 1-2 week intensive preparation:
- **Week 1**: Complete modules 01-02 (Core objects + Configuration)
- **Week 2**: Complete modules 03-04 (Scheduling + Security)
- **Final days**: Module 05 (Operations) + Review weak areas

For self-paced learning: 1 module per week over 5 weeks.

## ✅ Success Criteria

You're ready for the exam when you can:
- ✅ Create and manage all core Kubernetes objects from scratch
- ✅ Configure applications with ConfigMaps, Secrets, and Volumes
- ✅ Solve scheduling challenges with affinity, taints, and resource limits
- ✅ Implement RBAC and network policies from requirements
- ✅ Troubleshoot deployments, scaling issues, and application problems
- ✅ Complete mixed-domain scenarios under time pressure

## 🔄 Validation Approach

Solutions are validated by:
1. **Manual deployment** - You apply YAML to your cluster
2. **kubectl verification** - Running provided commands to check state
3. **Behavior testing** - Confirming resources behave as required
4. **Optional AI review** - Get second opinions on solutions or troubleshooting

## 📝 Notes

- All exercises use `default` namespace unless otherwise specified
- Manifests should be idempotent (can be applied multiple times safely)
- Use descriptive names for resources (e.g., `nginx-deployment`, not `deploy1`)
- Delete resources after completing exercises to keep cluster clean: `kubectl delete -f <manifest.yaml>`

---

**Good luck with your KCNA exam preparation!** 🎯

Start with **01-beginner/README.md** for module-specific guidance.
