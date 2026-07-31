from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from apps.accounts.models import User, UserRole
from apps.vendors.models import VendorProfile, VendorStatus, KycDocType, KycDocStatus

class VendorOnboardingAndApprovalWorkflowTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.register_url = reverse('vendor-onboarding-register')
        self.profile_me_url = reverse('vendor-profile-me')
        self.kyc_url = reverse('vendor-kyc-documents')
        self.catalog_check_url = reverse('vendor-approved-catalog-check')
        self.pending_list_url = reverse('admin-vendors-pending-list')

        # Create test actors
        self.vendor_user = User.objects.create_user(phone_number="+919111111101", role=UserRole.VENDOR, email="studio@herarea.in")
        self.admin_user = User.objects.create_superuser(phone_number="+919000000001", role=UserRole.ADMIN, email="admin@herarea.in")
        self.customer_user = User.objects.create_user(phone_number="+919222222201", role=UserRole.CUSTOMER)

        self.onboarding_payload = {
            "owner_name": "Priyanka Sharma",
            "official_email": "priyanka.studio@herarea.in",
            "phone_number": "+919111111101",
            "business_name": "Silk & Soul Designer Studio",
            "description": "Exclusive bridal wear and bespoke haute couture showroom.",
            "address_line_1": "14, Promenade Avenue, High Street",
            "city": "Bengaluru",
            "state": "Karnataka",
            "pincode": "560001",
            "contact_email": "concierge@silksoul.in",
            "contact_phone": "+919888888801",
            "business_timings": {"Mon - Sat": "10:30 AM - 08:30 PM", "Sun": "By Appointment Only"},
        }

    def test_complete_vendor_onboarding_to_admin_approval_lifecycle(self):
        """
        Verify end-to-end lifecycle:
        1. Vendor Registration -> PENDING state.
        2. Unapproved Vendor is blocked (403 Forbidden) from catalog management operations.
        3. Vendor submits KYC documentation.
        4. Admin inspects pending queue and executes APPROVE.
        5. Approved Vendor gains full access (200 OK) to catalog management operations.
        """
        # Step 1: Vendor registers onboarding profile & business details
        self.client.force_authenticate(user=self.vendor_user)
        reg_response = self.client.post(self.register_url, self.onboarding_payload, format='json')
        self.assertEqual(reg_response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(reg_response.data['status'], VendorStatus.PENDING)
        self.assertEqual(reg_response.data['business_profile']['business_name'], "Silk & Soul Designer Studio")

        # Step 2: Unapproved vendor attempts catalog access -> BLOCKED BY RBAC
        catalog_resp_blocked = self.client.get(self.catalog_check_url)
        self.assertEqual(catalog_resp_blocked.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn("Marketplace Approval Required", str(catalog_resp_blocked.data['message']))

        # Step 3: Vendor submits KYC compliance documents
        kyc_payload = {
            "document_type": KycDocType.GSTIN,
            "document_url": "https://storage.herarea.internal/kyc/gstin_cert.pdf",
            "document_number": "29AABCU9603R1ZM"
        }
        kyc_resp = self.client.post(self.kyc_url, kyc_payload, format='json')
        self.assertEqual(kyc_resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(kyc_resp.data['status'], KycDocStatus.PENDING)

        # Step 4: Governance Admin logs in, verifies queue, and approves vendor
        self.client.force_authenticate(user=self.admin_user)
        pending_queue_resp = self.client.get(self.pending_list_url)
        self.assertEqual(pending_queue_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(pending_queue_resp.data), 1)

        vendor_id = reg_response.data['id']
        approve_url = reverse('admin-vendor-approve', kwargs={'pk': vendor_id})
        approve_resp = self.client.post(approve_url)
        self.assertEqual(approve_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(approve_resp.data['status'], VendorStatus.APPROVED)
        self.assertIsNotNone(approve_resp.data['approved_at'])
        self.assertEqual(approve_resp.data['kyc_documents'][0]['status'], KycDocStatus.VERIFIED)

        # Step 5: Vendor logs back in -> Catalog access IS NOW AUTHORIZED!
        self.client.force_authenticate(user=self.vendor_user)
        catalog_resp_allowed = self.client.get(self.catalog_check_url)
        self.assertEqual(catalog_resp_allowed.status_code, status.HTTP_200_OK)
        self.assertEqual(catalog_resp_allowed.data['status'], "authorized")

    def test_admin_rejection_and_suspension_workflows(self):
        """
        Verify Admin rejection and suspension enforce strict catalog lockouts with rejection feedback reasoning.
        """
        # Create registered vendor
        self.client.force_authenticate(user=self.vendor_user)
        reg_response = self.client.post(self.register_url, self.onboarding_payload, format='json')
        vendor_id = reg_response.data['id']

        # Admin executes REJECT with explicit feedback reasoning
        self.client.force_authenticate(user=self.admin_user)
        reject_url = reverse('admin-vendor-reject', kwargs={'pk': vendor_id})
        reject_resp = self.client.post(reject_url, {"rejection_reason": "GSTIN document scan is blurry. Please re-upload clear certificate."}, format='json')
        self.assertEqual(reject_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(reject_resp.data['status'], VendorStatus.REJECTED)

        # Verify Vendor receives explicit rejection feedback upon hitting catalog gate
        self.client.force_authenticate(user=self.vendor_user)
        blocked_resp = self.client.get(self.catalog_check_url)
        self.assertEqual(blocked_resp.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn("Admin Reason: GSTIN document scan is blurry", str(blocked_resp.data['message']))

        # Admin overrides with APPROVE, then later SUSPENDS active studio
        self.client.force_authenticate(user=self.admin_user)
        self.client.post(reverse('admin-vendor-approve', kwargs={'pk': vendor_id}))
        
        suspend_url = reverse('admin-vendor-suspend', kwargs={'pk': vendor_id})
        suspend_resp = self.client.post(suspend_url, {"rejection_reason": "Temporary quality audit suspension."}, format='json')
        self.assertEqual(suspend_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(suspend_resp.data['status'], VendorStatus.SUSPENDED)

        # Verify suspended vendor is immediately locked out of catalog operations
        self.client.force_authenticate(user=self.vendor_user)
        susp_blocked_resp = self.client.get(self.catalog_check_url)
        self.assertEqual(susp_blocked_resp.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn("SUSPENDED", str(susp_blocked_resp.data['message']))

    def test_customer_cannot_access_vendor_or_admin_endpoints(self):
        """Verify standard customer role accounts are entirely excluded from onboarding & governance APIs."""
        self.client.force_authenticate(user=self.customer_user)
        self.assertEqual(self.client.post(self.register_url, {}, format='json').status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(self.client.get(self.pending_list_url).status_code, status.HTTP_403_FORBIDDEN)
