from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from apps.accounts.models import User, UserRole

class BusinessShowroomProfileTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.register_url = reverse('vendor-onboarding-register')
        self.business_me_url = reverse('business-profile-me')
        self.vendor_user = User.objects.create_user(phone_number="+919111111199", role=UserRole.VENDOR)
        
        self.onboarding_payload = {
            "owner_name": "Deepika Rao",
            "official_email": "deepika.rao@herarea.in",
            "phone_number": "+919111111199",
            "business_name": "Aura Luxury Wellness Studio",
            "address_line_1": "Level 4, Orion Towers, Brigade Way",
            "city": "Bengaluru",
            "state": "Karnataka",
            "pincode": "560025",
            "contact_email": "hello@aurastudio.in",
            "contact_phone": "+919000090000",
            "business_timings": {"Mon - Sun": "09:00 AM - 09:00 PM"},
        }

    def test_vendor_can_view_and_update_business_showroom_and_timings(self):
        """Verify partner studio owner can read and refine showroom address, contact numbers, and operation timings."""
        self.client.force_authenticate(user=self.vendor_user)
        
        # Initialize via onboarding registration
        self.client.post(self.register_url, self.onboarding_payload, format='json')
        
        # Read Business Profile
        get_resp = self.client.get(self.business_me_url)
        self.assertEqual(get_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(get_resp.data['business_name'], "Aura Luxury Wellness Studio")
        self.assertEqual(get_resp.data['city'], "Bengaluru")
        self.assertEqual(get_resp.data['business_timings']['Mon - Sun'], "09:00 AM - 09:00 PM")

        # Update Business Timings & Contact Number
        update_payload = {
            "contact_phone": "+919555555555",
            "business_timings": {"Mon - Fri": "08:00 AM - 10:00 PM", "Sat - Sun": "10:00 AM - 08:00 PM"}
        }
        put_resp = self.client.put(self.business_me_url, update_payload, format='json')
        self.assertEqual(put_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(put_resp.data['contact_phone'], "+919555555555")
        self.assertIn("Mon - Fri", put_resp.data['business_timings'])
