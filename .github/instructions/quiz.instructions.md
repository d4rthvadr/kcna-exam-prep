---
name: quiz-generation
description: "When a user asks to create a quiz, test themselves, generate mock exams, or practice with questions about KCNA topics: use the quiz-generator skill. Support interactive quizzing, answer validation, and learning feedback."
applyTo: ["**/*.md"]
---

# Quiz Generation Instructions

Guide users through quizzing with flexibility, explanation, and progress tracking.

## Core Principles

1. **Scaffolded Learning**: Provide hints in practice mode, no hints in exam mode
2. **Immediate Feedback**: Explain why answers are correct/incorrect
3. **Adaptive Difficulty**: Increase difficulty after correct answers in practice
4. **Multi-Format Support**: Accommodate different learning styles (visual, scenario, command-based)
5. **Progress Visibility**: Show quiz performance metrics and gaps

## Quiz Generation Workflow

### Step 1: Clarify Quiz Intent

Ask the user:

- **Purpose**: Practice, self-assessment, mock exam, or quick check?
- **Scope**: Which modules/topics? (Module 01 only, or mix?)
- **Format**: Multiple choice, scenarios, command-line, or mixed?
- **Difficulty**: Match current level or stretch target?
- **Length**: How many questions? (3-50)

### Step 2: Set Quiz Parameters

Based on user input, set:

- Question count and types
- Difficulty distribution
- Topic coverage
- Time limit (if exam mode)
- Answer mode (interactive vs. batch)

### Step 3: Administer Quiz

#### Practice Mode

- Present one question at a time
- Accept user answer
- Provide immediate explanation (correct/incorrect)
- Show reference to learning material
- Offer hint before revealing answer (if requested)
- Track performance

#### Exam Mode

- No hints or answer peeking
- Timed (default 90 min for full exam, scaled for partial)
- Full batch submission, then reveal answers
- Scored against standard (66-70% pass for KCNA)
- Performance breakdown by domain

### Step 4: Provide Feedback & Analysis

**For Practice Mode:**

```
✅ Correct!
Concept: Service discovery in Kubernetes
Your understanding: Strong on this topic
Related exercise: Module 02 - Services exercise 3
Next topic: LoadBalancer vs NodePort edge cases
```

**For Exam Mode:**

```
Exam Score: 72/100 (72%)
Status: ✅ PASSED (66% threshold)
Domain Breakdown:
  • Kubernetes Fundamentals: 90% (9/10)
  • Container Orchestration: 75% (15/20)
  • Cloud Native Architecture: 60% (6/10)
  • Cloud Native Observability: 55% (2/4)
  • Application Delivery: 80% (4/5)
Weak Areas: Observability and monitoring
Study Recommendation: Review 03-advanced/observability/exercise.md
```

### Step 5: Support Continued Learning

After quiz completion:

- Suggest exercises for weak areas
- Recommend review topics
- Allow retake with different questions
- Offer focused practice quizzes

## Question Types & Formats

### Multiple Choice (4 options)

- Single correct answer
- Realistic distractor options
- Clear, unambiguous questions
- Exam-aligned

### Scenario Based

- Real-world Kubernetes problems
- Multi-step reasoning required
- Validate design/deployment decisions
- Example: "Your Pods are crashing at startup. Describe how you'd diagnose."

### Command Challenge

- Write kubectl commands or YAML
- Validate syntax and correctness
- Accept multiple valid approaches
- Example: "Create a ConfigMap named 'app-config' with key 'ENV=production'"

### True/False

- Quick concept checks
- Time-efficient (2-3 min for 5 questions)
- Good for fast-feedback loops
- Example: "ServiceAccounts are required for all Pods" (False)

### Fill-in-the-Blank

- Command syntax, configuration keys
- Partial credit for partial correctness
- Example: "The flag to set a pod's restart policy is \_\_\_"

### Matching

- Pair concepts with definitions or use cases
- Example: Match Kubernetes objects (Pod, Deployment, Service) with descriptions

## Difficulty Levels

| Level            | Module Focus     | % of Content | User Profile         |
| ---------------- | ---------------- | ------------ | -------------------- |
| **Beginner**     | 01, basics of 02 | First 30%    | New to Kubernetes    |
| **Intermediate** | 02, 03           | Middle 40%   | Familiar with basics |
| **Advanced**     | 03, 04           | Upper 20%    | Experienced user     |
| **Expert**       | 04, 05           | Final 10%    | CKA-level knowledge  |

## Scoring & Interpretation

### Points Per Question

| Type              | Points       | Partial Credit       |
| ----------------- | ------------ | -------------------- |
| Multiple Choice   | 1            | No                   |
| Scenario          | 1-3          | Yes (partial answer) |
| Command Challenge | 1-2          | Yes (syntax partial) |
| True/False        | 1            | No                   |
| Fill-in-Blank     | 1            | Yes (fuzzy match)    |
| Matching          | 0.5 per pair | No                   |

### Scoring Interpretation

- **90-100%**: Exam-ready, take test immediately
- **80-89%**: Minor gaps, 1-2 more reviews recommended
- **70-79%**: Solid foundation, focused review needed
- **60-69%**: Gaps in weak domains, study plan needed
- **<60%**: Return to foundational exercises

## Quiz Repository Integration

Quizzes automatically reference:

| Resource               | Usage                                         |
| ---------------------- | --------------------------------------------- |
| Module 01-05 exercises | Question sourcing, topic organization         |
| mock-scenarios.md      | Realistic scenario questions, answer patterns |
| learning-summary.md    | Concept definitions, command syntax           |
| cheatsheet.md          | Command reference for validation              |
| NAVIGATION.md          | Module/topic-to-file mapping                  |

## Best Practices for Quiz Takers

1. **Start with Practice Mode**: Low-stakes, get immediate feedback
2. **Topic-Focused Quizzes**: Master 1-2 topics before full exams
3. **Spaced Repetition**: Quiz same topic after 1 day, 3 days, 1 week
4. **Review Wrong Answers**: Read explanations + do relevant exercises
5. **Exam Simulation**: Take 60-90 min full quiz without breaks 1 week before test
6. **Track Progress**: Record quiz scores over time to identify trends

## Assistance Commands

```
/quiz                  Launch interactive quiz builder
/quiz [topic]          Quick quiz on specific topic
/quiz mock-exam        Full KCNA mock exam (90 min)
/quiz review           Review previous quiz results
/quiz spaced           Spaced repetition retry of weak areas
```

---

For quiz generation examples and answer explanations, see the referenced exercises and mock-scenarios.md.
