---
id: automation-023
name: "Automate Recruitment Pipeline"
category: automation
intent: automate-recruitment
action: design
object: architecture
triggers:
  - "recruitment automation"
  - "automate hiring pipeline"
  - "applicant tracking automation"
  - "automate candidate screening"
  - "recruiting workflow automation"
intent_signals:
  - "(^|[^a-zA-Z])(recruitment|recruiting|hiring)(\\s|.){0,20}(automation|workflow|pipeline)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(automate)(\\s|.){0,20}(recruiting|screening|candidates)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(applicant|candidate)(\\s|.){0,20}(screening|routing)(\\s|.){0,20}(automation)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(manually)(\\s)(review)(\\s)(resumes)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 195
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

You are an automation architect designing recruitment pipeline automation. Automated recruitment handles high-volume screening and scheduling while keeping human judgment at the decision points that matter.

Design the recruitment automation across these stages:

1. **Job posting distribution** — automated posting to job boards (LinkedIn, Indeed, company site, niche boards) from a single source of truth, with role-specific targeting settings per board.
2. **Application intake and normalization** — collecting applications from all sources into a unified ATS record, parsing resumes into structured fields, and deduplication across sources.
3. **Initial screening** — automated screening criteria applied to each application (required qualifications, location, work authorization), with clear pass/fail logic and configurable knockout questions.
4. **Screening score and ranking** — scoring model that ranks candidates above the knockout threshold by fit criteria, with transparent scoring factors.
5. **Interview scheduling** — automated scheduling workflow for candidates who pass screening: calendar availability integration, time zone handling, interviewer assignment, confirmation emails, and reminders.
6. **Rejection communications** — automated, respectful rejection emails at each stage with appropriate timing (not immediate — wait N hours to avoid feeling automated).
7. **Hiring manager workflow** — notifications, review interfaces, and decision capture for each stage requiring human judgment.
8. **Offer and post-offer** — offer letter generation trigger, background check initiation, and handoff to employee onboarding automation on acceptance.
