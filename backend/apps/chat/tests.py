from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from apps.accounts.models import User, UserRole
from apps.business.models import BusinessProfile
from apps.vendors.models import VendorProfile, VendorStatus, ChatStatus
from apps.subscriptions.models import ListingPlan, VendorSubscription
from apps.chat.models import Conversation, Message

class ChatAPITestCase(APITestCase):
    def setUp(self):
        self.customer = User.objects.create(email='customer@test.com', phone_number='1234567890', role=UserRole.CUSTOMER)
        self.customer.set_password('password')
        self.customer.save()

        self.vendor = User.objects.create(email='vendor@test.com', phone_number='0987654321', role=UserRole.VENDOR)
        self.vendor.set_password('password')
        self.vendor.save()

        self.vendor_profile = VendorProfile.objects.create(
            user=self.vendor,
            owner_name='Vendor Owner',
            status=VendorStatus.APPROVED,
            chat_status=ChatStatus.ACTIVE
        )

        self.store = BusinessProfile.objects.create(
            vendor=self.vendor_profile,
            business_name="Test Store"
        )

        self.plan = ListingPlan.objects.create(
            name="Chat Plan",
            price=100,
            duration_days=30,
            customer_chat=True
        )

        self.subscription = VendorSubscription.objects.create(
            vendor=self.vendor,
            store=self.store,
            plan=self.plan,
            status='ACTIVE'
        )

    def test_start_conversation_success(self):
        self.client.force_authenticate(user=self.customer)
        url = reverse('conversation_start')
        response = self.client.post(url, {'vendor_id': self.vendor.id})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Conversation.objects.count(), 1)

    def test_start_conversation_rejected_if_vendor_disabled(self):
        self.vendor_profile.chat_status = ChatStatus.DISABLED
        self.vendor_profile.save()

        self.client.force_authenticate(user=self.customer)
        url = reverse('conversation_start')
        response = self.client.post(url, {'vendor_id': self.vendor.id})
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_start_conversation_rejected_if_plan_no_chat(self):
        self.plan.customer_chat = False
        self.plan.save()

        self.client.force_authenticate(user=self.customer)
        url = reverse('conversation_start')
        response = self.client.post(url, {'vendor_id': self.vendor.id})
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_ws_token_generation(self):
        self.client.force_authenticate(user=self.customer)
        url = reverse('ws_token')
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('ws_token', response.data)

