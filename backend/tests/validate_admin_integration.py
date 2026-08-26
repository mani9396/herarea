import os
import sys
import json
import uuid
import django

# Ensure backend project root is in sys.path for module discovery
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

# Setup Django project environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from apps.accounts.models import User, UserRole
from apps.catalog.models import Product, Offer, GalleryImage
from apps.categories.models import Category
from apps.vendors.models import VendorProfile
from apps.business.models import BusinessProfile
from apps.interactions.models import Review
from apps.notifications.models import Notification
from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken, OutstandingToken

def get_jwt_for_user(client, phone, role_str):
    # Ensure user exists in DB with appropriate role and unique email
    email = f"{role_str.lower()}_suite_72@herarea.in"
    user = User.objects.filter(phone_number=phone).first() or User.objects.filter(email=email).first()
    if not user:
        user = User.objects.create(phone_number=phone, email=email, role=role_str, is_verified=True, is_active=True)
    else:
        user.phone_number = phone
        user.email = email
        user.role = role_str
        user.is_active = True
        user.is_verified = True
        user.save(update_fields=['phone_number', 'email', 'role', 'is_active', 'is_verified'])

    refresh = RefreshToken.for_user(user)
    refresh['role'] = user.role
    refresh['phone_number'] = user.phone_number
    return user, str(refresh.access_token), str(refresh)

