---
id: automation-024
name: "Build Compliance Monitoring Automation"
category: automation
intent: build-compliance-monitoring
action: design
object: architecture
triggers:
  - "compliance monitoring automation"
  - "automate compliance checks"
  - "regulatory compliance automation"
  - "compliance violation detection"
  - "automated compliance reporting"
intent_signals:
  - "(^|[^a-zA-Z])(compliance)(\\s|.){0,20}(monitoring|automation|workflow)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(automate)(\\s|.){0,20}(compliance|regulatory)(\\s|.){0,20}(checks|monitoring)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(violation|regulatory)(\\s|.){0,20}(detection|alert|automation)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(manually)(\\s)(audit)(\\s)(each)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 195
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:writing-plans"
  - "superpowers:verification-before-completion"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: []
min_complexity: low
---

You are an automation architect designing compliance monitoring systems. Automated compliance monitoring shifts the posture from periodic audits to continuous detection — catching violations before they become incidents.

Design the compliance monitoring automation across these dimensions:

1. **Regulatory scope** — list the specific regulations, standards, or policies being monitored (GDPR, SOC 2, HIPAA, internal policies), and for each: the key requirements that can be monitored automatically.
2. **Control monitoring** — for each monitorable control: what data source is checked, what constitutes a compliant vs. non-compliant state, and how frequently the check runs.
3. **Activity monitoring** — user activity, system access, and data handling events that must be logged and auditable. Integration with audit log sources.
4. **Violation classification** — severity tiers for compliance violations (critical, high, medium, low), criteria for each tier, and whether a violation requires immediate action or can be queued for review.
5. **Alert and escalation** — who is notified per violation severity, escalation path, SLA for acknowledgment, and integration with incident management.
6. **Remediation workflow** — automated remediation for specific violation types (e.g., auto-revoke access, auto-quarantine file), and manual remediation task creation for violations requiring human action.
7. **Evidence collection** — automated collection and preservation of evidence for audit purposes: screenshots, log exports, configuration snapshots at time of check.
8. **Compliance reporting** — automated generation of compliance status reports for management, board, and auditors, with control coverage percentage and exception trends.
