from django.test import TestCase
from django.urls import reverse
from django.core.cache import cache
from rest_framework import status
from rest_framework.test import APIClient
from apps.accounts.models import User, UserRole
from apps.vendors.models import VendorProfile, VendorStatus
from apps.accounts.views import _make_otp_cache_key
from rest_framework_simplejwt.tokens import RefreshToken

class AuthenticationAndRBACTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.send_url = reverse('auth-otp-send')
        self.verify_url = reverse('auth-otp-verify')
        self.login_url = reverse('auth-customer-login')
        self.refresh_url = reverse('token-refresh')
        self.verify_purpose_url = reverse('auth-otp-verify-purpose')
        self.password_reset_url = reverse('auth-password-reset')
        self.me_url = reverse('auth-me')
        self.test_customer_url = reverse('rbac-test-customer')
        self.test_vendor_url = reverse('rbac-test-vendor')
        self.test_admin_url = reverse('rbac-test-admin')
        self.test_superadmin_url = reverse('rbac-test-superadmin')
        self.catalog_check_url = reverse('vendor-approved-catalog-check')

    def test_otp_send_and_verify_jwt_issuance(self):
        """Test complete passwordless OTP login challenge and JWT bearer exchange."""
        phone = "+919800000001"
        send_response = self.client.post(self.send_url, {"phone_number": phone, "role": "VENDOR"}, format='json')
        self.assertEqual(send_response.status_code, status.HTTP_200_OK)
        self.assertIn("expires_in_seconds", send_response.data)

        # Retrieve dynamic OTP from cache
        cache_key = _make_otp_cache_key(phone)
        otp = cache.get(cache_key)
        self.assertIsNotNone(otp)

        verify_response = self.client.post(self.verify_url, {"phone_number": phone, "otp": otp, "role": "VENDOR"}, format='json')
        self.assertEqual(verify_response.status_code, status.HTTP_200_OK)
        self.assertIn("access", verify_response.data)
        self.assertIn("refresh", verify_response.data)
        self.assertEqual(verify_response.data['role'], 'VENDOR')

        access_token = verify_response.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')
        profile_response = self.client.get(self.me_url)
        self.assertEqual(profile_response.status_code, status.HTTP_200_OK)
        self.assertEqual(profile_response.data['phone_number'], phone)
        self.assertEqual(profile_response.data['role'], 'VENDOR')

    def test_invalid_otp_rejection(self):
        """Verify wrong OTP code returns standardized JSON validation error."""
        verify_response = self.client.post(self.verify_url, {"phone_number": "+919800000001", "otp": "999999"}, format='json')
        self.assertEqual(verify_response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue('error' in verify_response.data)

    def test_vendor_login_with_email_and_password(self):
        """Verify vendor can log in using registered email and password."""
        vendor_user = User.objects.create_user(
            phone_number="9876543210",
            email="vendor_studio@test.com",
            role=UserRole.VENDOR,
            full_name="Tejasi Nambiar"
        )
        vendor_user.set_password("VendorPass123!")
        vendor_user.save()

        VendorProfile.objects.create(
            user=vendor_user,
            owner_name="Tejasi Nambiar",
            official_email="vendor_studio@test.com",
            phone_number="9876543210",
            status=VendorStatus.APPROVED
        )

        # 1. Login with exact email
        response = self.client.post(self.login_url, {
            "email": "vendor_studio@test.com",
            "password": "VendorPass123!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)
        self.assertEqual(response.data['role'], 'VENDOR')
        self.assertEqual(response.data['vendor_status'], 'APPROVED')
        self.assertTrue(response.data['is_approved'])

        # 2. Login with uppercase / whitespace email normalization
        response_norm = self.client.post(self.login_url, {
            "identifier": "  VENDOR_STUDIO@TEST.COM  ",
            "password": "VendorPass123!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(response_norm.status_code, status.HTTP_200_OK)

    def test_vendor_login_with_mobile_number_and_password(self):
        """Verify vendor can log in using registered mobile number and password."""
        vendor_user = User.objects.create_user(
            phone_number="9988776655",
            email="studio99@test.com",
            role=UserRole.VENDOR,
            full_name="Ananya Rao"
        )
        vendor_user.set_password("StudioPass123!")
        vendor_user.save()

        VendorProfile.objects.create(
            user=vendor_user,
            owner_name="Ananya Rao",
            official_email="studio99@test.com",
            phone_number="9988776655",
            status=VendorStatus.APPROVED
        )

        # 1. 10-digit raw mobile
        res1 = self.client.post(self.login_url, {
            "identifier": "9988776655",
            "password": "StudioPass123!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(res1.status_code, status.HTTP_200_OK)
        self.assertEqual(res1.data['role'], 'VENDOR')

        # 2. Mobile with +91 country prefix
        res2 = self.client.post(self.login_url, {
            "identifier": "+919988776655",
            "password": "StudioPass123!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(res2.status_code, status.HTTP_200_OK)

        # 3. Mobile with spaces and dashes
        res3 = self.client.post(self.login_url, {
            "identifier": "+91 99887-76655",
            "password": "StudioPass123!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(res3.status_code, status.HTTP_200_OK)

    def test_invalid_identifier_and_password(self):
        """Verify rejection of unknown identifiers and invalid passwords."""
        # Unknown identifier
        res_unknown = self.client.post(self.login_url, {
            "identifier": "nobody@test.com",
            "password": "AnyPassword123!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(res_unknown.status_code, status.HTTP_401_UNAUTHORIZED)

        # Known user with wrong password
        u = User.objects.create_user(phone_number="9123456789", email="known@test.com", role=UserRole.VENDOR)
        u.set_password("CorrectPass123!")
        u.save()

        res_wrong_pw = self.client.post(self.login_url, {
            "identifier": "known@test.com",
            "password": "WrongPassword!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(res_wrong_pw.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_customer_only_account_rejected_by_vendor_login(self):
        """Customer-only accounts must NOT obtain vendor access."""
        cust = User.objects.create_user(phone_number="9000000010", email="cust_only@test.com", role=UserRole.CUSTOMER)
        cust.set_password("CustPass123!")
        cust.save()

        # Attempt login using email on Vendor app
        res_email = self.client.post(self.login_url, {
            "identifier": "cust_only@test.com",
            "password": "CustPass123!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(res_email.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn("Account exists with a different role", res_email.data['error'])

        # Attempt login using phone on Vendor app
        res_phone = self.client.post(self.login_url, {
            "identifier": "9000000010",
            "password": "CustPass123!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(res_phone.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn("Account exists with a different role", res_phone.data['error'])

    def test_vendor_only_account_rejected_by_customer_login(self):
        """Vendor-only accounts must NOT obtain customer access."""
        vend = User.objects.create_user(phone_number="9000000020", email="vend_only@test.com", role=UserRole.VENDOR)
        vend.set_password("VendPass123!")
        vend.save()

        res = self.client.post(self.login_url, {
            "identifier": "vend_only@test.com",
            "password": "VendPass123!",
            "role": "CUSTOMER"
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn("Account exists with a different role", res.data['error'])

    def test_inactive_and_vendor_status_restrictions(self):
        """Verify inactive accounts and suspended/rejected vendor restrictions."""
        vend = User.objects.create_user(phone_number="9000000030", email="susp_vend@test.com", role=UserRole.VENDOR)
        vend.set_password("Pass12345!")
        vend.save()
        vp = VendorProfile.objects.create(
            user=vend,
            owner_name="Suspended Owner",
            official_email="susp_vend@test.com",
            phone_number="9000000030",
            status=VendorStatus.SUSPENDED,
            rejection_reason="Compliance policy violation"
        )

        # 1. Suspended vendor login rejected
        res_susp = self.client.post(self.login_url, {
            "identifier": "susp_vend@test.com",
            "password": "Pass12345!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(res_susp.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn("suspended", res_susp.data['error'].lower())

        # 2. Rejected vendor login rejected
        vp.status = VendorStatus.REJECTED
        vp.rejection_reason = "Unverified identity"
        vp.save()
        res_rej = self.client.post(self.login_url, {
            "identifier": "susp_vend@test.com",
            "password": "Pass12345!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(res_rej.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn("rejected", res_rej.data['error'].lower())

        # 3. Disabled account rejected
        vp.status = VendorStatus.APPROVED
        vp.save()
        vend.is_active = False
        vend.save()
        res_dis = self.client.post(self.login_url, {
            "identifier": "susp_vend@test.com",
            "password": "Pass12345!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(res_dis.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn("disabled", res_dis.data['error'].lower())

        # 4. Pending vendor can log in, but catalog operations are blocked
        vend.is_active = True
        vend.save()
        vp.status = VendorStatus.PENDING
        vp.save()
        res_pend = self.client.post(self.login_url, {
            "identifier": "susp_vend@test.com",
            "password": "Pass12345!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(res_pend.status_code, status.HTTP_200_OK)
        self.assertEqual(res_pend.data['vendor_status'], 'PENDING')
        self.assertFalse(res_pend.data['is_approved'])

        # Catalog access attempt with pending status
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {res_pend.data['access']}")
        cat_res = self.client.get(self.catalog_check_url)
        self.assertEqual(cat_res.status_code, status.HTTP_403_FORBIDDEN)

    def test_jwt_refresh_and_role_checks(self):
        """Verify RoleAwareTokenRefreshView enforces user active status, role, and vendor status."""
        vend = User.objects.create_user(phone_number="9000000040", email="refresh_vend@test.com", role=UserRole.VENDOR)
        vend.set_password("RefreshPass123!")
        vend.save()
        vp = VendorProfile.objects.create(
            user=vend,
            owner_name="Refresh Owner",
            official_email="refresh_vend@test.com",
            phone_number="9000000040",
            status=VendorStatus.APPROVED
        )

        refresh = RefreshToken.for_user(vend)
        refresh['role'] = vend.role

        # 1. Valid refresh
        res1 = self.client.post(self.refresh_url, {"refresh": str(refresh)}, format='json')
        self.assertEqual(res1.status_code, status.HTTP_200_OK)
        self.assertIn("access", res1.data)
        self.assertEqual(res1.data['role'], 'VENDOR')

        # 2. Deactivated account refresh fails
        vend.is_active = False
        vend.save()
        res_deact = self.client.post(self.refresh_url, {"refresh": str(refresh)}, format='json')
        self.assertEqual(res_deact.status_code, status.HTTP_403_FORBIDDEN)

        # 3. Suspended vendor refresh fails
        vend.is_active = True
        vend.save()
        vp.status = VendorStatus.SUSPENDED
        vp.save()
        res_susp = self.client.post(self.refresh_url, {"refresh": str(refresh)}, format='json')
        self.assertEqual(res_susp.status_code, status.HTTP_403_FORBIDDEN)

    def test_vendor_password_recovery_flow(self):
        """Verify full password recovery flow for vendor via registered email."""
        vend = User.objects.create_user(
            phone_number="9000000050",
            email="recover_vend@test.com",
            role=UserRole.VENDOR,
            full_name="Pooja Reddy"
        )
        vend.set_password("OldPassword123!")
        vend.save()
        VendorProfile.objects.create(
            user=vend,
            owner_name="Pooja Reddy",
            official_email="recover_vend@test.com",
            phone_number="9000000050",
            status=VendorStatus.APPROVED
        )

        # 1. Request recovery OTP
        req_res = self.client.post(self.send_url, {
            "email": "recover_vend@test.com",
            "role": "VENDOR",
            "purpose": "PASSWORD_RESET"
        }, format='json')
        self.assertEqual(req_res.status_code, status.HTTP_200_OK)

        # Retrieve OTP from cache
        cache_key = _make_otp_cache_key("recover_vend@test.com")
        otp = cache.get(cache_key)
        self.assertIsNotNone(otp)

        # 2. Verify OTP for PASSWORD_RESET purpose
        verify_res = self.client.post(self.verify_purpose_url, {
            "email": "recover_vend@test.com",
            "otp": otp,
            "purpose": "PASSWORD_RESET"
        }, format='json')
        self.assertEqual(verify_res.status_code, status.HTTP_200_OK)
        reset_token = verify_res.data.get('reset_token')
        self.assertIsNotNone(reset_token)

        # 3. Complete password reset
        reset_res = self.client.post(self.password_reset_url, {
            "email": "recover_vend@test.com",
            "reset_token": reset_token,
            "password": "NewSecretPass456!",
            "confirm_password": "NewSecretPass456!"
        }, format='json')
        self.assertEqual(reset_res.status_code, status.HTTP_200_OK)
        self.assertTrue(reset_res.data['success'])

        # 4. Token is single-use: Reusing reset_token must fail
        reuse_res = self.client.post(self.password_reset_url, {
            "email": "recover_vend@test.com",
            "reset_token": reset_token,
            "password": "AnotherPassword456!",
            "confirm_password": "AnotherPassword456!"
        }, format='json')
        self.assertEqual(reuse_res.status_code, status.HTTP_400_BAD_REQUEST)

        # 5. Sign in with the newly updated password
        login_res = self.client.post(self.login_url, {
            "identifier": "recover_vend@test.com",
            "password": "NewSecretPass456!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(login_res.status_code, status.HTTP_200_OK)

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

    def test_vendor_registration_with_email_otp(self):
        """Verify Vendor registration requires valid Email OTP before creating account."""
        reg_url = "/api/v1/vendor/auth/register/"
        email = "new_partner@boutique.com"
        phone = "9876543299"

        # 1. Request registration OTP
        req_res = self.client.post(self.send_url, {
            "email": email,
            "phone_number": phone,
            "role": "VENDOR",
            "purpose": "REGISTRATION",
            "full_name": "Meera Textiles"
        }, format='json')
        self.assertEqual(req_res.status_code, status.HTTP_200_OK)

        # Retrieve OTP from cache
        cache_key = _make_otp_cache_key(email)
        otp = cache.get(cache_key)
        self.assertIsNotNone(otp)

        # 2. Registration with wrong OTP must be rejected
        fail_res = self.client.post(reg_url, {
            "owner_name": "Meera Textiles",
            "email": email,
            "phone_number": phone,
            "password": "StrongPassword123!",
            "confirm_password": "StrongPassword123!",
            "otp": "000000"
        }, format='json')
        self.assertEqual(fail_res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue("otp" in fail_res.data or "otp" in fail_res.data.get("details", {}))

        # 3. Registration with valid OTP succeeds
        success_res = self.client.post(reg_url, {
            "owner_name": "Meera Textiles",
            "email": email,
            "phone_number": phone,
            "password": "StrongPassword123!",
            "confirm_password": "StrongPassword123!",
            "otp": otp
        }, format='json')
        self.assertEqual(success_res.status_code, status.HTTP_201_CREATED)

        # Verify user state in DB
        created_user = User.objects.get(email=email)
        self.assertEqual(created_user.role, UserRole.VENDOR)
        self.assertTrue(created_user.is_verified)
        self.assertTrue(created_user.is_active)
        self.assertEqual(created_user.vendor_profile.status, VendorStatus.PENDING)

        # 4. OTP is single-use: cache key was deleted
        self.assertIsNone(cache.get(cache_key))

        # 5. Vendor can now log in using email and password
        login_res = self.client.post(self.login_url, {
            "identifier": email,
            "password": "StrongPassword123!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(login_res.status_code, status.HTTP_200_OK)
        self.assertIn("access", login_res.data)

        # 6. Vendor can also log in using mobile number and password
        login_phone_res = self.client.post(self.login_url, {
            "identifier": phone,
            "password": "StrongPassword123!",
            "role": "VENDOR"
        }, format='json')
        self.assertEqual(login_phone_res.status_code, status.HTTP_200_OK)

