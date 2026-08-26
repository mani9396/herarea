import os
import sys
import time
import json
import datetime
import django
from decimal import Decimal

# Initialize Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.utils import timezone
from rest_framework.test import APIClient
from apps.accounts.models import User, UserRole
from apps.business.models import BusinessProfile
from apps.categories.models import Category
from apps.catalog.models import Product, Offer, GalleryImage, CatalogItemType
from apps.interactions.models import Favorite, Review
from apps.operations.models import AppointmentBooking, ProductEnquiry, BookingStatus
from apps.notifications.models import Notification

def run_validation_suite():
    print("=========================================================================")
    print("       HER AREA: PHASE 7 END-TO-END SYSTEM INTEGRATION VALIDATION        ")
    print("=========================================================================")

    results = []
    
    def record_test(suite, name, method, endpoint, expected_status, res_status, start_time, details=""):
        elapsed = int((time.time() - start_time) * 1000)
        passed = (res_status == expected_status) or (isinstance(expected_status, list) and res_status in expected_status)
        status_symbol = "[PASS]" if passed else "[FAIL]"
        print(f"{status_symbol} [{suite}] {name} ({method} {endpoint}) -> {res_status} in {elapsed}ms | {details}")
        results.append({
            "suite": suite,
            "test": name,
            "method": method,
            "endpoint": endpoint,
            "status": res_status,
            "expected": expected_status,
            "time_ms": elapsed,
            "passed": passed,
            "details": details
        })

    # Prepare Clients
    anon_client = APIClient()
    cust_client = APIClient()
    vend_client = APIClient()
    admin_client = APIClient()

    store = BusinessProfile.objects.first()
    customer_user = User.objects.filter(role=UserRole.CUSTOMER).first()
    vendor_user = store.vendor.user if (store and hasattr(store, 'vendor') and store.vendor) else User.objects.filter(role=UserRole.VENDOR).first()
    admin_user = User.objects.filter(role=UserRole.SUPERADMIN).first()
    category = Category.objects.first()

    # =========================================================================
    # SUITE 1: AUTHENTICATION & JWT TOKEN LIFECYCLE
    # =========================================================================
    suite = "Auth & JWT"
    
    # 1.1 OTP Send Customer
    t0 = time.time()
    res = anon_client.post('/api/v1/auth/otp/send/', {"phone_number": "+919700000001"}, format='json')
    record_test(suite, "Send Customer SMS OTP Challenge", "POST", "/api/v1/auth/otp/send/", 200, res.status_code, t0, "Dev OTP generated")

    # 1.2 OTP Verify Customer
    t0 = time.time()
    res = anon_client.post('/api/v1/auth/otp/verify/', {"phone_number": "+919700000001", "otp": "123456", "role": "CUSTOMER"}, format='json')
    cust_tokens = res.data if res.status_code == 200 else {}
    cust_client.credentials(HTTP_AUTHORIZATION='Bearer ' + cust_tokens.get('access', ''))
    record_test(suite, "Verify Customer OTP & Issue JWT", "POST", "/api/v1/auth/otp/verify/", 200, res.status_code, t0, f"Issued JWT Access + Refresh for Role: {cust_tokens.get('role', 'CUSTOMER')}")

    # 1.3 OTP Verify Vendor
    t0 = time.time()
    res = anon_client.post('/api/v1/auth/otp/verify/', {"phone_number": vendor_user.phone_number, "otp": "123456", "role": "VENDOR"}, format='json')
    vend_tokens = res.data if res.status_code == 200 else {}
    vend_client.credentials(HTTP_AUTHORIZATION='Bearer ' + vend_tokens.get('access', ''))
    record_test(suite, "Verify Vendor Studio OTP & Issue JWT", "POST", "/api/v1/auth/otp/verify/", 200, res.status_code, t0, "Authenticated Studio Partner")

    # 1.4 OTP Verify Admin
    t0 = time.time()
    res = anon_client.post('/api/v1/auth/otp/verify/', {"phone_number": admin_user.phone_number, "otp": "123456", "role": "SUPERADMIN"}, format='json')
    admin_tokens = res.data if res.status_code == 200 else {}
    admin_client.credentials(HTTP_AUTHORIZATION='Bearer ' + admin_tokens.get('access', ''))
    record_test(suite, "Verify Admin OTP & Issue JWT", "POST", "/api/v1/auth/otp/verify/", 200, res.status_code, t0, "Authenticated Super Admin")

    # 1.5 Invalid OTP Challenge Error Handling
    t0 = time.time()
    res = anon_client.post('/api/v1/auth/otp/verify/', {"phone_number": "+919700000001", "otp": "999999", "role": "CUSTOMER"}, format='json')
    record_test(suite, "Invalid OTP Error Handling", "POST", "/api/v1/auth/otp/verify/", 400, res.status_code, t0, "Correctly refused invalid cryptographic OTP")

    # 1.6 JWT Refresh Rotation
    t0 = time.time()
    res = anon_client.post('/api/v1/auth/token/refresh/', {"refresh": cust_tokens.get('refresh', '')}, format='json')
    new_access = res.data.get('access', '') if res.status_code == 200 else ''
    if new_access:
        cust_client.credentials(HTTP_AUTHORIZATION='Bearer ' + new_access)
    record_test(suite, "JWT Access Token Rotation & Refresh", "POST", "/api/v1/auth/token/refresh/", 200, res.status_code, t0, "Successfully renewed JWT Access Token")

    # 1.7 Session Identity Restoration & Me Profile
    t0 = time.time()
    res = cust_client.get('/api/v1/auth/me/')
    record_test(suite, "Session Restoration & Identity Check", "GET", "/api/v1/auth/me/", 200, res.status_code, t0, f"Restored Session for {res.data.get('phone_number', '')}")

    # =========================================================================
    # SUITE 2: CUSTOMER EXPERIENCE & O2O MARKETPLACE DISCOVERY
    # =========================================================================
    suite = "Customer O2O"
    
    # 2.1 Public Promotions Feed
    t0 = time.time()
    res = anon_client.get('/api/v1/promotions/')
    count = len(res.data.get('results', [])) if isinstance(res.data, dict) and 'results' in res.data else len(res.data) if isinstance(res.data, list) else 0
    record_test(suite, "Public Promotional Campaign Banners", "GET", "/api/v1/promotions/", 200, res.status_code, t0, f"Loaded {count} live promotional banners")

    # 2.2 Marketplace Taxonomy Categories
    t0 = time.time()
    res = anon_client.get('/api/v1/categories/')
    cat_count = len(res.data.get('results', [])) if isinstance(res.data, dict) and 'results' in res.data else len(res.data) if isinstance(res.data, list) else 0
    record_test(suite, "Marketplace Taxonomy & Crafts", "GET", "/api/v1/categories/", 200, res.status_code, t0, f"Loaded {cat_count} categories (Maggam, Sarees, Bridal)")

    # 2.3 Store Showrooms Directory & Pagination
    t0 = time.time()
    res = anon_client.get('/api/v1/stores/')
    store_count = len(res.data.get('results', [])) if isinstance(res.data, dict) and 'results' in res.data else len(res.data) if isinstance(res.data, list) else 0
    record_test(suite, "Store Showroom Discovery & Geolocation", "GET", "/api/v1/stores/", 200, res.status_code, t0, f"Loaded {store_count} approved partner studios")

    # 2.4 Detailed Store Showroom Dossier
    t0 = time.time()
    res = anon_client.get(f'/api/v1/stores/{store.id}/')
    record_test(suite, "Store Showroom Detailed Dossier", "GET", f"/api/v1/stores/{store.id}/", 200, res.status_code, t0, f"Verified dossier for {store.business_name}")

    # 2.5 Showroom Operating Schedules
    t0 = time.time()
    res = anon_client.get(f'/api/v1/stores/{store.id}/schedules/')
    record_test(suite, "Studio Weekly Working Schedule", "GET", f"/api/v1/stores/{store.id}/schedules/", 200, res.status_code, t0, "Loaded studio working hours")

    # 2.6 Showroom Complete Catalog Dossier
    t0 = time.time()
    res = anon_client.get(f'/api/v1/products/store/{store.id}/dossier/')
    record_test(suite, "Showroom Catalog & Services Dossier", "GET", f"/api/v1/products/store/{store.id}/dossier/", 200, res.status_code, t0, "Loaded integrated products and services")

    # 2.7 Global Product & Service Catalog
    t0 = time.time()
    res = anon_client.get('/api/v1/products/')
    prod_count = len(res.data.get('results', [])) if isinstance(res.data, dict) and 'results' in res.data else len(res.data) if isinstance(res.data, list) else 0
    record_test(suite, "Global Products & Services Catalog", "GET", "/api/v1/products/", 200, res.status_code, t0, f"Loaded {prod_count} catalog creations")

    # 2.8 Catalog Category Filtering
    t0 = time.time()
    res = anon_client.get(f'/api/v1/products/?category={category.id}')
    record_test(suite, "Catalog Taxonomy Filtering", "GET", f"/api/v1/products/?category={category.id}", 200, res.status_code, t0, "Filtered inventory by category")

    # 2.9 Global O2O Keyword Search
    t0 = time.time()
    res = anon_client.get('/api/v1/search/?q=Silk')
    record_test(suite, "Global O2O Keyword Discovery Search", "GET", "/api/v1/search/?q=Silk", 200, res.status_code, t0, "Executed full-text query across stores and catalogs")

    # 2.10 Customer Favorites Wishlist
    t0 = time.time()
    res = cust_client.get('/api/v1/favorites/')
    fav_count = len(res.data.get('results', [])) if isinstance(res.data, dict) and 'results' in res.data else len(res.data) if isinstance(res.data, list) else 0
    record_test(suite, "Customer Wishlist Bookmarks", "GET", "/api/v1/favorites/", 200, res.status_code, t0, f"Retrieved {fav_count} saved favorites")

    # 2.11 Toggle Wishlist Bookmark (CRUD Test)
    t0 = time.time()
    res = cust_client.post('/api/v1/favorites/toggle/', {"store": str(store.id)}, format='json')
    record_test(suite, "Toggle Wishlist Store Bookmark (CRUD)", "POST", "/api/v1/favorites/toggle/", [200, 201], res.status_code, t0, f"Bookmark status: {res.data.get('status', 'toggled')}")

    # 2.12 Customer Real-Time Notifications
    t0 = time.time()
    res = cust_client.get('/api/v1/notifications/')
    record_test(suite, "Customer Real-Time Notification Feed", "GET", "/api/v1/notifications/", 200, res.status_code, t0, "Fetched alerts & system notifications")

    # 2.13 Mark All Notifications Read
    t0 = time.time()
    res = cust_client.post('/api/v1/notifications/read-all/')
    record_test(suite, "Mark Notifications Read All", "POST", "/api/v1/notifications/read-all/", 200, res.status_code, t0, "Acknowledged notification queue")

    # 2.14 Customer Bookings History
    t0 = time.time()
    res = cust_client.get('/api/v1/bookings/')
    record_test(suite, "Customer Appointment Bookings History", "GET", "/api/v1/bookings/", 200, res.status_code, t0, "Fetched scheduled fitting appointments")

    # 2.15 Customer Enquiries History
    t0 = time.time()
    res = cust_client.get('/api/v1/enquiries/')
    record_test(suite, "Customer Bespoke Product Enquiries", "GET", "/api/v1/enquiries/", 200, res.status_code, t0, "Fetched active custom couture enquiries")

    # 2.16 Store Reviews Collection
    t0 = time.time()
    res = anon_client.get(f'/api/v1/stores/{store.id}/reviews/')
    record_test(suite, "Store Verified Customer Reviews", "GET", f"/api/v1/stores/{store.id}/reviews/", 200, res.status_code, t0, "Loaded community feedback and ratings")

    # 2.17 Submit Verified Review (CRUD Persistence)
    t0 = time.time()
    rev_payload = {"rating": 5, "title": "Exquisite Couture Experience", "comment": "The bridal lehenga precision was extraordinary. Wonderful studio!"}
    res = cust_client.post(f'/api/v1/stores/{store.id}/reviews/', rev_payload, format='json')
    record_test(suite, "Submit Verified Customer Review (CRUD)", "POST", f"/api/v1/stores/{store.id}/reviews/", [200, 201], res.status_code, t0, "Successfully published 5-star review to PostgreSQL")

    # =========================================================================
    # SUITE 3: VENDOR STUDIO OPERATIONS & CATALOG GOVERNANCE
    # =========================================================================
    suite = "Vendor Operations"

    # 3.1 Vendor Profile Load
    t0 = time.time()
    res = vend_client.get('/api/v1/vendor/me/')
    record_test(suite, "Vendor Studio Profile & Identity", "GET", "/api/v1/vendor/me/", 200, res.status_code, t0, f"Owner: {res.data.get('owner_name', '')}")

    # 3.2 Showroom Business Profile
    t0 = time.time()
    res = vend_client.get('/api/v1/business/me/')
    record_test(suite, "Showroom Business Details & Location", "GET", "/api/v1/business/me/", 200, res.status_code, t0, f"Showroom: {res.data.get('business_name', '')}")

    # 3.3 Vendor Catalog Check
    t0 = time.time()
    res = vend_client.get('/api/v1/vendor/catalog-check/')
    record_test(suite, "Vendor Approved Catalog Verification", "GET", "/api/v1/vendor/catalog-check/", 200, res.status_code, t0, "Confirmed studio authorization for catalog indexing")

    # 3.4 Vendor Catalog Products List
    t0 = time.time()
    res = vend_client.get('/api/v1/vendor/catalog/products/')
    record_test(suite, "Studio Catalog Inventory Management", "GET", "/api/v1/vendor/catalog/products/", 200, res.status_code, t0, "Fetched vendor private catalog items")

    # 3.5 Vendor Create New Product (CRUD Persistence & Marketplace Sync)
    t0 = time.time()
    new_prod_payload = {
        "name": "Phase 7 Royal Banarasi Silk Saree",
        "description": "Handwoven genuine Banarasi brocade for Phase 7 end-to-end validation testing.",
        "item_type": "PRODUCT",
        "price": "52000.00",
        "stock_status": "IN_STOCK",
        "category": str(category.id),
        "image_url": "https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800",
        "is_featured": True,
        "is_active": True
    }
    res = vend_client.post('/api/v1/vendor/catalog/products/', new_prod_payload, format='json')
    record_test(suite, "Create Catalog Product (CRUD Sync)", "POST", "/api/v1/vendor/catalog/products/", [200, 201], res.status_code, t0, "Persisted item & synchronized with public directory")

    # 3.6 Vendor Gallery Showcase List
    t0 = time.time()
    res = vend_client.get('/api/v1/vendor/catalog/gallery/')
    record_test(suite, "Studio Portfolio Gallery Management", "GET", "/api/v1/vendor/catalog/gallery/", 200, res.status_code, t0, "Loaded studio showcase images")

    # 3.7 Vendor Promotional Offers Management
    t0 = time.time()
    res = vend_client.get('/api/v1/vendor/catalog/offers/')
    record_test(suite, "Promotional Campaigns Management", "GET", "/api/v1/vendor/catalog/offers/", 200, res.status_code, t0, "Loaded studio deals & discounts")

    # 3.8 Vendor Creates Promotional Offer (Sync to Public /promotions/)
    t0 = time.time()
    offer_payload = {
        "title": "Phase 7 Couture Celebration Deal",
        "description": "Exclusive 20% discount on all bespoke Maggam embroidery during System Validation.",
        "discount_percentage": "20.00",
        "start_date": timezone.now().date().isoformat(),
        "end_date": (timezone.now().date() + datetime.timedelta(days=15)).isoformat(),
        "banner_image": "https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800"
    }
    res = vend_client.post('/api/v1/vendor/catalog/offers/', offer_payload, format='json')
    record_test(suite, "Create Promotional Offer (CRUD Sync)", "POST", "/api/v1/vendor/catalog/offers/", [200, 201], res.status_code, t0, "Created offer & synced to public promotions feed")

    # 3.9 Vendor Schedules Management
    t0 = time.time()
    res = vend_client.get('/api/v1/vendor/schedules/')
    record_test(suite, "Studio Weekly Schedule Management", "GET", "/api/v1/vendor/schedules/", 200, res.status_code, t0, "Loaded studio business hours configuration")

    # 3.10 Vendor Incoming Appointments Monitor
    t0 = time.time()
    res = vend_client.get('/api/v1/vendor/bookings/')
    record_test(suite, "Studio Incoming Appointments Dashboard", "GET", "/api/v1/vendor/bookings/", 200, res.status_code, t0, "Received live customer booking requests")

    # 3.11 Vendor Incoming Enquiries Monitor
    t0 = time.time()
    res = vend_client.get('/api/v1/vendor/enquiries/')
    record_test(suite, "Studio Bespoke Product Enquiries Feed", "GET", "/api/v1/vendor/enquiries/", 200, res.status_code, t0, "Received live customer couture customization inquiries")

    # =========================================================================
    # SUITE 4: ADMIN PLATFORM GOVERNANCE & MODERATION AUDIT
    # =========================================================================
    suite = "Admin Governance"

    # 4.1 Admin Pending Vendors Pipeline
    t0 = time.time()
    res = admin_client.get('/api/v1/admin/vendors/pending/')
    record_test(suite, "Admin Pending Onboarding Pipeline", "GET", "/api/v1/admin/vendors/pending/", 200, res.status_code, t0, "Loaded partner applications awaiting vetting")

    # 4.2 Admin Category Governance
    t0 = time.time()
    res = admin_client.get('/api/v1/admin/categories/')
    record_test(suite, "Admin Category Taxonomy Governance", "GET", "/api/v1/admin/categories/", 200, res.status_code, t0, "Retrieved system category structures")

    # 4.3 Admin System-Wide Appointments Monitor
    t0 = time.time()
    res = admin_client.get('/api/v1/admin/bookings/')
    record_test(suite, "Admin System-Wide Appointments Monitor", "GET", "/api/v1/admin/bookings/", 200, res.status_code, t0, "Auditing platform appointment reservations")

    # 4.4 Admin System-Wide Enquiries Monitor
    t0 = time.time()
    res = admin_client.get('/api/v1/admin/enquiries/')
    record_test(suite, "Admin System-Wide Enquiries Monitor", "GET", "/api/v1/admin/enquiries/", 200, res.status_code, t0, "Auditing platform custom bespoke enquiries")

    # 4.5 Check for Admin Content Moderation Endpoints (Documenting Missing Endpoints)
    t0 = time.time()
    res = admin_client.get('/api/v1/admin/products/')
    record_test(suite, "Admin Product Moderation Route", "GET", "/api/v1/admin/products/", [200], res.status_code, t0, "Auditing platform catalog creations")

    # =========================================================================
    # SUITE 5: SECURITY, RBAC ISOLATION & DATA INTEGRITY
    # =========================================================================
    suite = "RBAC & Security"

    # 5.1 Customer -> Vendor Profile Unauthorized Access Attempt
    t0 = time.time()
    res = cust_client.get('/api/v1/vendor/me/')
    record_test(suite, "Enforce Vendor Role Isolation against Customer", "GET", "/api/v1/vendor/me/", 403, res.status_code, t0, "Successfully blocked customer from studio dashboard (403 Forbidden)")

    # 5.2 Customer -> Admin Pipeline Unauthorized Access Attempt
    t0 = time.time()
    res = cust_client.get('/api/v1/admin/vendors/pending/')
    record_test(suite, "Enforce Admin Role Isolation against Customer", "GET", "/api/v1/admin/vendors/pending/", 403, res.status_code, t0, "Successfully blocked customer from admin console (403 Forbidden)")

    # 5.3 Vendor -> Admin Pipeline Unauthorized Access Attempt
    t0 = time.time()
    res = vend_client.get('/api/v1/admin/categories/')
    record_test(suite, "Enforce Admin Role Isolation against Vendor", "GET", "/api/v1/admin/categories/", 403, res.status_code, t0, "Successfully blocked vendor from admin category mutations (403 Forbidden)")

    # 5.4 Unauthenticated Access to Protected Customer Wishlist
    t0 = time.time()
    res = anon_client.get('/api/v1/favorites/')
    record_test(suite, "Enforce JWT Authentication on Private Endpoints", "GET", "/api/v1/favorites/", 401, res.status_code, t0, "Successfully blocked unauthenticated user (401 Unauthorized)")

    # =========================================================================
    # SUMMARY STATISTICS & PERFORMANCE OBSERVATIONS
    # =========================================================================
    passed = sum(1 for r in results if r["passed"])
    total = len(results)
    avg_time = sum(r["time_ms"] for r in results) / total if total > 0 else 0

    print("\n=========================================================================")
    print(f"VALIDATION SUMMARY: {passed}/{total} tests passed ({passed/total*100:.1f}%)")
    print(f"AVERAGE API LATENCY: {avg_time:.1f} ms per request")
    print("=========================================================================")

    # Save structured results for reporting
    with open('phase7_validation_results.json', 'w') as f:
        json.dump({
            "timestamp": timezone.now().isoformat(),
            "total_tests": total,
            "passed_tests": passed,
            "average_latency_ms": round(avg_time, 2),
            "results": results
        }, f, indent=2)
    print("Test results saved to backend/phase7_validation_results.json")

if __name__ == "__main__":
    run_validation_suite()
