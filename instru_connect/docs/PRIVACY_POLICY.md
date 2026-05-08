# Privacy Policy for InstruConnect

**Effective Date:** March 27, 2026  
**Last Updated:** March 27, 2026  
**Version:** 2.0

InstruConnect ("App", "we", "us", or "our") is a college-use mobile application for attendance, notices, resources, complaints, timetables, and related academic administration.

This Privacy Policy explains what personal data we collect, why we collect it, the lawful bases we rely on, how we share and protect data, how long we retain it, and the rights available to users.

This policy is intended to support transparency requirements under the General Data Protection Regulation ("GDPR"), Google Play policies, and Apple App Store privacy expectations.

## 1. Data Controller

The **Data Controller** for personal data processed through InstruConnect is:

**[Full Legal Name of Institution]**  
**Address:** [Institution Address]  
**Email:** [Privacy Contact Email]  
**Phone:** [Institution Phone Number]

If the institution is legally required to appoint a Data Protection Officer ("DPO"), the DPO details must also be published here:

**Data Protection Officer (if applicable)**  
**Name:** [DPO Name]  
**Email:** [DPO Email]  
**Postal Address:** [DPO Address]

The App must not be submitted to public app stores until these controller details are finalized and published both in-app and in store metadata.

## 2. Categories of Personal Data We Process

Depending on your role and use of the App, we may process the following categories of personal data:

### 2.1 Identity and account data
- Name
- Institutional email address
- User ID, roll number, MIS number, or similar institutional identifier
- Role such as student, CR, faculty, staff, or administrator
- Microsoft sign-in account information required for authentication

### 2.2 Profile and academic administration data
- Department
- Batch or class information
- Contact number
- Attendance records
- Subject and session associations
- Academic timetable references

### 2.3 User submissions and operational content
- Complaint title, description, category, status, progress notes, and assignment details
- Images or videos attached to complaints
- Uploaded academic resources and related file metadata
- Notices and event information created by authorized users

### 2.4 Technical and service data
- Firebase Cloud Messaging token
- Authentication session details
- Device and app information reasonably required for service security, diagnostics, and delivery

## 3. Purposes of Processing and Lawful Bases

Under GDPR Article 6, we process personal data only where a lawful basis applies.

| Data Category | Purpose | Lawful Basis |
|---|---|---|
| Institutional email, Microsoft sign-in data, role, user ID | Sign-in, identity verification, role-based access, account security | Article 6(1)(b) performance of a contract or pre-contractual steps; Article 6(1)(f) legitimate interests in securing institutional systems |
| Name, department, batch, contact details, academic profile | Profile completion, academic administration, routing users to the correct workflows | Article 6(1)(b) performance of a contract; Article 6(1)(f) legitimate interests in operating the service |
| Attendance records, class/session data, notices, complaint workflows, resources, timetable and event records | Delivery of the core educational and administrative service | Article 6(1)(b) performance of a contract; Article 6(1)(f) legitimate interests; where applicable, Article 6(1)(c) compliance with a legal or institutional obligation |
| Complaint attachments, uploaded resource files | Storing and displaying content that users or authorized staff choose to submit through the App | Article 6(1)(b) performance of a contract; Article 6(1)(f) legitimate interests |
| Push notification token | Sending service notifications, complaint updates, and notices | Article 6(1)(a) consent where local law or platform practice requires it; otherwise Article 6(1)(f) legitimate interests in service communications |
| Technical logs and security-related service data | Security, fraud prevention, abuse detection, troubleshooting, and service continuity | Article 6(1)(f) legitimate interests |

Where we rely on **legitimate interests**, those interests are limited to operating, securing, and supporting the App for authorized institutional use.

Where we rely on **consent**, you may withdraw that consent at any time without affecting the lawfulness of processing carried out before withdrawal.

## 4. Granular Data Use Disclosure

We do not treat all data in the same way. The table below explains why specific data items are collected:

| Data Item | Why It Is Collected |
|---|---|
| Institutional email address | To authenticate the user and confirm they belong to the authorized institution domain |
| Name and role | To identify the user in the App and apply role-based permissions |
| User ID / MIS / roll number | To associate academic records with the correct user |
| Department and batch | To show the correct timetable, attendance data, and academic content |
| Contact number | For profile completion and operational contact where required by the institution |
| Attendance data | To record and display attendance-related information |
| Complaint text and status data | To allow issue reporting, assignment, review, and resolution |
| Complaint image or video attachments | To support evidence-based complaint handling where the user chooses to upload a file |
| Uploaded resources and documents | To share educational materials inside the App |
| Notification token | To send notices, complaint updates, and service alerts |

## 5. Consent and User Choice

### 5.1 Consent is separate from device permissions
Operating system permissions, such as notification or media access prompts, help control device features but **do not by themselves constitute GDPR consent** for all processing activities. GDPR consent must be freely given, specific, informed, and unambiguous.

### 5.2 When consent is required
Where the App relies on consent, the institution should implement an active opt-in mechanism before the relevant processing begins. This includes, where applicable:
- optional push notifications
- any optional analytics or non-essential tracking, if introduced later
- any future optional processing that is not necessary for the core service

