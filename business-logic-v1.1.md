# Business Logic v1.1

> This document defines the MVP baseline for BankPay's `mint` product.

## Product Positioning

### One-line positioning

**mint is the simple rent-and-utilities ledger for boarding houses: owners bill accurately,
tenants see exactly what they owe, and caretakers verify payments without spreadsheets.**

### Target customer and problem

- **Primary customer:** Boarding house owners and small property managers who manage recurring
  rent, shared utilities, and payment proof manually.
- **Primary users:** Owners, caretakers, and tenants in properties with rooms or bedspaces.
- **Core problem:** Manual meter calculations and fragmented payment records cause billing disputes,
  late collections, and weak visibility into outstanding balances.
- **MVP promise:** A property can onboard tenants, issue an itemized monthly bill, receive proof of
  payment, and reconcile the month from one shared record.

### MVP success measures

1. An owner can configure a property, rooms, rates, billing day, and payment instructions.
2. A caretaker can record readings and produce bills without a spreadsheet.
3. A tenant can understand the bill and submit one proof of payment.
4. An owner can identify unpaid, pending-verification, and paid balances for the current month.

## Project Details

| Field | Proposed value |
| --- | --- |
| Company / team | BankPay |
| Product name | mint |
| Short code | MT |
| Platforms | React web dashboard and Flutter Android app |
| MVP scope | One property per owner account; monthly billing; rent plus electricity and water; manual payment verification |
| Explicit non-goals | Online payment processing, accounting/tax filing, maintenance tickets, lease generation, multi-currency support, and advanced forecasting |

## User Levels

| User level | MVP responsibility and boundary |
| --- | --- |
| A. System Administrator | Operates the service, manages support access, security settings, and backups. Must not alter financial records without a recorded reason. |
| B. Boarding House Owner | Owns one or more property records, configures rooms, rates, utility rules, tenants, billing periods, and reports. |
| C. Caretaker / Property Manager | Acts only on assigned properties: records readings, reviews payment proofs, and communicates billing corrections. |
| D. Tenant / Boarder | Sees only the tenant's assigned room, bills, receipts, and submitted inquiries; uploads proof of payment. |
| E. Prospective Tenant / Guest | Sees only explicitly published property, room, and availability information; no private tenant or financial data. |

## System Requirements

1. The system shall authenticate users with Google Sign-In, require an approved role and property
   assignment, and deny access by default.
2. The owner shall configure a property, rooms or bedspaces, monthly rent, billing date, due date,
   payment instructions, and electricity/water charging method.
3. The owner or assigned caretaker shall record a dated meter reading with the meter identifier,
   previous reading, current reading, and optional note or photo.
4. The system shall create a draft monthly bill containing rent, each utility line, prior balance,
   adjustment, due date, and total. It shall prevent duplicate bills for the same tenant and period.
5. The system shall support these MVP utility methods only:
   - Sub-meter: `(current reading - previous reading) × configured rate`.
   - Shared charge: configured amount divided by the configured allocation count.
6. The system shall reject a negative reading delta, missing rate, invalid billing period, or
   unassigned tenant and show the correction required. No silent fallback calculation is allowed.
7. An owner or caretaker shall review and publish a draft bill. A published bill is immutable;
   corrections create a recorded adjustment or replacement, not an overwritten history.
8. A tenant shall view an itemized current bill, balance, due date, payment instructions, and
   payment history, then upload one or more proof-of-payment files with amount and payment date.
9. An owner or caretaker shall mark a submission as approved or rejected with a reason. Approval
   records verifier, timestamp, amount, and receipt reference; rejection returns the bill to unpaid.
10. The system shall show current-month status as **Unpaid**, **Proof submitted**, **Partially paid**,
    **Paid**, or **Overdue**, with one source of truth for owner and tenant.
11. The system shall send an in-app notification and one configured email reminder for bill
    publication and overdue status. Push campaigns and SMS are outside the MVP.
12. The owner shall download a monthly summary of billed, collected, outstanding, and utility
    amounts, with filters for property, room, billing period, and payment status.
