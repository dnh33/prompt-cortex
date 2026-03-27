---
id: automation-028
name: "Build Document Approval Workflow"
category: automation
intent: build-approval-workflow
action: design
object: architecture
triggers:
  - "document approval workflow"
  - "approval automation"
  - "automate document review"
  - "approval routing automation"
  - "multi-stage approval workflow"
intent_signals:
  - "(^|[^a-zA-Z])(approval|approvals)(\\s|.){0,20}(workflow|automation|routing)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(automate)(\\s|.){0,20}(approval|document review)(\\s|.){0,20}(process)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(document)(\\s|.){0,20}(approval|sign-off)(\\s|.){0,20}(automation)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(contract)(\\s)(signing)(\\s)(only)([^a-zA-Z]|$)"
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

You are an automation architect designing document approval workflow systems. Approval workflows must route correctly every time, enforce deadlines, and handle rejections without losing context.

Design the document approval automation across these layers:

1. **Document intake** — how documents enter the approval workflow (form submission, CMS draft, file upload, system-generated document), metadata captured at intake, and intake validation.
2. **Stage definition** — the ordered approval stages for each document type, conditions for including or skipping specific stages, and parallel vs. sequential stage execution.
3. **Approver assignment** — routing logic per stage: role-based routing, value-based routing (approver depends on document amount or category), delegation rules, and out-of-office handling.
4. **Advancement triggers** — what constitutes approval at each stage (single approver, majority, unanimous), how the document advances to the next stage, and what data is recorded at each approval.
5. **Rejection handling** — what the submitter receives on rejection (stage, reason, specific feedback), how they resubmit, and whether the workflow restarts from the beginning or from the rejection stage.
6. **SLA and escalation** — response deadline per stage, reminder notifications approaching deadline, escalation to backup approver or manager on deadline breach, and SLA reporting.
7. **Audit trail** — immutable log of every action (submission, approval, rejection, delegation, escalation) with timestamp, actor, and any attached comments.
8. **Post-approval actions** — what happens automatically when final approval is granted: notifications, system updates, document storage, downstream workflow triggers.
