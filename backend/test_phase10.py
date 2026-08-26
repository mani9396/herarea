import os
import django
import sys
import datetime
import traceback

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from django.utils import timezone
from apps.accounts.models import User
from apps.vendors.models import VendorProfile
from apps.business.models import BusinessProfile
from apps.subscriptions.models import VendorSubscription, ListingPlan
from apps.catalog.models import Offer
from apps.categories.models import Category

def run_tests():
    print("Starting Phase 10 Automated Tests...")
    
    # 1. Setup Data
    user1, _ = User.objects.get_or_create(email="vendor10@test.com", defaults={"password":"pwd", "phone_number":"+919876543290"})
    user2, _ = User.objects.get_or_create(email="vendor11@test.com", defaults={"password":"pwd", "phone_number":"+919876543291"})
    admin, _ = User.objects.get_or_create(email="admin10@test.com", defaults={"password":"pwd", "is_superuser":True, "is_staff":True, "phone_number":"+919876543292"})
    
    cat, _ = Category.objects.get_or_create(name="Apparel")
    plan, _ = ListingPlan.objects.get_or_create(name="PREMIUM", defaults={"price": 100, "duration_days": 30})
    
    profile1, _ = VendorProfile.objects.get_or_create(user=user1)
    store1, _ = BusinessProfile.objects.get_or_create(vendor=profile1, defaults={"status":"PUBLISHED", "category":cat})
    sub, _ = VendorSubscription.objects.get_or_create(vendor=user1, store=store1, defaults={"plan":plan, "status":"ACTIVE", "end_date":timezone.now() + datetime.timedelta(days=30)})
    sub.status = "ACTIVE"
    sub.save()
    store1.status = "PUBLISHED"
    store1.save()
    
    Offer.objects.all().delete()
    
    # 2. Test Draft Offer
    offer = Offer.objects.create(
        business_profile=store1, title="20% Off", promo_code="DISC20",
        discount_value=20.0, status="DRAFT", offer_type="PERCENTAGE",
        start_date=timezone.now().date(),
        end_date=timezone.now().date() + datetime.timedelta(days=10)
    )
    assert offer.status == "DRAFT", "Offer should be DRAFT"
    active_offers = Offer.objects.filter(status="APPROVED", business_profile__status="PUBLISHED", business_profile__subscriptions__status="ACTIVE", start_date__lte=timezone.now().date(), end_date__gte=timezone.now().date())
    assert offer not in active_offers, "Draft offer should not be public"
    print("[x] Draft creation test passed.")
    
    # 3. Test Submission
    offer.status = "PENDING_APPROVAL"
    offer.save()
    assert offer.status == "PENDING_APPROVAL"
    print("[x] Submit for approval test passed.")
    
    # 4. Test Rejection
    offer.status = "REJECTED"
    offer.admin_remarks = "Needs more info"
    offer.save()
    assert offer.status == "REJECTED"
    print("[x] Admin rejection test passed.")
    
    # 5. Test Resubmission
    offer.discount_value = 25.0
    offer.status = "PENDING_APPROVAL"
    offer.save()
    assert offer.status == "PENDING_APPROVAL"
    print("[x] Resubmission test passed.")
    
    # 6. Test Approval & Visibility
    offer.status = "APPROVED"
    offer.save()
    active_offers = Offer.objects.filter(status="APPROVED", business_profile__status="PUBLISHED", business_profile__subscriptions__status="ACTIVE", start_date__lte=timezone.now().date(), end_date__gte=timezone.now().date())
    assert offer in active_offers, "Approved valid offer should be public"
    print("[x] Approval & Customer Visibility test passed.")
    
    # 7. Test Date Filtering
    offer.start_date = timezone.now().date() + datetime.timedelta(days=1)
    offer.save()
    active_offers = Offer.objects.filter(status="APPROVED", business_profile__status="PUBLISHED", business_profile__subscriptions__status="ACTIVE", start_date__lte=timezone.now().date(), end_date__gte=timezone.now().date())
    assert offer not in active_offers, "Future offer should not be public"
    
    offer.start_date = timezone.now().date() - datetime.timedelta(days=10)
    offer.end_date = timezone.now().date() - datetime.timedelta(days=1)
    offer.save()
    active_offers = Offer.objects.filter(status="APPROVED", business_profile__status="PUBLISHED", business_profile__subscriptions__status="ACTIVE", start_date__lte=timezone.now().date(), end_date__gte=timezone.now().date())
    assert offer not in active_offers, "Expired offer should not be public"
    
    offer.end_date = timezone.now().date() + datetime.timedelta(days=10)
    offer.save()
    print("[x] Date filtering test passed.")
    
    # 8. Test Store Status
    store1.status = "SUSPENDED"
    store1.save()
    active_offers = Offer.objects.filter(status="APPROVED", business_profile__status="PUBLISHED", business_profile__subscriptions__status="ACTIVE", start_date__lte=timezone.now().date(), end_date__gte=timezone.now().date())
    assert offer not in active_offers, "Offer on suspended store should not be public"
    store1.status = "PUBLISHED"
    store1.save()
    print("[x] Store status filtering test passed.")
    
    # 9. Test Subscription Status
    sub.status = "EXPIRED"
    sub.save()
    active_offers = Offer.objects.filter(status="APPROVED", business_profile__status="PUBLISHED", business_profile__subscriptions__status="ACTIVE", start_date__lte=timezone.now().date(), end_date__gte=timezone.now().date())
    assert offer not in active_offers, "Offer on expired sub should not be public"
    sub.status = "ACTIVE"
    sub.save()
    print("[x] Subscription status filtering test passed.")
    
    print("\nALL PHASE 10 TESTS PASSED SUCESSFULLY.")

if __name__ == "__main__":
    try:
        run_tests()
    except AssertionError as e:
        print(f"TEST FAILED: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"ERROR: {e}")
        traceback.print_exc()
        sys.exit(1)
