from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from apps.accounts.models import User, UserRole

class AuthenticationAndRBACTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.send_url = reverse('auth-otp-send')
        self.verify_url = reverse('auth-otp-verify')
        self.me_url = reverse('auth-me')
        self.test_customer_url = reverse('rbac-test-customer')
        self.test_vendor_url = reverse('rbac-test-vendor')
        self.test_admin_url = reverse('rbac-test-admin')
        self.test_superadmin_url = reverse('rbac-test-superadmin')

    def test_otp_send_and_verify_jwt_issuance(self):
        """Test complete passwordless OTP login challenge and JWT bearer exchange."""
        # 1. Dispatch OTP challenge
        send_response = self.client.post(self.send_url, {"phone_number": "+919800000001", "role": "VENDOR"}, format='json')
        self.assertEqual(send_response.status_code, status.HTTP_200_OK)
        self.assertIn("expires_in_seconds", send_response.data)

        # 2. Verify OTP code '123456' and obtain JWT token pair
        verify_response = self.client.post(self.verify_url, {"phone_number": "+919800000001", "otp": "123456", "role": "VENDOR"}, format='json')
        self.assertEqual(verify_response.status_code, status.HTTP_200_OK)
        self.assertIn("access", verify_response.data)
        self.assertIn("refresh", verify_response.data)
        self.assertEqual(verify_response.data['role'], 'VENDOR')

        # 3. Authenticate with access token and read profile
        access_token = verify_response.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')
        profile_response = self.client.get(self.me_url)
        self.assertEqual(profile_response.status_code, status.HTTP_200_OK)
        self.assertEqual(profile_response.data['phone_number'], "+919800000001")
        self.assertEqual(profile_response.data['role'], 'VENDOR')

    def test_invalid_otp_rejection(self):
        """Verify wrong OTP code returns standardized JSON validation error."""
        verify_response = self.client.post(self.verify_url, {"phone_number": "+919800000001", "otp": "999999"}, format='json')
        self.assertEqual(verify_response.status_code, status.HTTP_400_BAD_REQUEST)
        # Check custom exception handler structure
        self.assertTrue(verify_response.data['error'])
        self.assertEqual(verify_response.data['status_code'], 400)

    def test_rbac_role_isolation_enforcement(self):
        """Verify strict RBAC boundaries: Customer vs Vendor vs Admin vs SuperAdmin."""
        customer_user = User.objects.create_user(phone_number="+919000000001", role=UserRole.CUSTOMER)
        vendor_user = User.objects.create_user(phone_number="+919000000002", role=UserRole.VENDOR)
        admin_user = User.objects.create_user(phone_number="+919000000003", role=UserRole.ADMIN)
        superadmin_user = User.objects.create_user(phone_number="+919000000004", role=UserRole.SUPERADMIN)

        # 1. Customer Access Evaluation
        self.client.force_authenticate(user=customer_user)
        self.assertEqual(self.client.get(self.test_customer_url).status_code, status.HTTP_200_OK)
        self.assertEqual(self.client.get(self.test_vendor_url).status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(self.client.get(self.test_admin_url).status_code, status.HTTP_403_FORBIDDEN)

        # 2. Vendor Access Evaluation
        self.client.force_authenticate(user=vendor_user)
        self.assertEqual(self.client.get(self.test_vendor_url).status_code, status.HTTP_200_OK)
        self.assertEqual(self.client.get(self.test_customer_url).status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(self.client.get(self.test_superadmin_url).status_code, status.HTTP_403_FORBIDDEN)

        # 3. Staff Admin & SuperAdmin Governance Evaluation
        self.client.force_authenticate(user=admin_user)
        self.assertEqual(self.client.get(self.test_admin_url).status_code, status.HTTP_200_OK)
        self.assertEqual(self.client.get(self.test_superadmin_url).status_code, status.HTTP_403_FORBIDDEN)

        self.client.force_authenticate(user=superadmin_user)
        self.assertEqual(self.client.get(self.test_admin_url).status_code, status.HTTP_200_OK)
        self.assertEqual(self.client.get(self.test_superadmin_url).status_code, status.HTTP_200_OK)
