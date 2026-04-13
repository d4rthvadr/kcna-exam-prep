# Repository Navigation & Index

## Welcome to KCNA Prep!

This repository contains a comprehensive study guide for the **KCNA (Kubernetes and Cloud Native Associate)** certification exam. Whether you're just starting or reviewing before the exam, this index will help you navigate the materials efficiently.

---

## Quick Start (30 minutes)

**New to this repository?** Start here:

1. **Read**: [README.md](README.md) — Overview of KCNA and study approach (5 min)
2. **Understand**: [learning-summary.md](learning-summary.md) — Quick review of key concepts (10 min)
3. **Prepare Cluster**: Run `bash setup/cluster-setup.sh` to initialize local Kubernetes (5 min)
4. **Choose Path**: Select a module below based on your experience level (10 min decision)

---

## Repository Structure

```
CKNA-prep/
├── README.md                          # Main guide + KCNA overview
├── cheatsheet.md                      # kubectl command reference (200+ commands)
├── learning-summary.md                # Concept review by module
├── exam-tips.md                       # Exam strategy & domain tips
├── mock-scenarios.md                  # Practice questions with answers
│
├── setup/
│   ├── cluster-setup.sh              # Initialize Kubernetes cluster
│   └── verify-setup.sh               # Verify cluster prerequisites
│
├── templates/                         # YAML boilerplate for exercises
│   ├── pod.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── pvc.yaml
│   ├── pv.yaml
│   ├── job.yaml
│   ├── cronjob.yaml
│   ├── serviceaccount.yaml
│   ├── role.yaml
│   ├── networkpolicy.yaml
│   ├── hpa.yaml
│   └── others...
│
├── 01-beginner/                      # Module 1: Foundations
│   ├── README.md
│   ├── pods/exercise.md              # 6 exercises
│   ├── deployments/exercise.md       # 6 exercises
│   └── services/exercise.md          # 7 exercises
│
├── 02-intermediate/                  # Module 2: Configuration & Storage
│   ├── README.md
│   ├── configmaps-secrets/exercise.md # 9 exercises
│   └── storage/exercise.md            # 8 exercises
│
├── 03-advanced/                      # Module 3: Scheduling & Lifecycle
│   ├── README.md
│   ├── scheduling/exercise.md        # 8 exercises
│   ├── lifecycle/exercise.md         # 8 exercises
│   └── cronjobs/exercise.md          # 8 exercises
│
├── 04-expert-security/               # Module 4: RBAC & Networking
│   ├── README.md
│   ├── rbac/exercise.md              # 8 exercises
│   └── network-policies/exercise.md  # 7 exercises
│
└── 05-expert-operations/             # Module 5: Operations & Observability
    ├── README.md
    ├── observability/exercise.md     # 7 exercises
    ├── deployments/exercise.md       # 7 exercises
    └── troubleshooting/exercise.md   # 5 exercises
```

---

## Study Paths by Experience Level

### Path A: Complete Beginner (4-6 weeks)

**Goal**: Build foundational Kubernetes skills from scratch

**Week 1-2: Module 01 - Kubernetes Fundamentals**

- [ ] Read [`01-beginner/README.md`](01-beginner/README.md)
- [ ] Complete all exercises in [`01-beginner/`](01-beginner/)
  - Pods (6 exercises)
  - Deployments (6 exercises)
  - Services (7 exercises)
- **Time commitment**: 8-10 hours hands-on

**Week 2-3: Module 02 - Configuration & Storage**

- [ ] Read [`02-intermediate/README.md`](02-intermediate/README.md)
- [ ] Complete all exercises in [`02-intermediate/`](02-intermediate/)
  - ConfigMaps & Secrets (9 exercises)
  - Storage (8 exercises)
- **Time commitment**: 6-8 hours hands-on

**Week 3-4: Module 03 - Advanced Scheduling**

- [ ] Read [`03-advanced/README.md`](03-advanced/README.md)
- [ ] Complete all exercises in [`03-advanced/`](03-advanced/)
  - Scheduling (8 exercises)
  - Lifecycle (8 exercises)
  - CronJobs (8 exercises)
- **Time commitment**: 8-10 hours hands-on

**Week 4-5: Module 04 - Security & Networking**

- [ ] Read [`04-expert-security/README.md`](04-expert-security/README.md)
- [ ] Complete all exercises in [`04-expert-security/`](04-expert-security/)
  - RBAC (8 exercises)
  - NetworkPolicies (7 exercises)
- **Time commitment**: 6-8 hours hands-on

**Week 5-6: Module 05 - Operations & Exam Prep**

- [ ] Read [`05-expert-operations/README.md`](05-expert-operations/README.md)
- [ ] Complete all exercises in [`05-expert-operations/`](05-expert-operations/)
  - Observability (7 exercises)
  - Deployments (7 exercises)
  - Troubleshooting (5 exercises)
- [ ] Review [exam-tips.md](exam-tips.md)
- [ ] Practice [mock-scenarios.md](mock-scenarios.md)
- [ ] Score 75%+ on mock scenarios before exam
- **Time commitment**: 8-10 hours + exam prep

