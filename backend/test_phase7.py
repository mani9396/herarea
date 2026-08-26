import os
import django
import uuid

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.test import Client
from apps.accounts.models import User
from apps.vendors.models import VendorProfile, VendorStatus
from apps.business.models import BusinessProfile, StoreStatus
from apps.subscriptions.models import VendorSubscription, ListingPlan

def print_test(name, success):
    print(f"{'PASS' if success else 'FAIL'}: {name}")

def run_tests():
    print("============================================================")
    print("PHASE 7 AUTOMATED DISCOVERY TEST SUITE")
    print("============================================================\n")

    BusinessProfile.objects.all().delete()
    VendorSubscription.objects.all().delete()
    VendorProfile.objects.all().delete()
    User.objects.filter(email__startswith='vendor_test_').delete()
    User.objects.filter(email__startswith='customer_test_').delete()

    client = Client()

    # Create Plan
    plan, _ = ListingPlan.objects.get_or_create(
        name='Phase 7 Plan',
        defaults={'price': 1000, 'duration_days': 30, 'is_active': True}
    )

    # Helper to create store
    def create_store(letter, status, active_sub, lat, lon):
        user, _ = User.objects.get_or_create(
            email=f'vendor_test_{letter}@test.com',
            defaults={'role': 'VENDOR', 'phone_number': f'99999000{letter}'}
        )
        vendor, _ = VendorProfile.objects.get_or_create(
            user=user, defaults={'owner_name': f'Vendor {letter}', 'status': VendorStatus.APPROVED}
        )
        store, _ = BusinessProfile.objects.get_or_create(
            vendor=vendor,
            defaults={
                'business_name': f'Store {letter}',
                'status': status,
                'latitude': lat,
                'longitude': lon,
                'address_line_1': f'{letter} Street'
            }
        )
        store.status = status
        store.latitude = lat
        store.longitude = lon
        store.save()
        
        if active_sub:
            VendorSubscription.objects.create(
                vendor=user,
                store=store,
                plan=plan,
                status='ACTIVE'
            )
        return store

    # CUSTOMER LOCATION: 17.0, 78.0
    # Store A: PUBLISHED, ACTIVE, Within 25KM
    store_a = create_store('A', StoreStatus.PUBLISHED, True, 17.0, 78.0)
    
    # Store B: PUBLISHED, EXPIRED, Within 25KM
    store_b = create_store('B', StoreStatus.PUBLISHED, False, 17.0, 78.0)
    
    # Store C: PENDING_APPROVAL, ACTIVE, Within 25KM
    store_c = create_store('C', StoreStatus.PENDING_APPROVAL, True, 17.0, 78.0)
    
    # Store D: REJECTED, ACTIVE, Within 25KM
    store_d = create_store('D', StoreStatus.REJECTED, True, 17.0, 78.0)
    
    # Store E: SUSPENDED, ACTIVE, Within 25KM
    store_e = create_store('E', StoreStatus.SUSPENDED, True, 17.0, 78.0)
    
    # Store F: PUBLISHED, ACTIVE, Outside 25KM (e.g. 18.0, 79.0 which is ~150km away)
    store_f = create_store('F', StoreStatus.PUBLISHED, True, 18.0, 79.0)

    # Store G: PUBLISHED, ACTIVE, Within 25KM, No valid location
    store_g = create_store('G', StoreStatus.PUBLISHED, True, None, None)

    # Fetch Discovery API
    response = client.get('/api/v1/stores/nearby/?latitude=17.0&longitude=78.0&radius_km=25')
    if response.status_code != 200:
        print_test(f"API Returned {response.status_code}", False)
        return
        
    data = response.json()
    if isinstance(data, list):
        results = data
    else:
        results = data.get('results', [])
        
    ids = [s['id'] for s in results]

    print_test("STORE A: VISIBLE", str(store_a.id) in ids)
    print_test("STORE B: NOT VISIBLE (Expired Sub)", str(store_b.id) not in ids)
    print_test("STORE C: NOT VISIBLE (Pending)", str(store_c.id) not in ids)
    print_test("STORE D: NOT VISIBLE (Rejected)", str(store_d.id) not in ids)
    print_test("STORE E: NOT VISIBLE (Suspended)", str(store_e.id) not in ids)
    print_test("STORE F: NOT VISIBLE (Outside 25 KM)", str(store_f.id) not in ids)
    print_test("STORE G: NOT VISIBLE (No Location)", str(store_g.id) not in ids)
    print_test("TOTAL ELIGIBLE STORES == 1", len(ids) == 1)

if __name__ == '__main__':
    run_tests()
