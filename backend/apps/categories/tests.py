from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from apps.accounts.models import User, UserRole
from apps.categories.models import Category

class CategoryTaxonomyTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.public_list_url = reverse('public-category-list')
        self.admin_list_url = reverse('admin-category-list')

        self.admin_user = User.objects.create_superuser(phone_number="+919000000088", role=UserRole.ADMIN, email="admin88@herarea.in")
        self.customer_user = User.objects.create_user(phone_number="+919000000089", role=UserRole.CUSTOMER)

    def test_admin_category_lifecycle_and_public_discovery_hierarchy(self):
        """
        Verify Admin can create parent and subcategories, auto-generate slugs, 
        and public discovery endpoints embed immediate active children cleanly.
        """
        self.client.force_authenticate(user=self.admin_user)

        # 1. Create Parent Category
        parent_payload = {
            "name": "Bespoke Bridal Couture",
            "description": "Exquisite handcrafted bridal lehengas and designer sarees.",
            "icon_url": "https://storage.herarea.internal/icons/bridal.svg",
            "display_order": 1,
            "is_active": True
        }
        parent_resp = self.client.post(self.admin_list_url, parent_payload, format='json')
        self.assertEqual(parent_resp.status_code, status.HTTP_201_CREATED)
        parent_id = parent_resp.data['id']
        self.assertEqual(parent_resp.data['slug'], "bespoke-bridal-couture")

        # 2. Create Subcategory
        child_payload = {
            "name": "Bridal Lehengas",
            "description": "Traditional and contemporary bridal lehenga ensembles.",
            "parent_category": parent_id,
            "display_order": 1,
            "is_active": True
        }
        child_resp = self.client.post(self.admin_list_url, child_payload, format='json')
        self.assertEqual(child_resp.status_code, status.HTTP_201_CREATED)

        # 3. Public Discovery Verification (No Auth Required)
        self.client.logout()
        public_resp = self.client.get(self.public_list_url)
        self.assertEqual(public_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(public_resp.data), 1)  # Only top-level parent categories returned at root
        self.assertEqual(public_resp.data[0]['name'], "Bespoke Bridal Couture")
        
        # Verify subcategory is embedded cleanly in parent object
        subcats = public_resp.data[0]['subcategories']
        self.assertEqual(len(subcats), 1)
        self.assertEqual(subcats[0]['name'], "Bridal Lehengas")
        self.assertEqual(subcats[0]['slug'], "bridal-lehengas")

        # 4. Soft Delete Verification
        self.client.force_authenticate(user=self.admin_user)
        delete_url = reverse('admin-category-detail', kwargs={'pk': parent_id})
        delete_resp = self.client.delete(delete_url)
        self.assertEqual(delete_resp.status_code, status.HTTP_204_NO_CONTENT)

        # Verify soft deleted category no longer appears in public discovery
        self.client.logout()
        self.assertEqual(len(self.client.get(self.public_list_url).data), 0)

    def test_unauthorized_users_blocked_from_admin_taxonomy_endpoints(self):
        """Verify standard customer or vendor roles receive 403 Forbidden when attempting taxonomy mutations."""
        self.client.force_authenticate(user=self.customer_user)
        self.assertEqual(self.client.post(self.admin_list_url, {"name": "Hack"}, format='json').status_code, status.HTTP_403_FORBIDDEN)
