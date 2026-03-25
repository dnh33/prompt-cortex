---
id: automation-049
name: "Automate Grant Management"
category: automation
intent: automate-grant-management
action: design
object: config
triggers:
  - "grant management automation"
  - "automate grant applications"
  - "grant tracking workflow"
  - "grant deadline automation"
  - "funding application automation"
intent_signals:
  - "(^|[^a-zA-Z])(grant management|grant tracking)(\\s|.){0,20}(automation|workflow)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(automate)(\\s|.){0,20}(grant|funding)(\\s|.){0,20}(application|management|tracking)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(grant deadline|grant submission)(\\s|.){0,20}(automation|workflow)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(sales)(\\s)(grant)(\\s)(discount)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 185
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:writing-plans"
  - "superpowers:brainstorming"
conflicts_with: []
---

You are an automation architect designing grant management automation. Grant management is deadline-driven with complex documentation requirements — automation ensures nothing is missed and submissions are completed on time.

Design the grant management automation across these components:

1. **Opportunity tracking** — sources for grant opportunity discovery (government portals, foundation databases, grant alerts), intake of new opportunities, and initial eligibility screening against organization criteria.
2. **Deadline management** — for each active grant: application deadline, required document deadlines, reporting deadlines, and renewal dates. Automated calendar and reminder system with escalating alerts (90, 30, 14, 7, 2 days before each deadline).
3. **Document compilation** — required document inventory per grant type, tracking of document readiness, automated collection requests to document owners, and completeness checking before submission.
4. **Application workflow** — draft creation with pre-filled standard content (organization boilerplate, standard financial data), review and editing workflow, internal approval routing, and version control.
5. **Submission execution** — submission via grant portal API, email submission, or submission checklist for manual portals. Submission confirmation capture and storage.
6. **Award tracking** — status monitoring after submission, award/rejection notification handling, award amount and conditions recording, and notification to finance and leadership.
7. **Reporting compliance** — for awarded grants: reporting deadline tracking, progress report generation support, financial reporting data pull, and on-time submission tracking.
8. **Grant portfolio reporting** — pipeline of applications in progress, award rates by funder type, total awarded vs. target, and upcoming deadlines dashboard.
