import os
import django
import math
from datetime import timedelta
from django.utils import timezone

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.accounts.models import User, UserRole
from apps.business.models import BusinessProfile, StoreStatus
from apps.vendors.models import VendorProfile, VendorStatus
from apps.subscriptions.models import VendorSubscription, ListingPlan
from apps.categories.models import Category
from apps.interactions.models import StoreVisit, Review, StoreVisitStatus, ReviewStatus
from rest_framework.test import APIClient

def haversine(lat1, lon1, lat2, lon2):
    R = 6371.0 # km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def run_tests():
    print("============================================================")
    print("PHASE 8 AUTOMATED DISCOVERY & REVIEW TEST SUITE")
    print("============================================================")

    import uuid
    run_id = str(uuid.uuid4())[:6]

    def get_or_create_user(phone, email, role):
        try:
            return User.objects.get(phone_number=phone)
        except User.DoesNotExist:
            return User.objects.create_user(
                phone_number=phone,
                email=email,
                password='password123',
                role=role
            )

    admin_user = get_or_create_user(f'+919900{run_id}', f'admin_{run_id}@test.com', UserRole.ADMIN)
    admin_client = APIClient()
    admin_client.force_authenticate(user=admin_user)

    vendor_user = get_or_create_user(f'+919911{run_id}', f'vendor_{run_id}@test.com', UserRole.VENDOR)
    vendor_profile, _ = VendorProfile.objects.get_or_create(user=vendor_user, defaults={'status': VendorStatus.APPROVED})
    
    category, _ = Category.objects.get_or_create(name='Phase 8 Category', slug='phase8-cat')
    
    store, _ = BusinessProfile.objects.get_or_create(
        vendor=vendor_profile,
        defaults={
            'business_name': 'Phase 8 Store',
            'category': category,
            'status': StoreStatus.PUBLISHED,
            'latitude': 17.4326,
            'longitude': 78.4071,
            'address_line_1': 'Jubilee Hills',
        }
    )

    plan, _ = ListingPlan.objects.get_or_create(
        name='Phase 8 Plan',
        defaults={'price': 1000, 'duration_days': 30, 'is_active': True}
    )

    VendorSubscription.objects.create(
        vendor=vendor_user,
        store=store,
        plan=plan,
        status='ACTIVE'
    )

    customer_user = get_or_create_user(f'+919922{run_id}', f'customer1_{run_id}@test.com', UserRole.CUSTOMER)
    customer_client = APIClient()
    customer_client.force_authenticate(user=customer_user)

    customer2_user = get_or_create_user(f'+919933{run_id}', f'customer2_{run_id}@test.com', UserRole.CUSTOMER)
    customer2_client = APIClient()
    customer2_client.force_authenticate(user=customer2_user)

    # TEST 1: Customer opens Store. Cannot immediately submit review without verified visit.
    response = customer_client.post(f'/api/v1/stores/{store.id}/reviews/', {
        'rating': 5,
        'comment': 'Good store'
    })
    assert response.status_code == 400
    assert 'verified physical visit' in str(response.data)
    print("PASS: TEST 1 - Blocked review without visit")

    # TEST 2: Customer is outside visit-verification distance (101 meters away)
    # Latitude offset for ~150 meters
    offset_lat = 17.4326 + 0.0015
    response = customer_client.post(f'/api/v1/stores/{store.id}/visit/', {
        'latitude': offset_lat,
        'longitude': 78.4071
    })
    assert response.status_code == 400
    assert 'must be within 100.0m' in str(response.data)
    print("PASS: TEST 2 - Visit verification failed due to distance")

    # TEST 3: Customer is physically within verification distance
    response = customer_client.post(f'/api/v1/stores/{store.id}/visit/', {
        'latitude': 17.4326,
        'longitude': 78.4071
    })
    assert response.status_code == 201
    assert response.data['status'] == 'VERIFIED'
    print("PASS: TEST 3 - Visit VERIFIED")

    # TEST 4: Customer submits 5 stars
    response = customer_client.post(f'/api/v1/stores/{store.id}/reviews/', {
        'rating': 5,
        'title': 'Great',
        'comment': 'Excellent store.'
    })
    assert response.status_code == 201
    assert response.data['status'] == 'PENDING'
    review_id = response.data['id']
    print("PASS: TEST 4 - Review = PENDING")

    # TEST 10: Pending review exists. It does NOT affect public average rating.
    response = customer_client.get(f'/api/v1/stores/nearby/?latitude=17.4326&longitude=78.4071&radius_km=25')
    store_data = next((s for s in response.data if s['id'] == str(store.id)), None)
    assert store_data is not None
    assert store_data['rating'] == 0.0
    assert store_data['review_count'] == 0
    print("PASS: TEST 10 - Pending review does NOT affect public rating")

    # TEST 5: Admin approves. Review = APPROVED. Store rating becomes 5.0
    response = admin_client.patch(f'/api/v1/admin/reviews/{review_id}/', {
        'status': 'APPROVED'
    })
    assert response.status_code == 200

    response = customer_client.get(f'/api/v1/stores/nearby/?latitude=17.4326&longitude=78.4071&radius_km=25')
    store_data = next((s for s in response.data if s['id'] == str(store.id)), None)
    assert store_data['rating'] == 5.0
    assert store_data['review_count'] == 1
    print("PASS: TEST 5 - Admin APPROVED -> Rating 5.0")

    # TEST 6: Second Customer gives 4 stars
    customer2_client.post(f'/api/v1/stores/{store.id}/visit/', {
        'latitude': 17.4326,
        'longitude': 78.4071
    })
    response = customer2_client.post(f'/api/v1/stores/{store.id}/reviews/', {
        'rating': 4,
        'title': 'Good',
        'comment': 'Good.'
    })
    assert response.status_code == 201
    review2_id = response.data['id']
    
    admin_client.patch(f'/api/v1/admin/reviews/{review2_id}/', {
        'status': 'APPROVED'
    })

    response = customer_client.get(f'/api/v1/stores/nearby/?latitude=17.4326&longitude=78.4071&radius_km=25')
    store_data = next((s for s in response.data if s['id'] == str(store.id)), None)
    assert store_data['rating'] == 4.5
    assert store_data['review_count'] == 2
    print("PASS: TEST 6 - Second Review -> Rating 4.5")

    # TEST 7: Customer attempts another review for same Store. Blocked.
    response = customer_client.post(f'/api/v1/stores/{store.id}/reviews/', {
        'rating': 3,
        'comment': 'Another review'
    })
    assert response.status_code == 400
    assert 'already reviewed' in str(response.data)
    print("PASS: TEST 7 - Blocked duplicate review")

    # TEST 8 & 9: Customer attempts invalid rating (0 or 6)
    response = customer_client.patch(f'/api/v1/stores/customer/{review_id}/', {
        'rating': 0
    })
    assert response.status_code == 400
    
    response = customer_client.patch(f'/api/v1/stores/customer/{review_id}/', {
        'rating': 6
    })
    assert response.status_code == 400
    print("PASS: TEST 8 & 9 - Invalid ratings rejected")

    # TEST 11: Admin rejects review. It does NOT affect rating.
    admin_client.patch(f'/api/v1/admin/reviews/{review2_id}/', {
        'status': 'REJECTED'
    })
    response = customer_client.get(f'/api/v1/stores/nearby/?latitude=17.4326&longitude=78.4071&radius_km=25')
    store_data = next((s for s in response.data if s['id'] == str(store.id)), None)
    assert store_data['rating'] == 5.0
    assert store_data['review_count'] == 1
    print("PASS: TEST 11 - Rejected review removed from rating")

    # TEST 13: Vendor opens reviews. Sees only their own reviews.
    vendor_client = APIClient()
    vendor_client.force_authenticate(user=vendor_user)
    response = vendor_client.get(f'/api/v1/vendor/store/reviews/')
    assert response.status_code == 200
    assert len(response.data) == 2
    print("PASS: TEST 13 - Vendor sees own reviews")

    print("\nALL PHASE 8 TESTS PASSED SUCCESSFULLY!")

if __name__ == '__main__':
    run_tests()
