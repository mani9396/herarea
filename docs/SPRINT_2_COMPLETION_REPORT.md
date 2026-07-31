# HER AREA Backend Implementation — Sprint 2 (Vendor Onboarding & Approval System) Completion Report

**Project**: HER AREA Multi-Application Marketplace Engine  
**Phase**: Phase 5 – Backend Implementation  
**Sprint**: Sprint 2 (Vendor Onboarding & Approval System)  
**Status**: 100% Complete & Fully Verified via Automated Testing  
**Date**: July 31, 2026  

---

## Executive Summary
In strict compliance with the core marketplace business rule—**"A vendor must NOT be able to create stores, products, gallery images, or offers until the vendor has been approved by the Admin"**—Sprint 2 has been delivered as a fully operational **Vendor Onboarding & Approval System**.

We have constructed two modular clean-architecture subsystems (`apps/vendors` and `apps/business`), implemented rigorous status state machines (`PENDING`, `APPROVED`, `REJECTED`, `SUSPENDED`), constructed executive Admin review queues, built real-time database RBAC authorization shields (`IsApprovedVendor`), generated comprehensive Swagger documentation, and validated the end-to-end operational workflow with 10 automated unit tests passing cleanly.

As instructed, **execution has paused immediately upon completing Sprint 2**. No components of Sprint 3 (Categories, Stores, Products, Gallery, or Offers) have been commenced pending your review and formal approval.

---

## 1. Delivered Domain Architecture & Models

### 1.1 Vendor Identity & KYC Engine (`apps/vendors`)
* **`VendorStatus` State Machine**: Four strictly governed states: `PENDING` (awaiting review), `APPROVED` (live clearance), `REJECTED` (application denied with mandatory feedback), and `SUSPENDED` (temporary account freeze).
* **`VendorProfile`**: Links directly to the cryptographic identity (`User` OneToOne), capturing `owner_name`, `official_email`, `phone_number`, operational `status`, Admin `rejection_reason`, and approval audit timestamps (`approved_by`, `approved_at`).
* **`KycDocument` Repository**: Relational storage for vendor legal documents (`GSTIN`, `PAN`, `TRADE_LICENSE`, `ID_PROOF`, `ADDRESS_PROOF`) complete with cloud storage URIs (`document_url`), license identifiers (`document_number`), and verified state metrics.

### 1.2 Business Showroom & Location Engine (`apps/business`)
* **`BusinessProfile`**: Encapsulates public studio identity prior to catalog creation, bound directly to `VendorProfile`:
  * **Business Brand**: `business_name`, `description`, visual branding URIs (`logo_url`, `cover_url`).
  * **Physical Address & GPS**: `address_line_1`, `address_line_2`, `city`, `state`, `pincode`, `latitude`, `longitude`.
  * **Public Support Contacts**: `contact_email`, `contact_phone`.
  * **Business Timings**: Structured JSON schedule storage (`business_timings`) supporting daily operational hours (e.g., `{"Mon - Fri": "10:00 AM - 08:00 PM", "Sun": "By Appointment Only"}`).

---

## 2. API Endpoints & Governance Workflow Delivered

### 2.1 Partner Studio Onboarding & Management APIs (Tier: `VENDOR`)
* **`POST /api/v1/vendor/register/`**: Atomically initializes both `VendorProfile` (defaulting to `PENDING`) and `BusinessProfile` in a single transactional onboarding call.
* **`GET & PUT /api/v1/vendor/me/`**: Retreive or update legal owner details and inspect real-time approval status and Admin feedback reasoning.
* **`POST & GET /api/v1/vendor/kyc/`**: Submit legal KYC verification files (`GSTIN`, `PAN`, etc.) into the Admin compliance queue.
* **`GET & PUT /api/v1/business/me/`**: Refine showroom street address, support contacts, and daily operation timings during onboarding or operation.
* **`GET /api/v1/vendor/catalog-check/`**: Protected RBAC checkpoint verifying live marketplace approval clearance.

### 2.2 Executive Admin Governance APIs (Tier: `ADMIN` & `SUPERADMIN`)
* **`GET /api/v1/admin/vendors/pending/`**: Admin Review Queue — lists all partner studio onboarding applications currently in `PENDING` status along with complete Business Showroom details and attached KYC dossiers.
* **`GET /api/v1/admin/vendors/<uuid:pk>/`**: Inspect complete vendor audit history and KYC file links.
* **`POST /api/v1/admin/vendors/<uuid:pk>/approve/`**: Executive approval—transitions vendor status to `APPROVED`, timestamps approval audits, and sets pending KYC files to `VERIFIED`.
* **`POST /api/v1/admin/vendors/<uuid:pk>/reject/`**: Denies application requiring mandatory JSON body `{"rejection_reason": "<feedback>"}` for studio visibility.
* **`POST /api/v1/admin/vendors/<uuid:pk>/suspend/`**: Freezes active studios, transitioning account state to `SUSPENDED` with an audit reason.

