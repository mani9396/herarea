from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from apps.accounts.models import User, UserRole
from apps.vendors.models import VendorProfile, VendorStatus
from apps.categories.models import Category
from apps.catalog.models import StockStatus

class CatalogAndShowroomDiscoveryTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        
        # Actors
        self.vendor_user = User.objects.create_user(phone_number="+919333333301", role=UserRole.VENDOR, email="couture@herarea.in")
        self.admin_user = User.objects.create_superuser(phone_number="+919444444401", role=UserRole.ADMIN)
        self.customer_user = User.objects.create_user(phone_number="+919555555501", role=UserRole.CUSTOMER)

        # Taxonomy Category
        self.category = Category.objects.create(name="Luxury Jewelry", slug="luxury-jewelry", is_active=True)

        # Vendor Onboarding Registration (Status starts as PENDING)
        self.client.force_authenticate(user=self.vendor_user)
        onboarding_data = {
            "owner_name": "Meera Nandan",
            "official_email": "meera@jewel.in",
            "phone_number": "+919333333301",
            "business_name": "Royal Heritage Jewels",
            "description": "Handcrafted Kundan and Polki bridal necklaces.",
            "address_line_1": "Plot 45, Jubilee Hills Main Road",
            "city": "Hyderabad",
            "state": "Telangana",
            "pincode": "500033",
            "contact_email": "concierge@royaljewels.in",
            "contact_phone": "+919888800001"
        }
        self.reg_resp = self.client.post(reverse('vendor-onboarding-register'), onboarding_data, format='json')
        self.vendor_id = self.reg_resp.data['id']
        self.store_id = self.reg_resp.data['business_profile']['id']

        # URLs
        self.vendor_products_url = reverse('vendor-catalog-product-list')
        self.vendor_gallery_url = reverse('vendor-catalog-gallery-list')
        self.vendor_offers_url = reverse('vendor-catalog-offer-list')
        self.public_stores_url = reverse('public-store-list')
        self.public_products_url = reverse('public-product-list')
        self.store_dossier_url = reverse('public-store-catalog-dossier', kwargs={'store_id': self.store_id})

    def test_unapproved_vendor_strictly_blocked_from_all_catalog_endpoints(self):
        """
        Verify core marketplace approval gate:
        An unapproved (PENDING) vendor attempting to create products, gallery images, 
        or offers is immediately rejected with 403 Forbidden.
        """
        self.client.force_authenticate(user=self.vendor_user)
        
        prod_payload = {
            "category": str(self.category.id),
            "name": "Maharaja Emerald Kundan Choker",
            "description": "Authentic 22-carat gold Kundan necklace set with Zambian emeralds.",
            "price": "245000.00",
            "stock_status": StockStatus.MADE_TO_ORDER,
            "image_url": "https://storage.herarea.internal/catalog/choker1.jpg"
        }
        resp_prod = self.client.post(self.vendor_products_url, prod_payload, format='json')
        self.assertEqual(resp_prod.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn("Only APPROVED partner studios can manage", str(resp_prod.data['message']))

        resp_gal = self.client.post(self.vendor_gallery_url, {"image_url": "https://img.jpg"}, format='json')
        self.assertEqual(resp_gal.status_code, status.HTTP_403_FORBIDDEN)

        resp_off = self.client.post(self.vendor_offers_url, {"title": "Monsoon Deal", "description": "10% off"}, format='json')
        self.assertEqual(resp_off.status_code, status.HTTP_403_FORBIDDEN)

        # Furthermore, unapproved store showroom must NOT appear in public discovery lists!
        self.client.logout()
        self.assertEqual(len(self.client.get(self.public_stores_url).data), 0)
        self.assertEqual(self.client.get(self.store_dossier_url).status_code, status.HTTP_404_NOT_FOUND)

    def test_approved_vendor_catalog_management_and_public_customer_o2o_discovery(self):
        """
        Verify that upon executive Admin approval, the studio can publish products, gallery imagery, 
        and offers, and customers can discover them via faceted searching and dossier calls.
        """
        # Step 1: Admin executes marketplace approval
        self.client.force_authenticate(user=self.admin_user)
        approve_url = reverse('admin-vendor-approve', kwargs={'pk': self.vendor_id})
        self.assertEqual(self.client.post(approve_url).status_code, status.HTTP_200_OK)

        # Step 2: Approved Vendor publishes catalog products, gallery imagery & promotions
        self.client.force_authenticate(user=self.vendor_user)

        # Bind category to showroom profile
        self.client.put(reverse('business-profile-me'), {"category": str(self.category.id)}, format='json')

        prod_payload = {
            "category": str(self.category.id),
            "name": "Royal Polki Bridal Set",
            "description": "Bespoke polki diamond bridal necklace with earrings.",
            "price": "350000.00",
            "discounted_price": "320000.00",
            "stock_status": StockStatus.IN_STOCK,
            "image_url": "https://storage.herarea.internal/catalog/polki_set.jpg",
            "is_featured": True
        }
        prod_resp = self.client.post(self.vendor_products_url, prod_payload, format='json')
        self.assertEqual(prod_resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(prod_resp.data['store_name'], "Royal Heritage Jewels")
        self.assertEqual(prod_resp.data['store_city'], "Hyderabad")

        gal_resp = self.client.post(self.vendor_gallery_url, {"image_url": "https://storage.herarea.internal/gallery/ambiance.jpg", "caption": "VIP Bridal Lounge"}, format='json')
        self.assertEqual(gal_resp.status_code, status.HTTP_201_CREATED)

        offer_resp = self.client.post(self.vendor_offers_url, {"title": "Festive Bridal Privilege", "promo_code": "HERAREA15", "description": "15% off on making charges."}, format='json')
        self.assertEqual(offer_resp.status_code, status.HTTP_201_CREATED)

        # Step 3: Customer App user executes O2O discovery
        self.client.force_authenticate(user=self.customer_user)
        
        # Verify store showroom appears in public list with city filtering
        stores_resp = self.client.get(self.public_stores_url, {"city": "Hyderabad"})
        self.assertEqual(stores_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(stores_resp.data), 1)
        self.assertEqual(stores_resp.data[0]['business_name'], "Royal Heritage Jewels")

        # Verify global product search by keyword & category
        prod_search_resp = self.client.get(self.public_products_url, {"search": "Polki", "featured": "true"})
        self.assertEqual(prod_search_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(prod_search_resp.data), 1)
        self.assertEqual(prod_search_resp.data[0]['price'], "350000.00")
        self.assertEqual(prod_search_resp.data[0]['discounted_price'], "320000.00")

        # Verify Store Complete Catalog Dossier (Single-call aggregation for Store Details screen)
        dossier_resp = self.client.get(self.store_dossier_url)
        self.assertEqual(dossier_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(dossier_resp.data['products']), 1)
        self.assertEqual(len(dossier_resp.data['gallery']), 1)
        self.assertEqual(len(dossier_resp.data['offers']), 1)
        self.assertEqual(dossier_resp.data['offers'][0]['promo_code'], "HERAREA15")


from django.utils import timezone
import datetime
from apps.catalog.models import Promotion, PromotionType, PromotionStatus, InternalDestinationType

class PromotionBannersTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin_user = User.objects.create_superuser(phone_number="+919444444499", role=UserRole.ADMIN)
        self.customer_user = User.objects.create_user(phone_number="+919555555599", role=UserRole.CUSTOMER)
        self.vendor_user = User.objects.create_user(phone_number="+919333333399", role=UserRole.VENDOR)
        
        self.category = Category.objects.create(name="Promo Category", slug="promo-cat", is_active=True)
        
        self.admin_list_url = reverse('admin-banner-list')
        self.public_list_url = reverse('public-banner-list')
        
        self.now = timezone.now()
        self.tomorrow = self.now + datetime.timedelta(days=1)
        self.yesterday = self.now - datetime.timedelta(days=1)
        self.next_week = self.now + datetime.timedelta(days=7)

    def test_admin_can_create_app_promotion(self):
        self.client.force_authenticate(user=self.admin_user)
        payload = {
            "title": "App Promo",
            "image_url": "https://img.com/a.jpg",
            "promotion_type": PromotionType.APP,
            "internal_destination_type": InternalDestinationType.CATEGORY,
            "internal_destination_id": str(self.category.id),
            "start_at": self.yesterday,
            "end_at": self.tomorrow,
            "priority": 1
        }
        resp = self.client.post(self.admin_list_url, payload, format='json')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['title'], "App Promo")
        
    def test_admin_can_create_external_promotion(self):
        self.client.force_authenticate(user=self.admin_user)
        payload = {
            "title": "Ext Promo",
            "image_url": "https://img.com/b.jpg",
            "promotion_type": PromotionType.EXTERNAL,
            "external_url": "https://external.com",
            "start_at": self.yesterday,
            "end_at": self.tomorrow,
            "priority": 2
        }
        resp = self.client.post(self.admin_list_url, payload, format='json')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

    def test_non_admin_cannot_create_promotion(self):
        self.client.force_authenticate(user=self.customer_user)
        resp = self.client.post(self.admin_list_url, {"title": "X"}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)
        
        self.client.force_authenticate(user=self.vendor_user)
        resp2 = self.client.post(self.admin_list_url, {"title": "X"}, format='json')
        self.assertEqual(resp2.status_code, status.HTTP_403_FORBIDDEN)

    def test_invalid_external_url_rejected(self):
        self.client.force_authenticate(user=self.admin_user)
        payload = {
            "title": "Ext Promo",
            "image_url": "https://img.com/b.jpg",
            "promotion_type": PromotionType.EXTERNAL,
            "external_url": "not-a-url",
            "start_at": self.yesterday,
            "end_at": self.tomorrow
        }
        resp = self.client.post(self.admin_list_url, payload, format='json')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("external_url", resp.data)

    def test_missing_external_url_rejected(self):
        self.client.force_authenticate(user=self.admin_user)
        payload = {
            "title": "Ext Promo",
            "image_url": "https://img.com/b.jpg",
            "promotion_type": PromotionType.EXTERNAL,
            "start_at": self.yesterday,
            "end_at": self.tomorrow
        }
        resp = self.client.post(self.admin_list_url, payload, format='json')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_invalid_internal_destination_rejected(self):
        self.client.force_authenticate(user=self.admin_user)
        import uuid
        payload = {
            "title": "App Promo",
            "image_url": "https://img.com/a.jpg",
            "promotion_type": PromotionType.APP,
            "internal_destination_type": InternalDestinationType.CATEGORY,
            "internal_destination_id": str(uuid.uuid4()), # non-existent
            "start_at": self.yesterday,
            "end_at": self.tomorrow
        }
        resp = self.client.post(self.admin_list_url, payload, format='json')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_end_at_before_start_at_rejected(self):
        self.client.force_authenticate(user=self.admin_user)
        payload = {
            "title": "Ext Promo",
            "image_url": "https://img.com/b.jpg",
            "promotion_type": PromotionType.EXTERNAL,
            "external_url": "https://google.com",
            "start_at": self.tomorrow,
            "end_at": self.yesterday
        }
        resp = self.client.post(self.admin_list_url, payload, format='json')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_public_api_displays_only_active_promotions(self):
        # Create active
        Promotion.objects.create(title="Active", image_url="https://a", promotion_type="EXTERNAL", external_url="https://a", start_at=self.yesterday, end_at=self.tomorrow, status=PromotionStatus.ACTIVE)
        # Create scheduled
        Promotion.objects.create(title="Scheduled", image_url="https://a", promotion_type="EXTERNAL", external_url="https://a", start_at=self.tomorrow, end_at=self.next_week, status=PromotionStatus.SCHEDULED)
        # Create expired
        Promotion.objects.create(title="Expired", image_url="https://a", promotion_type="EXTERNAL", external_url="https://a", start_at=self.yesterday - datetime.timedelta(days=5), end_at=self.yesterday, status=PromotionStatus.ACTIVE)
        # Create suspended
        Promotion.objects.create(title="Suspended", image_url="https://a", promotion_type="EXTERNAL", external_url="https://a", start_at=self.yesterday, end_at=self.tomorrow, status=PromotionStatus.SUSPENDED)
        
        resp = self.client.get(self.public_list_url)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data), 1)
        self.assertEqual(resp.data[0]['title'], "Active")
        self.assertNotIn('created_at', resp.data[0]) # test public api doesn't expose admin fields

    def test_suspend_and_resume_promotion(self):
        self.client.force_authenticate(user=self.admin_user)
        p = Promotion.objects.create(title="Active", image_url="https://a", promotion_type="EXTERNAL", external_url="https://a", start_at=self.yesterday, end_at=self.tomorrow, status=PromotionStatus.ACTIVE)
        
        suspend_url = reverse('admin-banner-action', kwargs={'pk': p.id, 'action': 'suspend'})
        resp = self.client.post(suspend_url)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        p.refresh_from_db()
        self.assertEqual(p.status, PromotionStatus.SUSPENDED)
        
        # Verify it disappeared from public API
        resp_pub = self.client.get(self.public_list_url)
        self.assertEqual(len(resp_pub.data), 0)
        
        resume_url = reverse('admin-banner-action', kwargs={'pk': p.id, 'action': 'resume'})
        resp2 = self.client.post(resume_url)
        self.assertEqual(resp2.status_code, status.HTTP_200_OK)
        p.refresh_from_db()
        self.assertEqual(p.status, PromotionStatus.ACTIVE)

    def test_priority_ordering(self):
        Promotion.objects.create(title="P3", image_url="https://a", promotion_type="EXTERNAL", external_url="https://a", start_at=self.yesterday, end_at=self.tomorrow, status=PromotionStatus.ACTIVE, priority=3)
        Promotion.objects.create(title="P1", image_url="https://a", promotion_type="EXTERNAL", external_url="https://a", start_at=self.yesterday, end_at=self.tomorrow, status=PromotionStatus.ACTIVE, priority=1)
        Promotion.objects.create(title="P2", image_url="https://a", promotion_type="EXTERNAL", external_url="https://a", start_at=self.yesterday, end_at=self.tomorrow, status=PromotionStatus.ACTIVE, priority=2)
        
        resp = self.client.get(self.public_list_url)
        self.assertEqual(len(resp.data), 3)
        self.assertEqual(resp.data[0]['title'], "P1")
        self.assertEqual(resp.data[1]['title'], "P2")
        self.assertEqual(resp.data[2]['title'], "P3")
