---
id: automation-046
name: "Build Learning Management Automation"
category: automation
intent: build-lms-automation
action: design
object: architecture
triggers:
  - "learning management automation"
  - "LMS automation"
  - "automate training assignment"
  - "course automation workflow"
  - "learning path automation"
intent_signals:
  - "(^|[^a-zA-Z])(lms|learning management)(\\s|.){0,20}(automation|workflow)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(automate)(\\s|.){0,20}(training|course|learning)(\\s|.){0,20}(assignment|enrollment)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(learning path|training workflow)(\\s|.){0,20}(automation)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(customer)(\\s)(education)(\\s)(manual)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 185
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:writing-plans"
  - "superpowers:brainstorming"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: []
min_complexity: low
---

You are an automation architect designing learning management automation. LMS automation ensures the right people get the right training at the right time, and certifications never lapse unnoticed.

Design the learning management automation across these components:

1. **Assignment triggers** — events that auto-assign training: role assignment, department transfer, new hire onboarding, compliance calendar dates, role-based annual requirements, and policy updates.
2. **Learning path definition** — for each role and compliance requirement: the specific courses or assessments required, sequencing dependencies, and total time allocation.
3. **Enrollment automation** — automated enrollment in the LMS based on triggers, confirmation communication to learner and manager, and deadline assignment based on trigger date and course type.
4. **Reminder cadence** — reminder schedule relative to due date (14 days, 7 days, 3 days, 1 day), escalation to manager when deadline passes without completion.
5. **Progress tracking** — real-time completion tracking, manager dashboard showing team progress, and aggregated compliance completion reports for HR and compliance officers.
6. **Certification management** — tracking of earned certifications, expiry date monitoring, renewal reminder automation (90, 30, 7 days before expiry), and automatic re-enrollment on expiry.
7. **Completion actions** — post-completion automation: badge or certificate issuance, manager notification, profile update, and next course recommendation based on learning path.
8. **Compliance reporting** — automated compliance training completion reports for audit purposes, showing completion rates by department, overdue learners, and certification coverage.