### 5.3 Withdrawal of consent
Users must be able to withdraw consent as easily as it was given. Until an in-app preference center is implemented, withdrawal requests must be accepted through the privacy contact listed in Section 1. The institution should implement an in-app withdrawal workflow before launch if consent-based processing is enabled.

## 6. How We Share Personal Data

We do not sell personal data.

We may share personal data only with:
- **Google Firebase**, for authentication, database hosting, file storage, and push notifications
- **Microsoft**, for institutional sign-in and identity authentication
- **Authorized institutional staff**, where access is necessary for attendance, notices, complaints, resources, timetable administration, or technical support
- **Regulators, courts, or public authorities**, where disclosure is required by applicable law or a lawful request

## 7. Processors and Data Processing Agreements

Where third parties process personal data on behalf of the institution, they act as **data processors** or sub-processors.

The institution must ensure that appropriate **Data Processing Agreements ("DPAs")** or equivalent contractual safeguards are in place with processors, including where required for:
- Google Firebase / Google Cloud
- Microsoft identity services

This policy assumes such agreements are executed and maintained by the institution before launch.

## 8. International Data Transfers

Personal data processed through Firebase, Google Cloud, or Microsoft services may be transferred to or accessed from countries outside the United Kingdom, European Economic Area, or your home jurisdiction.

Where international transfers occur, the institution will rely on an appropriate transfer mechanism under applicable law, such as:
- an adequacy decision
- Standard Contractual Clauses ("SCCs")
- another legally recognized transfer safeguard

Users may request more information about the applicable transfer safeguards using the contact details in Section 1.

## 9. Data Retention

We retain data according to the nature of the record and the institution's legal, academic, and operational obligations.

The current retention approach is:
- **Active account and profile data:** retained while the user remains an authorized user and for a limited period afterward as needed for institutional administration
- **Attendance and academic administration data:** retained in line with the institution's academic recordkeeping requirements
- **Complaint records:** retained for operational handling and audit purposes; the codebase currently includes automated deletion windows of approximately 120 days for open complaints and shorter periods after resolution where configured, but institutional retention rules should override where legally required
- **Uploaded resources and notices/events:** retained while operationally required or until deleted by authorized personnel, subject to backup and recordkeeping needs
- **Push notification tokens:** retained until invalidated, replaced, or no longer required
- **Backups and disaster recovery copies:** retained only for the minimum backup cycle necessary to maintain resilience

Where exact retention periods vary by record type or institutional rules, the institution should maintain an internal retention schedule and apply it consistently.

## 10. Security and Privacy by Design

We apply reasonable technical and organizational safeguards to protect personal data, including:
- authenticated access controls
- role-based authorization
- secure data transmission
- managed cloud hosting and storage
- restricted operational access to records
- data minimization for core service delivery

The App is intended to follow the principle of **privacy by design and by default**, meaning personal data processing should be limited to what is necessary for the service and protected by default settings, access controls, and secure architecture choices.

## 11. Data Breach Response

If a personal data breach occurs, the institution will assess the incident promptly and take appropriate containment, investigation, and remediation steps.

Where required by law, the institution will:
- notify the competent supervisory authority without undue delay and, where applicable, within **72 hours** of becoming aware of the breach
- notify affected users where the breach is likely to result in a high risk to their rights and freedoms

## 12. Your Rights

Subject to applicable law, you may have the right to:
- request access to your personal data
- request correction of inaccurate data
- request deletion of data in certain circumstances
- request restriction of processing
- object to processing based on legitimate interests
- withdraw consent where processing is based on consent
- request data portability in a structured, commonly used, machine-readable format where applicable
- lodge a complaint with a supervisory authority

### How to exercise your rights
To exercise any of these rights, contact the Data Controller or DPO using the details in Section 1.

If the institution introduces in-app workflows for deletion, export, objection handling, or consent withdrawal, those workflows should be reflected in future policy updates. At present, rights requests must be supported through the institution's published privacy contact.

## 13. Supervisory Authority Complaints

If you believe your personal data has been processed unlawfully, you have the right to lodge a complaint with the relevant data protection or supervisory authority in your jurisdiction.

Examples include:
- **European Union:** your local Data Protection Authority
- **United Kingdom:** Information Commissioner's Office (ICO) - https://ico.org.uk/
- **Other jurisdictions:** the relevant national or regional privacy regulator

## 14. Children's Data

InstruConnect is intended for institutional higher-education use and is not marketed as a children's app.

## 15. Changes to This Policy

We may update this Privacy Policy from time to time to reflect legal, technical, operational, or platform changes. The latest version should be published in the App and any required app store listing fields.

## 16. Contact

For privacy questions, rights requests, or complaints about personal data handling, contact:

**[Full Legal Name of Institution]**  
**Email:** [Privacy Contact Email]  
**Address:** [Institution Address]  
**Phone:** [Institution Phone Number]

If applicable:

**Data Protection Officer**  
**Email:** [DPO Email]
