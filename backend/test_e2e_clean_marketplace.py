import uuid
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from apps.accounts.models import User, UserRole
from apps.categories.models import Category
from apps.subscriptions.models import ListingPlan

class CleanMarketplaceE2ETest(APITestCase):
    def setUp(self):
        # 1. Admin creates Categories and Listing Plan
        self.admin = User.objects.create_superuser(
            phone_number='+919999999999', 
            email='admin@herarea.com', 
            password='AdminPassword123'
        )
        self.category = Category.objects.create(name='Fashion', is_active=True, created_by=self.admin)
        self.plan = ListingPlan.objects.create(name='Pro Plan', price=999.00, duration_days=30, is_active=True)

    def test_end_to_end_flow(self):
        # 2. Vendor self-registers
        vendor_payload = {
            "owner_name": "Test Vendor",
            "email": "vendor@test.com",
            "phone_number": "+918888888888",
            "password": "VendorPassword123",
            "confirm_password": "VendorPassword123"
        }
        res = self.client.post(reverse('vendor-auth-register'), vendor_payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        
        # Vendor login
        login_res = self.client.post(reverse('auth-customer-login'), {
            "email": "vendor@test.com",
            "password": "VendorPassword123"
        }, format='json')
        token = login_res.data['access']
        self.client.credentials(HTTP_AUTHORIZATION='Bearer ' + token)
        
        # 3. Vendor creates Store
        store_payload = {
            "business_name": "Test Store",
            "address_line_1": "123 Street",
            "city": "Test City",
            "state": "Test State",
            "postal_code": "123456",
            "contact_email": "store@test.com",
            "contact_phone": "+918888888888",
            "area": "Test Area",
            "latitude": "12.9716",
            "longitude": "77.5946",
            "category": self.category.id
        }
        res = self.client.post(reverse('business-profile-me'), store_payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        store_id = res.data['id']
        
        # 4. Vendor Submits Store (Fails due to incomplete / no product / no subscription)
        submit_res = self.client.post(reverse('vendor-business-submit'))
        self.assertEqual(submit_res.status_code, status.HTTP_400_BAD_REQUEST)
        
        # Add Product
        product_payload = {
            "name": "Test Product",
            "description": "Test Desc",
            "price": "100.00",
            "is_available": True,
            "image_url": "http://example.com/image.jpg"
        }
        res = self.client.post(reverse('vendor-catalog-product-list'), product_payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        
        # 5. Dummy Payment
        initiate_res = self.client.post(reverse('payment-initiate'), {"plan_id": self.plan.id}, format='json')
        self.assertEqual(initiate_res.status_code, status.HTTP_201_CREATED)
        txn_id = initiate_res.data['transaction_id']
        
        verify_res = self.client.post(reverse('payment-verify'), {
            "transaction_id": txn_id,
            "action": "simulate_success"
        }, format='json')
        self.assertEqual(verify_res.status_code, status.HTTP_200_OK)
        
        # Add cover image (mock)
        from apps.business.models import BusinessProfile
        from django.core.files.uploadedfile import SimpleUploadedFile
        store = BusinessProfile.objects.get(id=store_id)
        store.cover_image = SimpleUploadedFile("cover.jpg", b"file_content", content_type="image/jpeg")
        store.save()

        # 6. Vendor submits Store application
        submit_res = self.client.post(reverse('vendor-business-submit'))
        self.assertEqual(submit_res.status_code, status.HTTP_200_OK)
        
        # Admin Login
        admin_login = self.client.post(reverse('auth-customer-login'), {
            "email": "admin@herarea.com",
            "password": "AdminPassword123"
        }, format='json')
        admin_token = admin_login.data['access']
        self.client.credentials(HTTP_AUTHORIZATION='Bearer ' + admin_token)
        
        # 7. Admin fetches Complete Application Dossier
        dossier_res = self.client.get(reverse('admin-store-dossier', args=[store_id]))
        self.assertEqual(dossier_res.status_code, status.HTTP_200_OK)
        self.assertIn('vendor', dossier_res.data)
        
        # 8. Admin Approves Store
        approve_res = self.client.post(reverse('admin-store-approve', args=[store_id]))
        self.assertEqual(approve_res.status_code, status.HTTP_200_OK)
        
        store.refresh_from_db()
        from apps.business.models import StoreStatus
        self.assertEqual(store.status, StoreStatus.PUBLISHED)
        
        # 9. Customer flow
        self.client.credentials()
        from apps.accounts.models import UserRole
        cust_user = User.objects.create_user(
            phone_number="+917777777777",
            email="cust@test.com",
            password="CustPassword123",
            full_name="Test Customer",
            role=UserRole.CUSTOMER
        )
        
        cust_login = self.client.post(reverse('auth-customer-login'), {
            "email": "cust@test.com",
            "password": "CustPassword123"
        }, format='json')
        cust_token = cust_login.data['access']
        self.client.credentials(HTTP_AUTHORIZATION='Bearer ' + cust_token)
        
        # Customer discovers store
        nearby_res = self.client.get(reverse('public-store-nearby') + f"?latitude=12.9716&longitude=77.5946")
        self.assertEqual(nearby_res.status_code, status.HTTP_200_OK)
        self.assertIsInstance(nearby_res.data, list)
