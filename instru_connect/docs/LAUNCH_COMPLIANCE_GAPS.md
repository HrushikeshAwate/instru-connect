# InstruConnect Launch Compliance Gaps

**Date:** March 27, 2026

This note identifies issues that are **not solved by document updates alone** and should be resolved before public launch on Google Play Store or Apple App Store if GDPR-facing compliance is required.

## 1. Product or Configuration Blockers

### 1.1 Controller details not finalized
The privacy policy now includes a proper Data Controller section, but the institution must still fill in:
- legal entity name
- address
- privacy email
- phone number
- DPO details, if applicable

### 1.2 Consent mechanism not implemented in-app
The current codebase does not show a dedicated consent screen or privacy preference center. If any processing activity relies on consent, the institution should implement:
- a clear opt-in flow
- purpose-specific consent choices
- consent logging

### 1.3 Consent withdrawal not implemented in-app
The policy now explains withdrawal rights, but the current codebase does not show an in-app mechanism for withdrawing consent. Until such a feature exists, the institution must support withdrawal through a documented privacy contact.

### 1.4 Data subject workflows are not self-service
The codebase does not show an in-app export, objection, or account/data deletion workflow. If the institution wants stronger GDPR operational readiness, it should add:
- data export request flow
- account/data deletion request flow
- objection/restriction request flow

### 1.5 Processor contracting must be completed outside the codebase
DPAs with Google/Firebase and Microsoft must be executed and retained by the institution. This is an organizational requirement, not a code change.

### 1.6 Breach response must be operationalized
The policy now states a breach notification standard, but the institution still needs:
- an incident response owner
- internal escalation steps
- decision criteria for user notification
- supervisory authority notification workflow

## 2. Store Submission Risks

### 2.1 Unused iOS permissions
The iOS configuration currently declares:
- camera access
- microphone access
- photo library access

The current complaint screen uses gallery selection for image and video attachment, but the reviewed code does not show direct camera capture or microphone-based recording. Unused permissions should be removed before submission to reduce App Store review risk.

### 2.2 Privacy contact must be live before submission
Both Google Play and Apple expect accessible privacy information. A placeholder contact is not sufficient for real launch.

## 3. Documentation Items Already Addressed

The revised privacy policy now covers:
- lawful bases
- granular data-purpose mapping
- controller and DPO fields
- international transfers
- processor/DPA language
- breach notification wording
- data subject rights including objection and portability
- supervisory authority complaint rights
- retention criteria
- privacy by design language
- clarification that OS permissions are not the same as GDPR consent

## 4. Recommended Launch Decision

**Recommended status:** Conditional approval only.

The documentation is materially improved, but public launch should wait until:
1. controller contact details are finalized,
2. processor agreements are confirmed,
3. unused permissions are removed, and
4. any consent-dependent processing has a real consent and withdrawal workflow.
