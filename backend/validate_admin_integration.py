import os
import sys
import django
import json
import uuid

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from rest_framework.test import APIClient
from rest_framework import status
from apps.accounts.models import User, UserRole

def run_admin_integration_validation():
    print("=================================================================================")
    print("           HER AREA: Phase 7.2 Admin Console Integration & RBAC Audit             ")
    print("=================================================================================")
    
    client = APIClient()
    
    # 1. Prepare Test Identities
    print("\n[+] Preparing authenticated role personas in PostgreSQL database...")
    
    superadmin, _ = User.objects.get_or_create(
        phone_number="+919999988801",
        defaults={'email': 'superadmin_audit@herarea.in', 'role': UserRole.SUPERADMIN, 'is_superuser': True, 'is_active': True}
    )
    admin_user, _ = User.objects.get_or_create(
        phone_number="+919999988802",
        defaults={'email': 'admin_audit@herarea.in', 'role': UserRole.ADMIN, 'is_active': True}
    )
    vendor_user, _ = User.objects.get_or_create(
        phone_number="+919999988803",
        defaults={'email': 'vendor_audit@herarea.in', 'role': UserRole.VENDOR, 'is_active': True}
    )
    customer_user, _ = User.objects.get_or_create(
        phone_number="+919999988804",
        defaults={'email': 'customer_audit@herarea.in', 'role': UserRole.CUSTOMER, 'is_active': True}
    )
    
    endpoints = [
        ("GET", "/api/v1/admin/products/", "Product Moderation Queue"),
        ("GET", "/api/v1/admin/offers/", "Promotional Campaigns Oversight"),
        ("GET", "/api/v1/admin/gallery/", "Studio Gallery Showcase Moderation"),
        ("GET", "/api/v1/admin/customers/", "Customer Accounts Governance"),
        ("GET", "/api/v1/admin/reviews/", "Community Review Takedown Queue"),
        ("GET", "/api/v1/admin/activity-logs/", "Real-Time System Activity Feed"),
        ("GET", "/api/v1/admin/notifications/", "Historical Push Announcement Broadcasts"),
    ]
    
    passed_tests = 0
    total_tests = 0
    
    # 2. Test Read / List Endpoints across Role Hierarchies
    print("\n[+] Executing RBAC security barrier and functional response verification...")
    print("-" * 85)
    print(f"{'Endpoint URL':<35} | {'Role Persona':<14} | {'Expected':<10} | {'Actual':<10} | {'Status'}")
    print("-" * 85)
    
    for method, url, desc in endpoints:
        # Test SuperAdmin (Should pass 200)
        total_tests += 1
        client.force_authenticate(user=superadmin)
        res_super = client.get(url)
        status_super = res_super.status_code
        is_pass_super = status_super == 200
        if is_pass_super: passed_tests += 1
        print(f"{url:<35} | {'SUPER_ADMIN':<14} | {'200 OK':<10} | {status_super:<10} | {'[PASS]' if is_pass_super else '[FAIL]'}")
        
        # Test regular Admin (Should pass 200)
        total_tests += 1
        client.force_authenticate(user=admin_user)
        res_admin = client.get(url)
        status_admin = res_admin.status_code
        is_pass_admin = status_admin == 200
        if is_pass_admin: passed_tests += 1
        print(f"{url:<35} | {'ADMIN':<14} | {'200 OK':<10} | {status_admin:<10} | {'[PASS]' if is_pass_admin else '[FAIL]'}")
        
        # Test Vendor (Should be forbidden 403)
        total_tests += 1
        client.force_authenticate(user=vendor_user)
        res_vendor = client.get(url)
        status_vendor = res_vendor.status_code
        is_pass_vendor = status_vendor == 403
        if is_pass_vendor: passed_tests += 1
        print(f"{url:<35} | {'VENDOR':<14} | {'403 FORBID':<10} | {status_vendor:<10} | {'[PASS]' if is_pass_vendor else '[FAIL]'}")
        
        # Test Customer (Should be forbidden 403)
        total_tests += 1
        client.force_authenticate(user=customer_user)
        res_cust = client.get(url)
        status_cust = res_cust.status_code
        is_pass_cust = status_cust == 403
        if is_pass_cust: passed_tests += 1
        print(f"{url:<35} | {'CUSTOMER':<14} | {'403 FORBID':<10} | {status_cust:<10} | {'[PASS]' if is_pass_cust else '[FAIL]'}")
        print("-" * 85)

    # 3. Test Broadcast Notification Post Endpoint
    print("\n[+] Testing System Broadcast Notification Transmitter (/api/v1/admin/notifications/broadcast/)...")
    total_tests += 1
    client.force_authenticate(user=admin_user)
    payload = {
        "title": "Platform Maintenance Notice",
        "body": "System infrastructure upgrades will complete within 1 hour.",
        "targetGroup": "All Users"
    }
    res_broadcast = client.post("/api/v1/admin/notifications/broadcast/", payload, format="json")
    is_pass_broadcast = res_broadcast.status_code == 201
    if is_pass_broadcast: passed_tests += 1
    print(f"[{'PASSED' if is_pass_broadcast else 'FAILED'}] Broadcast dispatch returned HTTP {res_broadcast.status_code}: {res_broadcast.data.get('detail')}")
    
    # 4. Test Unauthenticated Access Rejection
    total_tests += 1
    client.logout()
    client.force_authenticate(user=None)
    res_unauth = client.get("/api/v1/admin/activity-logs/")
    is_pass_unauth = res_unauth.status_code in [401, 403]
    if is_pass_unauth: passed_tests += 1
    print(f"[{'PASSED' if is_pass_unauth else 'FAILED'}] Anonymous external invocation blocked with HTTP {res_unauth.status_code}")

    print("\n=================================================================================")
    print(f"           AUDIT RESULTS: {passed_tests}/{total_tests} Tests Passed Successfully           ")
    print("=================================================================================")
    
    if passed_tests == total_tests:
        print("[SUCCESS]: All Admin endpoints are live, functioning, and securely isolated via RBAC.")
        sys.exit(0)
    else:
        print("[WARNING]: Some tests did not meet expected criteria.")
        sys.exit(1)

if __name__ == "__main__":
    run_admin_integration_validation()