13. Public availability shall be opt-in and limited to property details, general rates, and
    available rooms. Guest inquiries shall not expose tenant contact or occupancy information.
14. The system shall retain an event history for bill publication, adjustment, proof review, and
    role changes. Users may not edit or delete those events.

## Required Solution Layers

### Security and privacy by design

- Comply with the Philippine Data Privacy Act of 2012 (RA 10173), with a documented purpose and
  consent notice at account creation and receipt upload.
- Enforce tenant-to-property and tenant-to-room authorization on every read and write.
- Encrypt data in transit and at rest; store payment receipts in private object storage.
- Do not expose full receipt URLs, tenant lists, exact occupancy, or private contact information
  in the guest experience.
- Set retention and deletion rules for inactive tenant profiles and payment proofs; legal or
  financial retention exceptions must be explicit.
- Collect only identity, tenancy, billing, and payment-proof data required for the MVP.
- Provide an owner/admin path to correct data and a user path to request deletion or privacy help.

### Billing integrity

- Store money as fixed-precision values and store the currency explicitly as PHP.
- Define rounding at the line-item level and display the calculation inputs to the tenant.
- Require a billing period, meter identifier, reading timestamp, rate, and actor for every utility
  charge.
- Keep published bills and verification decisions traceable; never silently replace history.

### Reliability and operations

- Back up production data on a documented schedule and test restoration before launch.
- Surface failed notifications and file uploads to the responsible operator; never report success
  when the action was not saved.
- Provide a support-safe account disable path without deleting financial history.

## MVP Features and Access

| Feature | A | B | C | D | E |
| --- | :-: | :-: | :-: | :-: | :-: |
| 1. Public property, room availability, and inquiry form | ✓ | ✓ | ✓ | — | ✓ |
| 2. Google Sign-In, role assignment, and profile | ✓ | ✓ | ✓ | ✓ | — |
| 3. Property, room, tenant, rate, and billing-period setup | ✓ | ✓ | Assigned view | — | — |
| 4. Meter reading and shared-utility entry | ✓ | ✓ | ✓ | — | — |
| 5. Itemized bill draft, publish, and tenant viewer | ✓ | ✓ | Assigned view | ✓ | — |
| 6. Payment-proof upload, review, rejection, and receipt history | ✓ | ✓ | ✓ | ✓ | — |
| 7. Current-month collection dashboard and downloadable summary | ✓ | ✓ | — | Own bills | — |
| 8. Notifications, privacy requests, and immutable activity history | ✓ | ✓ | Assigned actions | Own notices | — |

**Access rule:** “Assigned” means only properties, rooms, tenants, and actions granted by the
owner. System administrators have operational access, but all exceptional access must be logged.

## Lean MVP Scope

### Included in the first release

- One owner account with one or more properties.
- Rooms or bedspaces, tenant assignment, monthly rent, electricity, and water.
- Manual meter entry and the two stated utility calculations.
- Monthly bill publication, payment-proof upload, manual approval/rejection, and receipt history.
- Current-month dashboard, downloadable summary, email/in-app reminders, and privacy controls.

### Deferred until validated

- Online payment gateway and automatic bank reconciliation.
- SMS, marketing automation, scheduled campaigns, and multi-channel messaging.
- Maintenance requests, lease contracts, visitor management, and community chat.
- OCR receipt scanning, smart meter integrations, predictive analytics, and dynamic pricing.
- Full accounting, tax reporting, payroll, multi-currency, and multi-country support.

## Open Decisions Before Build

1. Confirm whether an owner may manage multiple properties in the MVP or whether launch is limited
   to one property.
2. Set the default billing period, due-date rules, grace period, late-fee policy, and partial
   payment behavior.
3. Confirm whether the shared-charge allocation is equal split, headcount, room, or a selectable
   per-property rule.
4. Confirm PHP rounding precision and the allowed payment-proof file types and size limit.
5. Name the privacy contact, retention periods, backup schedule, and production hosting region.
6. Confirm whether email delivery is available at launch; if not, retain in-app notices and show
   an explicit undelivered status.