### 2.3 Real-Time RBAC Authorization Shield (`IsApprovedVendor`)
Unlike standard memory checks, `IsApprovedVendor` invokes `.refresh_from_db()` on each invocation to verify live PostgreSQL/SQLite status. Any attempt by a `PENDING`, `REJECTED`, or `SUSPENDED` studio to access catalog management endpoints is immediately terminated with a `403 Forbidden` exception:
```json
{
  "error": true,
  "status_code": 403,
  "message": "Marketplace Approval Required: Your vendor account is currently REJECTED (Admin Reason: GSTIN document scan is blurry. Please re-upload clear certificate.). Only APPROVED partner studios can manage showrooms, catalog items, gallery images, and offers.",
  "details": "Permission denied."
}
```

---

## 3. Comprehensive Verification & Unit Testing

The complete test suite was executed via `python manage.py test`.

### Test Execution Summary
```
Operations to perform:
  Apply all migrations: accounts, admin, auth, business, contenttypes, sessions, token_blacklist, vendors
Running migrations:
  Applying vendors.0001_initial... OK
  Applying business.0001_initial... OK
Creating test database for alias 'default'...

Ran 10 tests in 0.413s
OK
System check identified no issues (0 silenced).
```

### Sprint 2 Test Matrix (All Passed)
| Test Case Name | Target Module | Condition Verified | Status |
| :--- | :--- | :--- | :--- |
| `test_complete_vendor_onboarding_to_admin_approval_lifecycle` | `apps/vendors` | Verifies full workflow: Registration creates `PENDING` vendor and `BusinessProfile`. Unapproved vendor receives `403 Forbidden` on catalog access. Vendor submits KYC doc. Admin views pending queue and executes APPROVE. Approved vendor is subsequently granted `200 OK` catalog clearance. | ✅ PASSED |
| `test_admin_rejection_and_suspension_workflows` | `apps/vendors` | Verifies Admin REJECT stores explicit feedback reason and returns exact reason in `403 Forbidden` payload when vendor attempts catalog operations. Verifies SUSPEND immediately revokes catalog clearance of active studios. | ✅ PASSED |
| `test_customer_cannot_access_vendor_or_admin_endpoints` | `apps/vendors` | Verifies standard Customer tier is rejected (`403 Forbidden`) when attempting onboarding registration or accessing Admin pending queues. | ✅ PASSED |
| `test_vendor_can_view_and_update_business_showroom_and_timings` | `apps/business` | Verifies vendor can read and update showroom physical address, contact phone/email, and structured daily business timings via `PUT /api/v1/business/me/`. | ✅ PASSED |
| *Plus 6 existing infrastructure & auth tests* | `common` / `accounts` | Health checks, Soft delete managers, OpenAPI schema validity, OTP JWT issuance, and multi-tier RBAC isolation. | ✅ PASSED |

---

## 4. Current Backend Directory Structure
```
backend/
├── manage.py                   
├── requirements.txt            
├── docker-compose.yml          
├── her_area_dev.sqlite3        
├── config/                     
│   ├── settings.py             
│   └── urls.py                 
└── apps/                       
    ├── common/                 # Foundation Infrastructure & Health
    ├── accounts/               # OTP, JWT & Multi-Tier Identity RBAC
    ├── vendors/                # [NEW] Vendor Onboarding & Admin Governance
    │   ├── models.py           # VendorProfile & KycDocument models
    │   ├── permissions.py      # IsApprovedVendor RBAC gate
    │   ├── serializers.py      # Onboarding & Admin action schemas
    │   ├── views.py            # Vendor registration & KYC upload views
    │   ├── admin_views.py      # Admin review, approve, reject & suspend views
    │   ├── urls.py             # Route /api/v1/vendor/
    │   ├── admin_urls.py       # Route /api/v1/admin/vendors/
    │   └── tests.py            # End-to-end Onboarding & Governance unit tests
    └── business/               # [NEW] Business Showroom & Location Engine
        ├── models.py           # BusinessProfile (Address, Contacts, Timings)
        ├── serializers.py      # Business showroom serializer
        ├── views.py            # Showroom read/update view (/api/v1/business/me/)
        ├── urls.py             # Route /api/v1/business/
        └── tests.py            # Business showroom profile & timing tests
```

---

## 5. Next Steps & Authorization Request
**Sprint 2 (Vendor Onboarding & Approval System) is fully completed, documented, and passing all 10 automated test gates.**

In accordance with your instructions: **"Do not begin Categories, Stores, Products, Gallery, or Offers until Sprint 2 is approved."**  
Please review the verification matrix above and confirm when you are ready to authorize implementation of **Sprint 3 (Categories, Approved Store Showrooms, Catalog Inventory & Gallery Management)**!