**Total Time**: ~40-50 hours hands-on + 5-10 hours review

---

### Path B: Docker/Container Experienced (2-3 weeks)

**Goal**: Learn Kubernetes-specific concepts leveraging container knowledge

**Week 1: Modules 01-02 (Skim + Key Exercises)**

- [ ] Skim [`01-beginner/`](01-beginner/) README (understand Kubernetes abstractions)
- [ ] Do Deployments (6) and Services (7) exercises only
- [ ] Skim [`02-intermediate/`](02-intermediate/) README
- [ ] Do Storage exercises (8) only
- **Time commitment**: 8-10 hours

**Week 2: Modules 03-04 (Focus on Advanced)**

- [ ] Read [`03-advanced/`](03-advanced/) README (scheduling, lifecycle)
- [ ] Do Scheduling (8) and Lifecycle (8) exercises
- [ ] Read [`04-expert-security/`](04-expert-security/) README
- [ ] Do RBAC (8) and NetworkPolicies (7) exercises
- **Time commitment**: 10-12 hours

**Week 3: Module 05 + Exam Prep**

- [ ] Read [`05-expert-operations/`](05-expert-operations/) README
- [ ] Do Troubleshooting (5) exercises; skim others
- [ ] Review [learning-summary.md](learning-summary.md) (1-2 hours)
- [ ] Practice [mock-scenarios.md](mock-scenarios.md)
- [ ] Review [exam-tips.md](exam-tips.md)
- **Time commitment**: 10-12 hours

**Total Time**: ~30-35 hours hands-on + exam prep

---

### Path C: Kubernetes Admin/CKA Preparation (1-2 weeks)

**Goal**: Quick KCNA review before taking exam (you already know most concepts)

**Week 1: Focused Review**

- [ ] Read all module READMEs (2 hours)
- [ ] Skim [learning-summary.md](learning-summary.md) (30 min)
- [ ] Do troubleshooting exercises (5) (1 hour)
- [ ] Do mock-scenarios.md practice questions (2 hours)
- [ ] Review KCNA-specific topics: 12-factor, cloud-native patterns (1 hour)

**Week 2: Final Prep**

- [ ] Take full mock exam (90 min)
- [ ] Review weak areas (2-3 hours)
- [ ] Final review of exam-tips.md (1 hour)

**Total Time**: ~12-15 hours review/practice

---

## How to Use Exercises

### Exercise Format (All Modules)

Each exercise file (`*/exercise.md`) contains:

1. **Problem Statement** — Real-world scenario
2. **Learning Objectives** — What you'll learn
3. **Instructions** — Step-by-step commands/YAML to create
4. **Verification Steps** — Commands to verify success
5. **Expected Outcomes** — What should happen
6. **Key Learning Concepts** — Explanation of "why"

### Recommended Approach

**For each exercise:**

