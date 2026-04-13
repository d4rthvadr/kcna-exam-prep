---
name: quiz-generator
description: "Generate dynamic quizzes from KCNA study materials. Use when: creating practice quizzes, generating mock exams, testing understanding of specific topics, creating custom quiz formats (multiple choice, scenario, command-line, matching). Supports difficulty filtering (beginner/intermediate/advanced), topic selection, and answer explanations."
---

# Quiz Generator

Generate customized quizzes from KCNA study materials with detailed explanations, answer keys, and scoring.

## Capabilities

### Quiz Types

- **Multiple Choice**: 4-option questions with single correct answer
- **Scenario Based**: Real-world Kubernetes situations requiring diagnosis or solution design
- **Command Challenge**: Write kubectl commands or YAML to solve problems
- **True/False**: Quick concept validation
- **Fill-in-the-Blank**: Command syntax or configuration details
- **Matching**: Pair concepts with definitions or use cases

### Customization Options

- **Difficulty Level**: Beginner, Intermediate, Advanced, Expert, Mixed
- **Module Focus**: Select 1-5 modules or random distribution
- **Topic Filtering**: RBAC, Storage, Networking, Deployments, Observability, etc.
- **Question Count**: 1-50 questions in single quiz
- **Format**: Online practice, printable PDF, timed exam simulation

### Features

- Detailed answer explanations with learning references
- Scoring rubric and performance analysis
- Links to relevant exercises and resources
- Difficulty distribution indicators
- Time estimates per question type
- Hints system for practice vs. exam modes

## Usage Examples

### Generate a practice quiz on ConfigMaps and Secrets:

```
Generate a 10-question practice quiz on ConfigMaps and Secrets
Include 7 multiple choice and 3 command-challenge questions
Set difficulty to intermediate
Provide answer explanations
```

### Create a timed mock exam:

```
Generate a 60-question mock KCNA exam
Mix difficulty levels (Beginner 20%, Intermediate 50%, Advanced 30%)
Include scenario-based questions
Add exam timer (90 minutes total)
Provide scoring and pass/fail threshold
```

### Quick concept check:

```
Quiz me on Deployment rollout strategies (3 questions)
Use true/false format
I want instant feedback
```

## Question Banks

Questions sourced from:

- Module 01-05 exercise files (94 total exercises)
- mock-scenarios.md (15+ realistic scenarios)
- learning-summary.md (key concepts and patterns)
- Common KCNA exam question patterns

## Output Formats

- **Interactive Quiz**: Real-time feedback, hints, explanations
- **Study Guide**: Printable with answers and references
- **Exam Simulation**: Timed, full-screen, no hints mode
- **Review Session**: All answers visible, explanations highlighted
- **Spaced Repetition**: Adaptive difficulty based on performance

## Integration

Quizzes reference:

- Exercise files by module and topic
- Cheatsheet commands for validation
- Learning summary concepts
- Mock scenarios for context

Use `/quiz` command in VS Code Copilot Chat to generate a quiz.
