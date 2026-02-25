# Incident Response

Standards for detecting, responding to, and learning from production incidents. These complement the [Monitoring & Observability](monitoring-observability.md) alerting standards and the operational practices defined across DevRail-managed services.

## Severity Levels

| Level | Definition | Response Time | Examples |
|---|---|---|---|
| **SEV1** | Service is down or data loss is occurring | Page immediately, respond within 15 minutes | Complete outage, data corruption, security breach with active exploitation |
| **SEV2** | Major functionality degraded, significant user impact | Respond within 30 minutes | Partial outage, critical feature broken, significant performance degradation |
| **SEV3** | Minor functionality impacted, workaround available | Respond within 4 hours | Non-critical feature broken, intermittent errors, cosmetic issues affecting usability |
| **SEV4** | Minor issue, no immediate user impact | Respond within 1 business day | Monitoring gap identified, non-user-facing bug, minor configuration drift |

### Classification Rules

1. **When in doubt, escalate.** It is better to over-classify and downgrade than to under-classify and miss a critical issue.
2. **User impact determines severity.** Infrastructure metrics alone do not define severity -- map them to user experience.
3. **Security incidents are SEV1 or SEV2 by default.** Active exploitation is SEV1. Potential exposure without confirmed exploitation is SEV2.
4. **Data loss or corruption is always SEV1.** Regardless of scale.

## Incident Workflow

### Lifecycle

```
Detect → Triage → Mitigate → Resolve → Post-Mortem
```

### Phases

| Phase | Actions | Owner |
|---|---|---|
| **Detect** | Alert fires, user report received, or monitoring anomaly identified | Monitoring system / reporter |
| **Triage** | Confirm the incident, assign severity, identify initial scope | On-call responder |
| **Mitigate** | Apply immediate fix to stop the bleeding (rollback, scale up, disable feature, redirect traffic) | Incident commander |
| **Resolve** | Implement the permanent fix, verify resolution, close the incident | Engineering team |
| **Post-Mortem** | Document timeline, root cause, and action items | Incident commander + participants |

### Triage Checklist

- [ ] Confirm the incident is real (not a false alarm or monitoring issue)
- [ ] Assign severity level
- [ ] Identify affected services and user impact
- [ ] Open an incident channel or thread
- [ ] Notify stakeholders per communication plan
- [ ] Assign incident commander if SEV1-SEV2

## Communication

### Internal Communication

| Severity | Channel | Update Cadence |
|---|---|---|
| **SEV1** | Dedicated incident channel + page stakeholders | Every 15 minutes until mitigated |
| **SEV2** | Dedicated incident channel | Every 30 minutes until mitigated |
| **SEV3** | Team channel | At triage and resolution |
| **SEV4** | Issue tracker | At resolution |

### External Communication

For user-facing incidents:

1. **Acknowledge within 15 minutes** (SEV1) or 30 minutes (SEV2) on the status page.
2. **Update the status page** at every phase transition (investigating → identified → monitoring → resolved).
3. **Post a summary** after resolution with what happened, what was impacted, and what was done.
4. **Do not speculate on root cause** in public communications until the post-mortem is complete.

### Templates

Acknowledgment:
> We are investigating reports of [symptom]. Some users may experience [impact]. We will provide updates as we learn more.

Resolution:
> The issue affecting [service/feature] has been resolved. The incident lasted [duration]. A post-mortem will follow.

## Post-Mortems

### When Required

| Severity | Post-Mortem Required |
|---|---|
| **SEV1** | Yes, within 3 business days |
| **SEV2** | Yes, within 5 business days |
| **SEV3** | Optional, at team discretion |
| **SEV4** | No |

### Principles

1. **Blameless.** Focus on systems and processes, not individuals. "The deployment pipeline did not catch the regression" -- not "Alice deployed broken code."
2. **Honest.** Document what actually happened, including missteps during the response.
3. **Action-oriented.** Every post-mortem produces concrete action items with owners and due dates.

### Template

```markdown
# Post-Mortem: [Incident Title]

**Date:** YYYY-MM-DD
**Severity:** SEV1/SEV2
**Duration:** Xh Ym (from detection to resolution)
**Author:** [Name]
**Participants:** [List]

## Summary
One paragraph describing the incident and its impact.

## Timeline
| Time (UTC) | Event |
|---|---|
| HH:MM | Alert fired for [symptom] |
| HH:MM | On-call acknowledged, began investigation |
| HH:MM | Root cause identified: [brief description] |
| HH:MM | Mitigation applied: [action taken] |
| HH:MM | Incident resolved, monitoring confirmed recovery |

## Root Cause
Detailed description of why the incident occurred.

## Impact
- Users affected: [number or scope]
- Duration of impact: [time]
- Data loss: [yes/no, details]

## What Went Well
- [Positive observation about detection, response, or tooling]

## What Went Wrong
- [Process gap, tooling failure, or missed signal]

## Action Items
| Action | Owner | Due Date | Status |
|---|---|---|---|
| [Specific, measurable action] | [Name] | YYYY-MM-DD | Open |
```

## Runbooks

### Requirements

1. **Every production service has a runbook.** The runbook covers common failure modes, diagnostic commands, and recovery procedures.
2. **Stored alongside code.** Runbooks live in the repository (e.g., `docs/runbooks/`) so they are versioned and reviewed like code.
3. **Linked from alerts.** Every alert definition includes a link to the relevant runbook section.
4. **Reviewed quarterly.** Schedule a recurring review to verify runbooks are accurate and complete.

### Content

Each runbook entry covers:

- **Symptom:** What the operator sees (alert name, error message, dashboard pattern)
- **Diagnosis:** Commands and checks to confirm the issue and identify the root cause
- **Resolution:** Step-by-step recovery procedure
- **Escalation:** When and to whom to escalate if the runbook steps do not resolve the issue

## On-Call

### Expectations

1. **Defined rotation.** On-call schedules are published and visible to the team.
2. **Acknowledge alerts within the response time** for the severity level.
3. **Hand off context cleanly.** When rotating, the outgoing on-call briefs the incoming on-call on any active or recent incidents.
4. **Compensate on-call fairly.** On-call is real work. Follow your organization's compensation policy.

### Escalation Path

```
On-call engineer → Team lead → Engineering manager → CTO/VP Engineering
```

Escalate when:

- The incident is beyond the on-call's area of expertise
- The severity is higher than initially assessed
- Mitigation is not progressing within the expected timeframe
- The incident requires cross-team coordination

## Notes

- Incident response processes should be practiced through regular game days or chaos engineering exercises, not only learned during real incidents.
- The severity definitions and response times in this document are defaults. Organizations should calibrate them to their SLAs and team size.
- For security-specific incident response (data breaches, unauthorized access), additional procedures from your security team may apply.
