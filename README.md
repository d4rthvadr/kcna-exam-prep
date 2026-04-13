# CKNA Exam Preparation - Progressive Learning Path

This repository is a structured learning guide for **KCNA (Kubernetes and Cloud Native Associate)** exam preparation. Through hands-on exercises organized by difficulty level, you'll build practical expertise in Kubernetes and cloud-native technologies.

## Exam Overview

The KCNA certification validates foundational knowledge across five domains:

- **25%** Kubernetes Fundamentals (pods, deployments, services, namespaces)
- **46%** Container Orchestration (scaling, updates, self-healing, networking)
- **16%** Cloud Native Architecture (patterns, microservices, 12-factor apps)
- **8%** Cloud Native Observability (logging, metrics, tracing)
- **5%** Cloud Native Application Delivery (deployments, rollovers, rollbacks)

## Getting Started

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

## Learning Modules

Work through modules sequentially. Each module builds on previous knowledge.

| Module                   | Focus                      | Topics                                                      | Time     |
| ------------------------ | -------------------------- | ----------------------------------------------------------- | -------- |
| **01-beginner**          | Core K8s Objects           | Pods, Deployments, Services, ReplicaSets                    | 2-3 days |
| **02-intermediate**      | Configuration & State      | ConfigMaps, Secrets, PersistentVolumes, StatefulSets        | 2-3 days |
| **03-advanced**          | Scheduling & Lifecycle     | Labels, Affinity, Taints, Resource Limits, Probes, CronJobs | 2-3 days |
| **04-expert-security**   | Access Control & Security  | RBAC, ServiceAccounts, NetworkPolicies, SecurityContexts    | 2-3 days |
| **05-expert-operations** | Operations & Observability | Rollouts, Scaling (HPA/VPA), Metrics, Troubleshooting       | 2-3 days |

## How to Use This Repository

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

## Resources

- **templates/** - Boilerplate YAML files to accelerate exercise completion
- **cheatsheet.md** - Quick kubectl command reference organized by domain
- **setup/** - Scripts for cluster initialization and verification
- **Each module's README** - Module-specific objectives and guidance
- **exam-tips.md** - Exam format, strategies, and domain-specific guidance
- **learning-summary.md** - Concept review organized by module
- **mock-scenarios.md** - 15+ realistic KCNA exam-style questions with answers
- **NAVIGATION.md** - Multiple study paths tailored to your experience level

## Interactive Quizzing with the Quiz Generator

This repository includes a **Copilot Skill** that generates dynamic, customized quizzes from all course materials. Use it to practice, self-assess, and prepare for the exam.

### Getting Started with Quizzes

Open VS Code Copilot Chat and use the `/quiz` command:

```
/quiz Generate a 10-question practice quiz on ConfigMaps and Secrets
/quiz quiz me on RBAC (intermediate level)
/quiz Create a 60-question KCNA mock exam
/quiz Quick 3-question check on Deployment strategies
```

### What the Quiz Generator Does

**Quiz Types:**

- **Multiple Choice** (4 options) - Standard exam format
- **Scenario Based** - Real-world Kubernetes problems requiring diagnosis
- **Command Challenge** - Write kubectl commands or YAML to solve problems
- **True/False** - Quick concept validation
- **Fill-in-the-Blank** - Command syntax or configuration details
- **Matching** - Pair concepts with definitions or use cases

**Customization:**

- Filter by difficulty (Beginner → Intermediate → Advanced → Expert)
- Select specific modules or topics (RBAC, Storage, Networking, Deployments, Observability)
- Choose question count (1-50) and time limits
- Mix formats for variety or focus on one type

**Feedback & Scoring:**

- Instant explanations for correct/incorrect answers
- Links to relevant exercises and topics
- Score breakdown by domain (like the actual KCNA exam)
- Performance tracking across quizzes
- Recommendations for weak areas

### Example Quiz Commands

**Quick Practice (5-10 min):**

```
/quiz 5 true-false questions on Services and Ingress (beginner level)
/quiz 3 command-challenge questions on StatefulSets
```

**Focused Study (15-30 min):**

```
/quiz 15-question practice quiz on NetworkPolicies and RBAC (intermediate)
/quiz 20-question mixed quiz on Module 03 (Scheduling & Lifecycle)
```

**Full Mock Exam (90 min):**

```
/quiz Create a 60-question KCNA mock exam
/quiz Full exam simulation with 90-minute timer
```

**Progress Review:**

```
/quiz Show my quiz history and weak areas
/quiz Spaced repetition quiz on topics I struggled with
```

### Study Strategy with Quizzes

1. **After completing an exercise** → Take a 3-5 question quick quiz on that topic
2. **End of each module** → Take a 15-20 question module assessment
3. **Before exam** → Take full 60-question mock exams
4. **Weak areas** → Use spaced-repetition quizzes for review

### Scoring Interpretation

| Score   | Status            | Recommendation                   |
| ------- | ----------------- | -------------------------------- |
| 90-100% | Exam-ready        | Take the test immediately        |
| 80-89%  | Strong foundation | 1-2 targeted reviews             |
| 70-79%  | Solid progress    | Focused study on weak domains    |
| 60-69%  | Needs improvement | Return to foundational exercises |
| <60%    | Significant gaps  | Review module content and basics |

The KCNA exam requires **66-70% to pass**, so aim for 80%+ average on practice quizzes.

## Timeline Suggestion

For 1-2 week intensive preparation:

- **Week 1**: Complete modules 01-02 (Core objects + Configuration)
- **Week 2**: Complete modules 03-04 (Scheduling + Security)
- **Final days**: Module 05 (Operations) + Review weak areas

For self-paced learning: 1 module per week over 5 weeks.

## Success Criteria

You're ready for the exam when you can:

- Create and manage all core Kubernetes objects from scratch
- Configure applications with ConfigMaps, Secrets, and Volumes
- Solve scheduling challenges with affinity, taints, and resource limits
- Implement RBAC and network policies from requirements
- Troubleshoot deployments, scaling issues, and application problems
- Complete mixed-domain scenarios under time pressure

## Validation Approach

Solutions are validated by:

1. **Manual deployment** - You apply YAML to your cluster
2. **kubectl verification** - Running provided commands to check state
3. **Behavior testing** - Confirming resources behave as required
4. **Optional AI review** - Get second opinions on solutions or troubleshooting

## Notes

- All exercises use `default` namespace unless otherwise specified
- Manifests should be idempotent (can be applied multiple times safely)
- Use descriptive names for resources (e.g., `nginx-deployment`, not `deploy1`)
- Delete resources after completing exercises to keep cluster clean: `kubectl delete -f <manifest.yaml>`

---

**Good luck with your KCNA exam preparation!**

Start with **01-beginner/README.md** for module-specific guidance.
