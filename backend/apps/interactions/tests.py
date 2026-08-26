from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from apps.accounts.models import User, UserRole
from apps.catalog.models import StockStatus, CatalogItemType
from apps.notifications.models import Notification, NotificationType

class CustomerInteractionsAndO2OSearchTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.vendor_user = User.objects.create_user(phone_number="+919777777701", role=UserRole.VENDOR)
        self.admin_user = User.objects.create_superuser(phone_number="+919777777799", role=UserRole.ADMIN)
        self.customer1 = User.objects.create_user(phone_number="+919888888801", role=UserRole.CUSTOMER)
        self.customer2 = User.objects.create_user(phone_number="+919888888802", role=UserRole.CUSTOMER)

        # Onboard & Approve Vendor
        self.client.force_authenticate(user=self.vendor_user)
        onboarding_data = {
            "owner_name": "Aanya Verma",
            "official_email": "aanya@wellness.in",
            "phone_number": "+919777777701",
            "business_name": "Aanya Luxe Spa & Couture",
            "description": "Exclusive bridal wellness therapies, facial consultations, and bespoke lehengas.",
            "address_line_1": "Indiranagar 100 Feet Road",
            "city": "Bengaluru",
            "state": "Karnataka",
            "postal_code": "560038",
            "contact_email": "booking@aanya.in",
            "contact_phone": "+919900000001"
        }
        reg_resp = self.client.post(reverse('vendor-onboarding-register'), onboarding_data, format='json')
        self.vendor_id = reg_resp.data['id']
        self.store_id = reg_resp.data['business_profile']['id']

        # Admin Approval
        self.client.force_authenticate(user=self.admin_user)
        self.client.post(reverse('admin-vendor-approve', kwargs={'pk': self.vendor_id}))

        # Vendor creates both a PRODUCT and a SERVICE in Catalog
        self.client.force_authenticate(user=self.vendor_user)
        prod_url = reverse('vendor-catalog-product-list')
        
        # 1. Product creation
        resp_prod = self.client.post(prod_url, {
            "name": "Bespoke Silk Bridal Saree",
            "description": "Authentic Kanjivaram bridal saree with gold zari weaving.",
            "price": "125000.00",
            "item_type": CatalogItemType.PRODUCT,
            "stock_status": StockStatus.IN_STOCK,
            "image_url": "https://storage.herarea.internal/saree.jpg"
        }, format='json')
        self.product_id = resp_prod.data['id']

        # 2. Service consultation creation (Coexisting seamlessly!)
        resp_srv = self.client.post(prod_url, {
            "name": "Bridal Styling & Jewelry Trial Consultation",
            "description": "1-on-1 personalized styling session and bespoke fitting appointment.",
            "price": "5000.00",
            "item_type": CatalogItemType.SERVICE,
            "service_duration_minutes": 90,
            "stock_status": StockStatus.IN_STOCK,
            "image_url": "https://storage.herarea.internal/consult.jpg"
        }, format='json')
        self.service_id = resp_srv.data['id']

    def test_extensible_catalog_service_coexistence_and_unified_o2o_search(self):
        """
        Verify that physical Products and bespoke Services coexist seamlessly in the database and APIs,
        and that our Unified Global O2O Search cleanly groups Matching Stores, Products, and Services!
        """
        self.client.logout()
        search_url = reverse('global-o2o-search')
        
        # Keyword search matching store name, product, and service
        resp = self.client.get(search_url, {"q": "Bridal"})
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        
        self.assertEqual(len(resp.data['matching_stores']), 1)
        self.assertEqual(resp.data['matching_stores'][0]['business_name'], "Aanya Luxe Spa & Couture")

        self.assertEqual(len(resp.data['matching_products']), 1)
        self.assertEqual(resp.data['matching_products'][0]['name'], "Bespoke Silk Bridal Saree")
        self.assertEqual(resp.data['matching_products'][0]['item_type'], "PRODUCT")

        self.assertEqual(len(resp.data['matching_services']), 1)
        self.assertEqual(resp.data['matching_services'][0]['name'], "Bridal Styling & Jewelry Trial Consultation")
        self.assertEqual(resp.data['matching_services'][0]['item_type'], "SERVICE")
        self.assertEqual(resp.data['matching_services'][0]['service_duration_minutes'], 90)

    def test_customer_wishlist_favorite_toggling_for_stores_and_items(self):
        """
        Verify single-call favorite bookmark toggling for both showrooms and catalog items.
        """
        self.client.force_authenticate(user=self.customer1)
        toggle_url = reverse('favorite-toggle')

        # 1. Bookmark Store Showroom
        add_store_resp = self.client.post(toggle_url, {"store": str(self.store_id)}, format='json')
        self.assertEqual(add_store_resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(add_store_resp.data['status'], "added")
        self.assertTrue(add_store_resp.data['bookmarked'])

        # 2. Re-submitting exact same call should cleanly remove bookmark!
        remove_store_resp = self.client.post(toggle_url, {"store": str(self.store_id)}, format='json')
        self.assertEqual(remove_store_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(remove_store_resp.data['status'], "removed")
        self.assertFalse(remove_store_resp.data['bookmarked'])

        # 3. Bookmark Service Item and check Wishlist list
        self.client.post(toggle_url, {"product": str(self.service_id)}, format='json')
        list_resp = self.client.get(reverse('favorite-list'))
        self.assertEqual(len(list_resp.data), 1)
        self.assertEqual(list_resp.data[0]['product_details']['name'], "Bridal Styling & Jewelry Trial Consultation")

    def test_showroom_reviews_dynamic_rating_aggregation_and_vendor_notifying(self):
        """
        Verify customers can submit verified 1-5 star showroom ratings, confirm real-time average score 
        computations, and verify instant NotificationEngine dispatch to the studio owner!
        """
        review_url = reverse('store-review-list-create', kwargs={'store_id': self.store_id})
        
        # 1. Customer 1 submits a flawless 5-star review
        self.client.force_authenticate(user=self.customer1)
        r1_resp = self.client.post(review_url, {
            "rating": 5,
            "title": "Exquisite Bridal Fitting!",
            "comment": "The consultation with Aanya was transformative. Flawless craftsmanship."
        }, format='json')
        self.assertEqual(r1_resp.status_code, status.HTTP_201_CREATED)

        # 2. Customer 2 submits a 4-star review
        self.client.force_authenticate(user=self.customer2)
        r2_resp = self.client.post(review_url, {
            "rating": 4,
            "title": "Very elegant fabrics",
            "comment": "Lovely ambiance and prompt customer service."
        }, format='json')
        self.assertEqual(r2_resp.status_code, status.HTTP_201_CREATED)

        # 3. Public query of showroom reviews verifies dynamic average rating calculation ( (5 + 4) / 2 = 4.5 )
        self.client.logout()
        get_resp = self.client.get(review_url)
        self.assertEqual(get_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(get_resp.data['review_count'], 2)
        self.assertEqual(get_resp.data['average_rating'], 4.5)

        # 4. Verify Vendor received real-time review notification alerts via NotificationEngine
        vendor_notif_count = Notification.objects.filter(
            recipient=self.vendor_user, 
            notification_type=NotificationType.REVIEW
        ).count()
        self.assertEqual(vendor_notif_count, 2)
