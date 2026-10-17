from decimal import Decimal
from datetime import timedelta
from django.utils import timezone
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from apps.accounts.models import User, UserRole
from apps.vendors.models import VendorProfile, VendorStatus
from apps.business.models import BusinessProfile, StoreStatus
from apps.catalog.models import Product, StockStatus, Story, StoryType, StoryStatus
from apps.subscriptions.models import ListingPlan, VendorSubscription


class StoriesFeatureTests(APITestCase):
    def setUp(self):
        # 1. Create Vendor 1
        self.vendor_user_1 = User.objects.create_user(
            email='vendor1@herarea.com',
            phone_number='+919876543210',
            role=UserRole.VENDOR,
            password='TestPassword123!'
        )
        self.vendor_profile_1 = VendorProfile.objects.create(
            user=self.vendor_user_1,
            owner_name='Aaradhya Boutique Owner',
            official_email='vendor1@herarea.com',
            phone_number='+919876543210',
            status=VendorStatus.APPROVED
        )
        self.store_1 = BusinessProfile.objects.create(
            vendor=self.vendor_profile_1,
            business_name='Aaradhya Bridal Couture',
            description='Handloom Kanjeevarams and bespoke zardosi blouses',
            city='Hyderabad',
            area='Banjara Hills',
            postal_code='500034',
            contact_email='contact@aaradhya.com',
            contact_phone='+919876543210',
            status=StoreStatus.PUBLISHED
        )

        # Active Subscription for Store 1
        self.plan = ListingPlan.objects.create(
            name='Luxury Boutique Plan',
            price=Decimal('4999.00'),
            duration_days=30,
            is_active=True,
            customer_chat=True
        )
        self.sub_1 = VendorSubscription.objects.create(
            vendor=self.vendor_user_1,
            store=self.store_1,
            plan=self.plan,
            status='ACTIVE'
        )

        # Products for Store 1
        self.product_1 = Product.objects.create(
            business_profile=self.store_1,
            name='Royal Crimson Kanjeevaram Saree',
            description='Pure mulberry silk woven with real gold zari',
            price=Decimal('45000.00'),
            discounted_price=Decimal('39999.00'),
            image_url='https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800',
            stock_status=StockStatus.IN_STOCK,
            is_active=True,
            status='APPROVED'
        )

        # 2. Create Vendor 2 (competitor)
        self.vendor_user_2 = User.objects.create_user(
            email='vendor2@herarea.com',
            phone_number='+919876543211',
            role=UserRole.VENDOR,
            password='TestPassword123!'
        )
        self.vendor_profile_2 = VendorProfile.objects.create(
            user=self.vendor_user_2,
            owner_name='Meera Silks Owner',
            official_email='vendor2@herarea.com',
            phone_number='+919876543211',
            status=VendorStatus.APPROVED
        )
        self.store_2 = BusinessProfile.objects.create(
            vendor=self.vendor_profile_2,
            business_name='Meera Heritage Silks',
            description='Traditional silks',
            city='Hyderabad',
            area='Jubilee Hills',
            postal_code='500033',
            contact_email='contact@meera.com',
            contact_phone='+919876543211',
            status=StoreStatus.PUBLISHED
        )
        self.sub_2 = VendorSubscription.objects.create(
            vendor=self.vendor_user_2,
            store=self.store_2,
            plan=self.plan,
            status='ACTIVE'
        )
        self.product_2 = Product.objects.create(
            business_profile=self.store_2,
            name='Emerald Organza Lehanga',
            description='Hand embroidered silk organza',
            price=Decimal('35000.00'),
            image_url='https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800',
            stock_status=StockStatus.IN_STOCK,
            is_active=True,
            status='APPROVED'
        )

        # Customer User
        self.customer_user = User.objects.create_user(
            email='customer@herarea.com',
            phone_number='+919876543212',
            role=UserRole.CUSTOMER,
            password='TestPassword123!'
        )

        self.vendor_stories_url = reverse('vendor-catalog-story-list')
        self.public_stories_url = reverse('public-story-list')

    # Test 1: Product-linked Story creation & correct product linkage
    def test_product_linked_story_creation(self):
        self.client.force_authenticate(user=self.vendor_user_1)
        payload = {
            'story_type': 'product_linked',
            'product_id': str(self.product_1.id)
        }
        res = self.client.post(self.vendor_stories_url, data=payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['story_type'], 'product_linked')
        self.assertEqual(res.data['product_id'], str(self.product_1.id))
        self.assertEqual(res.data['title'], self.product_1.name)
        self.assertEqual(Decimal(str(res.data['price'])), self.product_1.price)
        self.assertEqual(Decimal(str(res.data['promotional_price'])), self.product_1.discounted_price)
        self.assertTrue(res.data['is_product_available'])
        self.assertIsNotNone(res.data['product'])
        self.assertEqual(res.data['product']['id'], str(self.product_1.id))

    # Test 2: Product-linked Story cannot reference another vendor's product
    def test_product_linked_story_rejects_other_vendor_product(self):
        self.client.force_authenticate(user=self.vendor_user_1)
        payload = {
            'story_type': 'product_linked',
            'product_id': str(self.product_2.id)  # Belongs to store_2
        }
        res = self.client.post(self.vendor_stories_url, data=payload, format='json')
        has_err = 'product_id' in res.data or ('details' in res.data and 'product_id' in res.data['details'])
        self.assertTrue(has_err)


    # Test 3: Gallery Story creation does not create or link a product record
    def test_gallery_story_creation_no_product(self):
        self.client.force_authenticate(user=self.vendor_user_1)
        initial_product_count = Product.objects.count()
        payload = {
            'story_type': 'gallery_uploaded',
            'media_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
            'title': 'Behind the Scenes: Loom Weaving',
            'caption': 'Witness our master weavers crafting silver zari borders in Kanchipuram.',
            'price': '12500.00'
        }
        res = self.client.post(self.vendor_stories_url, data=payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['story_type'], 'gallery_uploaded')
        # Product record must NOT be created
        self.assertEqual(Product.objects.count(), initial_product_count)
        # product_id and product must be null
        self.assertIsNone(res.data['product_id'])
        self.assertIsNone(res.data['product'])
        self.assertFalse(res.data['is_product_available'])

    # Test 4: Invalid prices (negative and promotional > regular) are rejected
    def test_invalid_prices_rejected(self):
        self.client.force_authenticate(user=self.vendor_user_1)
        # Negative price
        res1 = self.client.post(self.vendor_stories_url, data={
            'story_type': 'gallery_uploaded',
            'media_url': 'https://example.com/img.jpg',
            'price': '-100.00'
        }, format='json')
        self.assertEqual(res1.status_code, status.HTTP_400_BAD_REQUEST)

        # Promotional price > regular price
        res2 = self.client.post(self.vendor_stories_url, data={
            'story_type': 'gallery_uploaded',
            'media_url': 'https://example.com/img.jpg',
            'price': '1000.00',
            'promotional_price': '1500.00'
        }, format='json')
        self.assertEqual(res2.status_code, status.HTTP_400_BAD_REQUEST)

    # Test 5: 25-active-Story limit enforced
    def test_active_story_cap_enforced(self):
        self.client.force_authenticate(user=self.vendor_user_1)
        # Create 25 active stories
        now = timezone.now()
        for i in range(25):
            Story.objects.create(
                business_profile=self.store_1,
                story_type=StoryType.GALLERY_UPLOADED,
                media_url=f'https://example.com/img_{i}.jpg',
                published_at=now,
                expires_at=now + timedelta(hours=24),
                status=StoryStatus.ACTIVE,
                is_active=True
            )

        # Attempt to create the 26th story
        res = self.client.post(self.vendor_stories_url, data={
            'story_type': 'gallery_uploaded',
            'media_url': 'https://example.com/overflow.jpg',
            'title': '26th Story'
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('25', str(res.data))

    # Test 6: 24-hour expiration behavior
    def test_expired_stories_do_not_count_toward_active_cap_or_appear_publicly(self):
        now = timezone.now()
        # Create 25 expired stories
        for i in range(25):
            Story.objects.create(
                business_profile=self.store_1,
                story_type=StoryType.GALLERY_UPLOADED,
                media_url=f'https://example.com/expired_{i}.jpg',
                published_at=now - timedelta(hours=25),
                expires_at=now - timedelta(hours=1),
                status=StoryStatus.ACTIVE,
                is_active=True
            )

        # Creating a new story should succeed because older stories are expired
        self.client.force_authenticate(user=self.vendor_user_1)
        res = self.client.post(self.vendor_stories_url, data={
            'story_type': 'gallery_uploaded',
            'media_url': 'https://example.com/fresh.jpg',
            'title': 'Fresh Active Story'
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        # Public list should ONLY contain the 1 fresh active story, none of the 25 expired stories
        self.client.force_authenticate(user=None)
        pub_res = self.client.get(self.public_stories_url)
        self.assertEqual(pub_res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(pub_res.data), 1)
        self.assertEqual(pub_res.data[0]['title'], 'Fresh Active Story')

    # Test 7: Deleting a story removes it from active list immediately
    def test_delete_story_removes_from_active_list(self):
        story = Story.objects.create(
            business_profile=self.store_1,
            story_type=StoryType.PRODUCT_LINKED,
            product=self.product_1,
            media_url=self.product_1.image_url,
            title=self.product_1.name
        )
        self.client.force_authenticate(user=self.vendor_user_1)
        delete_url = reverse('vendor-catalog-story-detail', kwargs={'pk': story.id})
        res = self.client.delete(delete_url)
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)

        # Verify story is no longer returned in public list
        pub_res = self.client.get(self.public_stories_url)
        self.assertEqual(len(pub_res.data), 0)

    # Test 8: Unauthorized upload rejection (unapproved vendor / inactive subscription)
    def test_unauthorized_upload_rejected(self):
        # Vendor with no active subscription
        self.sub_1.status = 'EXPIRED'
        self.sub_1.save()

        self.client.force_authenticate(user=self.vendor_user_1)
        res = self.client.post(self.vendor_stories_url, data={
            'story_type': 'gallery_uploaded',
            'media_url': 'https://example.com/pic.jpg'
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    # Test 9: Graceful handling of deleted or unavailable products
    def test_deleted_or_unavailable_product_handling(self):
        story = Story.objects.create(
            business_profile=self.store_1,
            story_type=StoryType.PRODUCT_LINKED,
            product=self.product_1,
            media_url=self.product_1.image_url,
            title=self.product_1.name
        )

        # Simulate product soft deletion or status change to OUT_OF_STOCK / unapproved
        self.product_1.stock_status = StockStatus.OUT_OF_STOCK
        self.product_1.save()

        res = self.client.get(self.public_stories_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        story_data = res.data[0]
        self.assertEqual(story_data['story_type'], 'product_linked')
        self.assertEqual(story_data['product_id'], str(self.product_1.id))
        # is_product_available should be FALSE
        self.assertFalse(story_data['is_product_available'])
        self.assertFalse(story_data['product']['is_available'])

        # Now simulate product hard deletion
        self.product_1.delete()
        res2 = self.client.get(self.public_stories_url)
        self.assertEqual(res2.status_code, status.HTTP_200_OK)
        story_data_2 = res2.data[0]
        self.assertFalse(story_data_2['is_product_available'])
        self.assertIsNone(story_data_2['product_id'])
        self.assertIsNone(story_data_2['product'])

    # Test 10: Existing product detail endpoint handles unavailable products gracefully (404)
    def test_public_product_detail_graceful_404(self):
        product_detail_url = reverse('public-product-detail', kwargs={'pk': self.product_1.id})
        res = self.client.get(product_detail_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # Deactivate / remove product
        self.product_1.is_active = False
        self.product_1.save()

        res_404 = self.client.get(product_detail_url)
        self.assertEqual(res_404.status_code, status.HTTP_404_NOT_FOUND)