1. **Read** problem statement and objectives
2. **Look at templates** in `templates/` directory for boilerplate YAML (if needed)
3. **Follow instructions** — Type (don't copy-paste) each command
4. **Run verification** — Confirm your work
5. **Debug if needed** — Use `kubectl describe` and `kubectl logs`
6. **Review concepts** — Understand why it worked
7. **Try again from memory** — Can you do it without guide? (best learning)

### Using Templates

YAML templates are available in `/templates/` directory:

- `pod.yaml` — Pod boilerplate
- `deployment.yaml` — Deployment boilerplate
- `service.yaml` — Service templates (ClusterIP, NodePort, LoadBalancer)
- `configmap.yaml`, `secret.yaml`, `pvc.yaml`, etc.

**How to use**: Copy template, modify metadata and specs, apply to cluster

---

## Key Reference Files

### Quick References (Use during study/review)

| File                                       | Purpose                                        | Size   | Time      |
| ------------------------------------------ | ---------------------------------------------- | ------ | --------- |
| [cheatsheet.md](cheatsheet.md)             | 200+ kubectl commands organized by domain      | 50 KB  | 10-15 min |
| [learning-summary.md](learning-summary.md) | Key concepts from all 5 modules                | 80 KB  | 15-30 min |
| [exam-tips.md](exam-tips.md)               | Strategy, study tips, domain-specific guidance | 60 KB  | 20-30 min |
| [mock-scenarios.md](mock-scenarios.md)     | 10 scenario questions + 5 quick questions      | 100 KB | 45-60 min |

### Module READMEs (Read before exercises)

| Module | File                                                               | Content                                     |
| ------ | ------------------------------------------------------------------ | ------------------------------------------- |
| 01     | [`01-beginner/README.md`](01-beginner/README.md)                   | Pods, Deployments, Services overview        |
| 02     | [`02-intermediate/README.md`](02-intermediate/README.md)           | ConfigMaps, Secrets, Storage explanation    |
| 03     | [`03-advanced/README.md`](03-advanced/README.md)                   | Scheduling, Lifecycle, Jobs concepts        |
| 04     | [`04-expert-security/README.md`](04-expert-security/README.md)     | RBAC, NetworkPolicy overview                |
| 05     | [`05-expert-operations/README.md`](05-expert-operations/README.md) | Observability, Deployments, Troubleshooting |

### Master README

[README.md](README.md) — Start here! Overview of:

- KCNA exam domains
- 5-module learning path
- Setup instructions
- Study timeline
- Success criteria

---

## Exam Preparation Checklist

### 2 Weeks Before Exam

- [ ] Complete all 5 modules (or your chosen path)
- [ ] Run through troubleshooting exercise (Module 05)
- [ ] Score 75%+ on [mock-scenarios.md](mock-scenarios.md)
- [ ] Review [exam-tips.md](exam-tips.md) — domain-specific tips

### 1 Week Before Exam

- [ ] Re-do exercises in weak domains (focus on failures)
- [ ] Review [learning-summary.md](learning-summary.md) — quick concept check
- [ ] Practice [mock-scenarios.md](mock-scenarios.md) again
- [ ] Time your mock exam (should complete in 60-70 min)

### 3 Days Before Exam

- [ ] Light review of [cheatsheet.md](cheatsheet.md) (kubectl commands)
- [ ] Review KCNA-specific domains (if weak)
- [ ] Ensure exam environment (browser, internet) is tested
- [ ] Get good sleep

### Day Before Exam

- [ ] Read through [exam-tips.md](exam-tips.md) — strategy section
- [ ] Verify exam login credentials work
- [ ] Minimal studying (confidence building only)
- [ ] Sleep well

### Exam Day

- [ ] Review last 15-minute brain dump from [exam-tips.md](exam-tips.md)
- [ ] Manage time: 60 min first pass, 20 min second pass, 10 min review
- [ ] Carefully read questions (key words matter!)
- [ ] Mark uncertain questions for review

---

## Getting Help

### If You Get Stuck

**During Exercises:**

1. Check the **Verification Steps** — debugging commands provided
2. Review **Key Learning Concepts** section — explains the "why"
3. Check corresponding module README for more context
4. Use `kubectl describe <resource>` and `kubectl logs` for real errors
5. Check [cheatsheet.md](cheatsheet.md) for similar commands

**Before Exam:**

1. Review [exam-tips.md](exam-tips.md) — domain-specific guidance
2. Redo mock-scenarios in failed domain
3. Review [learning-summary.md](learning-summary.md) for that concept

### Common Questions

**Q: How long should each exercise take?**
A: 15-30 minutes typically; troubleshooting exercises take longer (30-60 min)

**Q: Can I skip modules?**
A: Yes, if experienced with containers. But recommend at least skimming all modules for KCNA-specific topics.

**Q: Should I memorize commands?**
A: No, understand concepts. Commands have help (`kubectl <cmd> --help`). Focus on understanding what each resource does.

**Q: Is real Kubernetes cluster required?**
A: Yes. Use minikube, kind, or Docker Desktop. See [setup/cluster-setup.sh](setup/cluster-setup.sh).

**Q: What if I fail the exam?**
A: Use failed domains guide in [exam-tips.md](exam-tips.md). Spend extra time on weak areas. Most retakes succeed.

---

## Success Stories

This repository was designed based on feedback from successful KCNA exam takers. Key patterns:

- **Hands-on > Reading**: Running exercises beats reading theory alone
- **Exercise Repetition**: Doing exercise twice teaches better than once
- **Debugging Skills**: Being able to diagnose issues is 80% of exam
- **Concept Understanding**: Knowing "why" not just "how"

---

## After Passing KCNA

### Celebrate & Share!

- Share your achievement on LinkedIn
- Add credential to resume/profile
- Join Kubernetes community

### Continue Learning

- **CKA**: Kubernetes Administrator (more advanced than KCNA)
- **CKAD**: Kubernetes Application Developer (application focus)
- **Keep practicing**: Skills degrade; continue hands-on work
- **Follow cloud-native**: Read blogs, join meetups

---

## Repository Stats

| Metric                     | Value                           |
| -------------------------- | ------------------------------- |
| Total Modules              | 5                               |
| Total Exercises            | 94                              |
| Total Guidance Lines       | ~20,000                         |
| Approximate Study Time     | 35-50 hours (depending on path) |
| Exam Domains Covered       | 100%                            |
| Mock Questions             | 15+ scenarios                   |
| kubectl Commands Reference | 200+                            |

---

## File Organization Summary

**Navigation Priority:**

1. **First Time**: Read [README.md](README.md) + choose your path above
2. **During Study**: Use module README + exercise files
3. **For Quick Lookup**: Use [cheatsheet.md](cheatsheet.md)
4. **For Reviewing**: Use [learning-summary.md](learning-summary.md)
5. **Before Exam**: Review [exam-tips.md](exam-tips.md) + [mock-scenarios.md](mock-scenarios.md)

---

**Ready to get started?**

→ **Begin with**: [README.md](README.md) or jump to your experience level path above.

Start your KCNA preparation today.
