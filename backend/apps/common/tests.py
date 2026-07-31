from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from apps.accounts.models import User, UserRole

class CommonInfrastructureTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_health_check_endpoint(self):
        """Verify API Health probe responds with operational database state."""
        response = self.client.get(reverse('api-health-check'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'ok')
        self.assertEqual(response.data['service'], 'HER AREA Unified Backend Engine')

    def test_soft_delete_manager_behavior(self):
        """Verify soft deletion preserves records in DB while hiding them from active querysets."""
        user = User.objects.create_user(phone_number="+919876543200", role=UserRole.CUSTOMER)
        self.assertEqual(User.objects.count(), 1)
        
        # Execute soft deletion
        user.delete()
        
        # Verified hidden from default active queryset
        self.assertEqual(User.objects.count(), 0)
        # Verified retained in database storage via all_objects / deleted_only
        self.assertEqual(User.all_objects.count(), 1)
        self.assertEqual(User.objects.deleted_only().count(), 1)
        self.assertTrue(User.all_objects.first().is_deleted)
        self.assertIsNotNone(User.all_objects.first().deleted_at)

    def test_swagger_openapi_schema_generation(self):
        """Verify OpenAPI schema is generated cleanly by drf-spectacular without errors."""
        response = self.client.get(reverse('schema'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('openapi', response.data)
        self.assertEqual(response.data['info']['title'], 'HER AREA Marketplace API Engine')
