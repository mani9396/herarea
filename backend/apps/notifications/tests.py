from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from apps.accounts.models import User, UserRole
from apps.notifications.models import Notification, NotificationType

class NotificationEngineTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.vendor_user = User.objects.create_user(phone_number="+919666666601", role=UserRole.VENDOR)
        self.admin_user = User.objects.create_superuser(phone_number="+919666666699", role=UserRole.ADMIN)

        # Onboard Vendor
        self.client.force_authenticate(user=self.vendor_user)
        onboarding_data = {
            "owner_name": "Sanya Malhotra",
            "official_email": "sanya@studio.in",
            "phone_number": "+919666666601",
            "business_name": "Sanya Couture & Studio",
            "description": "Luxury bespoke bridal wear.",
            "address_line_1": "Bandra West, Hill Road",
            "city": "Mumbai",
            "state": "Maharashtra",
            "pincode": "400050",
            "contact_email": "info@sanya.in",
            "contact_phone": "+919800080001"
        }
        self.reg_resp = self.client.post(reverse('vendor-onboarding-register'), onboarding_data, format='json')
        self.vendor_id = self.reg_resp.data['id']

        self.list_url = reverse('notification-list')
        self.read_all_url = reverse('notification-mark-read-all')

    def test_admin_approval_dispatches_atomic_onboarding_notification_to_vendor(self):
        """
        Verify that Admin governance operations (Approval) automatically trigger real-time 
        in-app alerts via NotificationEngine, and verify unread badge clearing workflows.
        """
        # Step 1: Admin approves partner studio
        self.client.force_authenticate(user=self.admin_user)
        approve_url = reverse('admin-vendor-approve', kwargs={'pk': self.vendor_id})
        resp_app = self.client.post(approve_url)
        self.assertEqual(resp_app.status_code, status.HTTP_200_OK)

        # Step 2: Vendor checks in-app notification feed
        self.client.force_authenticate(user=self.vendor_user)
        resp_notif = self.client.get(self.list_url)
        self.assertEqual(resp_notif.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp_notif.data), 1)

        notif_data = resp_notif.data[0]
        self.assertEqual(notif_data['title'], "Studio Onboarding Approved!")
        self.assertEqual(notif_data['notification_type'], NotificationType.ONBOARDING)
        self.assertFalse(notif_data['is_read'])
        self.assertEqual(notif_data['action_url'], "/vendor/dashboard")

        notif_id = notif_data['id']

        # Step 3: Test single read marker
        read_url = reverse('notification-mark-read', kwargs={'pk': notif_id})
        resp_read = self.client.patch(read_url)
        self.assertEqual(resp_read.status_code, status.HTTP_200_OK)
        self.assertTrue(resp_read.data['is_read'])

        # Step 4: Add extra simulated notifications and test read-all
        Notification.objects.create(recipient=self.vendor_user, title="New Review!", message="5 stars received.")
        Notification.objects.create(recipient=self.vendor_user, title="Security Alert", message="New login detected.")
        
        resp_read_all = self.client.post(self.read_all_url)
        self.assertEqual(resp_read_all.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_read_all.data['marked_read_count'], 2)

        # Verify all are now read
        unread_resp = self.client.get(self.list_url, {"unread": "true"})
        self.assertEqual(len(unread_resp.data), 0)
