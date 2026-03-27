---
id: automation-041
name: "Automate Partner Reporting"
category: automation
intent: automate-partner-reporting
action: design
object: config
triggers:
  - "partner reporting automation"
  - "automate partner reports"
  - "channel partner reporting"
  - "automated partner performance reports"
  - "partner data reporting workflow"
intent_signals:
  - "(^|[^a-zA-Z])(partner)(\\s|.){0,20}(reporting|report)(\\s|.){0,20}(automation|automated)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(automate)(\\s|.){0,20}(partner|channel)(\\s|.){0,20}(reporting|reports)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(channel partner)(\\s|.){0,20}(performance|report)(\\s|.){0,20}(automation)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(internal)(\\s)(team)(\\s)(reporting)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 180
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

You are an automation architect designing partner reporting automation. Partners need timely, accurate performance data to manage their business — automated reporting delivers consistent reports without manual compilation effort.

Design the partner reporting automation across these components:

1. **Data compilation** — the data sources contributing to partner reports (CRM pipeline data, revenue data, support ticket data, product usage data), how each is queried per partner, and data isolation to ensure each partner only sees their own data.
2. **Report templates** — define the report structure per partner tier: what metrics each tier receives, report sections, and any partner-specific customizations.
3. **Metric calculations** — precise calculation for every metric in the report: referral revenue, pipeline created, conversion rates, co-sell activity, certifications, and MDF utilization.
4. **Comparison and context** — period-over-period comparison, performance vs. targets, and ranking within partner tier (with anonymized peer benchmarks where appropriate).
5. **Generation schedule** — monthly and quarterly report cadences, close process dependencies (waiting for month-end close before generating revenue figures), and delivery timing.
6. **Delivery mechanism** — distribution via email, partner portal, or both. Authentication for portal access. PDF and data export formats.
7. **Partner portal integration** — if partners access reports via a portal, automated publishing, versioning, and access control.
8. **Alerting for partner managers** — internal notifications when a partner's performance crosses thresholds (significant decline, target achievement), prompting proactive outreach.