def run_suite():
    print("=================================================================================")
    print("      HER AREA: Phase 7.2 Comprehensive Admin Integration Test Suite             ")
    print("=================================================================================")
    
    client = APIClient()
    total_tests = 0
    passed_tests = 0
    errors = []

    def check(test_name, condition, error_msg="Assertion failed"):
        nonlocal total_tests, passed_tests
        total_tests += 1
        if condition:
            passed_tests += 1
            print(f"[PASS] {test_name}")
            return True
        else:
            print(f"[FAIL] {test_name} -> {error_msg}")
            errors.append((test_name, error_msg))
            return False

    # -------------------------------------------------------------------------
    # SECTION 1: Authentication & JWT Lifecycle Validation
    # -------------------------------------------------------------------------
    print("\n--- Section 1: Authentication & JWT Lifecycle Verification ---")
    
    # 1.1 OTP Send
    res_send = client.post("/api/v1/auth/otp/send/", {"phone_number": "+918888800001"}, format="json")
    check("OTP Send Endpoint (HTTP 200)", res_send.status_code == status.HTTP_200_OK, f"Got status {res_send.status_code}")
    check("OTP Send Response Schema", "dev_test_otp" in res_send.data and "expires_in_seconds" in res_send.data)

    # 1.2 OTP Verify (JWT Login) & PostgreSQL Persistence
    res_verify = client.post("/api/v1/auth/otp/verify/", {"phone_number": "+918888800001", "otp": "123456", "role": "ADMIN"}, format="json")
    check("OTP Verify JWT Issuance (HTTP 200)", res_verify.status_code == status.HTTP_200_OK, f"Got status {res_verify.status_code}")
    check("JWT Response Schema Validation", all(k in res_verify.data for k in ["access", "refresh", "user_id", "role"]))
    check("Role Asserted as ADMIN", res_verify.data.get("role") == "ADMIN")
    
    auth_user = User.objects.filter(phone_number="+918888800001").first()
    check("PostgreSQL Account Persistence", auth_user is not None and auth_user.role == UserRole.ADMIN)

    # 1.3 OTP Verification Failure
    res_fail = client.post("/api/v1/auth/otp/verify/", {"phone_number": "+918888800001", "otp": "999999", "role": "ADMIN"}, format="json")
    check("Invalid OTP Authentication Failure (HTTP 400)", res_fail.status_code == status.HTTP_400_BAD_REQUEST)

    # 1.4 JWT Token Refresh
    refresh_token = res_verify.data["refresh"]
    res_refresh = client.post("/api/v1/auth/token/refresh/", {"refresh": refresh_token}, format="json")
    check("JWT Refresh Token Issuance (HTTP 200)", res_refresh.status_code == status.HTTP_200_OK)
    check("Refreshed Access Token Schema", "access" in res_refresh.data)

    # 1.5 Logout & Session Revocation
    res_logout = client.post("/api/v1/auth/logout/", {"refresh": refresh_token}, format="json")
    check("Logout Endpoint Revocability (HTTP 200)", res_logout.status_code == status.HTTP_200_OK)

    # -------------------------------------------------------------------------
    # SECTION 2: RBAC Security Barrier & Role Authorization Matrix
    # -------------------------------------------------------------------------
    print("\n--- Section 2: RBAC Security Barrier & Role Authorization Matrix ---")
    
    super_user, super_access, _ = get_jwt_for_user(client, "+917777700001", UserRole.SUPERADMIN)
    super_user.is_superuser = True
    super_user.save()
    
    admin_user, admin_access, _ = get_jwt_for_user(client, "+917777700002", UserRole.ADMIN)
    vendor_user, vendor_access, _ = get_jwt_for_user(client, "+917777700003", UserRole.VENDOR)
    customer_user, customer_access, _ = get_jwt_for_user(client, "+917777700004", UserRole.CUSTOMER)

    admin_endpoints = [
        ("/api/v1/admin/products/", "Products Moderation"),
        ("/api/v1/admin/offers/", "Offers Oversight"),
        ("/api/v1/admin/gallery/", "Gallery Showcase"),
        ("/api/v1/admin/customers/", "Customer Governance"),
        ("/api/v1/admin/reviews/", "Review Takedown"),
        ("/api/v1/admin/activity-logs/", "Activity Feed"),
        ("/api/v1/admin/notifications/", "Notification Broadcasts"),
        ("/api/v1/admin/analytics/", "Platform Analytics"),
    ]

    for url, desc in admin_endpoints:
        # SUPER_ADMIN -> 200 OK
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {super_access}")
        res = client.get(url)
        check(f"RBAC [SUPER_ADMIN] -> {url} ({desc})", res.status_code == status.HTTP_200_OK, f"Got HTTP {res.status_code}")

        # ADMIN -> 200 OK
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {admin_access}")
        res = client.get(url)
        check(f"RBAC [ADMIN] -> {url} ({desc})", res.status_code == status.HTTP_200_OK, f"Got HTTP {res.status_code}")

        # VENDOR -> 403 FORBIDDEN
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {vendor_access}")
        res = client.get(url)
        check(f"RBAC [VENDOR] -> {url} (Blocked 403)", res.status_code == status.HTTP_403_FORBIDDEN, f"Got HTTP {res.status_code}")

        # CUSTOMER -> 403 FORBIDDEN
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {customer_access}")
        res = client.get(url)
        check(f"RBAC [CUSTOMER] -> {url} (Blocked 403)", res.status_code == status.HTTP_403_FORBIDDEN, f"Got HTTP {res.status_code}")

        # UNAUTHENTICATED -> 401 UNAUTHORIZED
        client.credentials()
        res = client.get(url)
        check(f"RBAC [UNAUTHENTICATED] -> {url} (Blocked 401)", res.status_code in [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN], f"Got HTTP {res.status_code}")

    # -------------------------------------------------------------------------
    # SECTION 3: CRUD API Verification & PostgreSQL Database Persistence
    # -------------------------------------------------------------------------
    print("\n--- Section 3: CRUD Moderation APIs & PostgreSQL Database Persistence ---")
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {admin_access}")

    # Create test dependencies in database
    category, _ = Category.objects.get_or_create(name="E2E Test Category", slug="e2e-test-category")
    vendor_prof, _ = VendorProfile.objects.get_or_create(user=vendor_user, defaults={"status": "APPROVED"})
    business, _ = BusinessProfile.objects.get_or_create(
        vendor=vendor_prof,
        defaults={"business_name": "E2E Studio", "contact_phone": "+917777700003"}
    )

    # 3.1 Product Moderation Delete
    dummy_product = Product.objects.create(
        category=category,
        business_profile=business,
        name="Non-Compliant Product",
        price=4999.00
    )
    prod_id = dummy_product.id
    res_del_prod = client.delete(f"/api/v1/admin/products/{prod_id}/")
    check("Product Moderation Takedown API (HTTP 204/200)", res_del_prod.status_code in [200, 204], f"Got HTTP {res_del_prod.status_code}")
    check("PostgreSQL Product Deletion Persistence", not Product.objects.filter(id=prod_id).exists())

    # 3.2 Offer Moderation Delete
    dummy_offer = Offer.objects.create(
        business_profile=business,
        title="Unauthorized 90% Discount",
        promo_code="UNAUTH90",
        description="Unauthorized discount",
        discount_percentage=90
    )
    offer_id = dummy_offer.id
    res_del_offer = client.delete(f"/api/v1/admin/offers/{offer_id}/")
    check("Offer Moderation Expiry API (HTTP 204/200)", res_del_offer.status_code in [200, 204], f"Got HTTP {res_del_offer.status_code}")
    check("PostgreSQL Offer Deletion Persistence", not Offer.objects.filter(id=offer_id).exists())

    # 3.3 Gallery Moderation Delete
    dummy_gallery = GalleryImage.objects.create(
        business_profile=business,
        image_url="https://herarea.in/static/test_gallery.jpg",
        caption="Non-compliant photo"
    )
    gal_id = dummy_gallery.id
    res_del_gal = client.delete(f"/api/v1/admin/gallery/{gal_id}/")
    check("Gallery Moderation Deletion API (HTTP 204/200)", res_del_gal.status_code in [200, 204], f"Got HTTP {res_del_gal.status_code}")
    check("PostgreSQL Gallery Deletion Persistence", not GalleryImage.objects.filter(id=gal_id).exists())

    # 3.4 Customer Management (Toggle Block Status)
    target_cust, _ = User.objects.get_or_create(phone_number="+915555544444", defaults={"role": UserRole.CUSTOMER, "is_active": True})
    cust_id = target_cust.id
    res_block = client.patch(f"/api/v1/admin/customers/{cust_id}/", {"is_blocked": True}, format="json")
    check("Customer Block Toggle Governance API (HTTP 200)", res_block.status_code == status.HTTP_200_OK, f"Got HTTP {res_block.status_code}")
    target_cust.refresh_from_db()
    check("PostgreSQL Account Restriction Persistence (is_active=False)", target_cust.is_active is False)

    # 3.5 Review Moderation Delete
    dummy_review = Review.objects.create(
        user=customer_user,
        store=business,
        rating=1,
        comment="Abusive defamatory testimonial content"
    )
    rev_id = dummy_review.id
    res_del_rev = client.delete(f"/api/v1/admin/reviews/{rev_id}/")
    check("Review Moderation Takedown API (HTTP 204/200)", res_del_rev.status_code in [200, 204], f"Got HTTP {res_del_rev.status_code}")
    check("PostgreSQL Review Deletion Persistence", not Review.objects.filter(id=rev_id).exists())

    # 3.6 Notification Broadcast Transmitter
    payload = {
        "title": "E2E Platform Verified",
        "body": "Executive audit complete across PostgreSQL relational layers.",
        "targetGroup": "All Users"
    }
    res_notif = client.post("/api/v1/admin/notifications/broadcast/", payload, format="json")
    check("Broadcast Notification Dispatch API (HTTP 201)", res_notif.status_code == status.HTTP_201_CREATED, f"Got HTTP {res_notif.status_code}")
    check("PostgreSQL Notification Bulk Persistence", Notification.objects.filter(title="E2E Platform Verified").count() > 0)

    # 3.7 Analytics & Activity Log Schema Integrity
    res_analytics = client.get("/api/v1/admin/analytics/")
    check("Analytics Telemetry Schema Integrity", res_analytics.status_code == 200 and "infrastructure_health" in res_analytics.data and "kpi_metrics" in res_analytics.data)
    
    res_logs = client.get("/api/v1/admin/activity-logs/")
    check("Activity Log Surveillance Feed Schema Integrity", res_logs.status_code == 200 and isinstance(res_logs.data, list))

    # -------------------------------------------------------------------------
    # SUMMARY
    # -------------------------------------------------------------------------
    print("\n=================================================================================")
    print(f"               TEST SUITE SUMMARY: {passed_tests} / {total_tests} PASSED                   ")
    print("=================================================================================")
    
    if passed_tests == total_tests and len(errors) == 0:
        print("[SUCCESS] All Django integration tests passed. Full RBAC isolation and PostgreSQL database persistence confirmed.")
        sys.exit(0)
    else:
        print("[FAILURE] Some tests did not meet requirements:")
        for name, msg in errors:
            print(f"  - {name}: {msg}")
        sys.exit(1)

if __name__ == "__main__":
    run_suite()
