# Business Logic

> Development of a Web- and Android-Based Rent and Utility Billing Management System using React and Flutter for Boarding Houses

* Allowed Platforms: Web, Android

## Project Details

* Company/Startup/Team Name: `BankPay`
* Project Code Name: `mint`
* Project Short Code: `MT`
* Short Description: `A web and mobile platform for automated rent collection, utility sub-meter computation, and payment tracking in boarding houses.`
* Long Description: `mint (MT) by BankPay is a dual-platform (React Web and Flutter Android) management system designed to streamline boarding house operations. It automates monthly rent invoicing, calculates shared or sub-metered electricity and water bills, tracks tenant payment statuses with digital receipt uploads, and sends automated due-date reminders to reduce late payments and manual ledger errors.`

## User Levels

| User Level | Description |
| --- | --- |
| A. System Administrator | Maintains/overrides system/server configurations, manages database security, and performs regular backups. |
| B. Boarding House Owner (Administrator) | Manages property settings, room rates, utility tariffs, tenant onboarding, and generates financial analytics and collection reports. |
| C. Caretaker / Property Manager (Moderator) | Records monthly utility meter readings, verifies uploaded payment receipts, and issues payment confirmations on behalf of the owner. |
| D. Tenant / Boarder (Contributor) | Views itemized monthly bills, uploads proof of payment (e.g., GCash/bank transfer receipts), checks payment history, and submits billing inquiries. |
| E. Prospective Tenant (Guest) | Users who do not log in, but can view public boarding house details, general room rates, and available bedspaces/rooms. |

## System Requirements

1. The app shall allow users to authenticate securely using Google Sign-In integration and role-based access control.
2. The app shall allow Boarding House Owners and Caretakers to input electricity and water meter readings and automatically compute individual or split utility charges.
3. The app shall allow the system to generate itemized monthly billing statements combining fixed room rent, utility consumption, and past-due balances.
4. The app shall allow Tenants to view their current invoices and upload digital proof of payment (receipts/screenshots) for verification.
5. The app shall allow Caretakers and Owners to review, approve, or reject submitted payment proofs and automatically issue digital official receipts.
6. The app shall send automated push notifications and email reminders to Tenants prior to and upon reaching billing due dates.
7. The app shall generate downloadable monthly revenue, collection rate, and utility consumption reports for Boarding House Owners.

## Required Solution Layers

1. **Security and privacy by design:** Compliance with the Philippine Data Privacy Act of 2012 (RA 10173), encrypted storage of tenant personal data and payment receipts, strict role-based data isolation (tenants can only view their own bills), retention limits for inactive tenant records, and explicit user consent for data processing.

## MVP Features and Access

| Feature | Access |
| --- | --- |
| 1. Public Room Availability & Boarding House Inquiry Board | A, B, C, D, E |
| 2. Google Sign-In Authentication & User Profile Management | A, B, C, D |
| 3. Itemized Monthly Billing & Utility Breakdown Viewer | A, B, C, D |
| 4. Proof-of-Payment Upload & Digital Receipt History | A, B, C, D |
| 5. Utility Sub-Meter Logging & Payment Verification Queue | A, B, C |
| 6. Room/Rate Configuration & Financial Collection Analytics | A, B |
| 7. System Configuration, Audit Logs & Database Backup Overrides | A |

## Notes

* **Utility Split Logic:** The billing engine supports both **individual sub-metering** (Current Reading minus Previous Reading × Rate per kWh/m³) and **equal/headcount splitting** for shared common-area utilities (e.g., Wi-Fi, water).
* **Platform Separation:** React (Web) serves as the primary administrative dashboard for Owners and System Admins, while Flutter (Android) prioritizes quick meter logging for Caretakers and instant bill viewing/receipt uploads for Tenants.