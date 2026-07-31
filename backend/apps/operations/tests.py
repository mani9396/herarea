from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from apps.accounts.models import User, UserRole
from apps.catalog.models import StockStatus, CatalogItemType
from apps.operations.models import BookingStatus, EnquiryStatus
from apps.notifications.models import Notification, NotificationType

class BookingOrdersAndBusinessOperationsTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.vendor_user = User.objects.create_user(phone_number="+919222222201", role=UserRole.VENDOR)
        self.unapproved_vendor_user = User.objects.create_user(phone_number="+919222222202", role=UserRole.VENDOR)
        self.admin_user = User.objects.create_superuser(phone_number="+919222222299", role=UserRole.ADMIN)
        self.customer = User.objects.create_user(phone_number="+919333333301", role=UserRole.CUSTOMER)

        # Onboard Vendor
        self.client.force_authenticate(user=self.vendor_user)
        onboarding_data = {
            "owner_name": "Rhea Kapoor",
            "official_email": "rhea@couture.in",
            "phone_number": "+919222222201",
            "business_name": "Rhea Bridal Studio",
            "description": "Luxury bespoke fashion house & styling lounge.",
            "address_line_1": "Juhu Tara Road",
            "city": "Mumbai",
            "state": "Maharashtra",
            "pincode": "400049",
            "contact_email": "concierge@rhea.in",
            "contact_phone": "+919800080009"
        }
        reg_resp = self.client.post(reverse('vendor-onboarding-register'), onboarding_data, format='json')
        self.vendor_id = reg_resp.data['id']
        self.store_id = reg_resp.data['business_profile']['id']

        # Onboard Unapproved Vendor (PENDING status)
        self.client.force_authenticate(user=self.unapproved_vendor_user)
        self.client.post(reverse('vendor-onboarding-register'), {
            "owner_name": "Unapproved Owner",
            "official_email": "unapp@test.in",
            "phone_number": "+919222222202",
            "business_name": "Unapproved Store",
            "description": "Pending audit.",
            "address_line_1": "Test Road",
            "city": "Delhi",
            "state": "Delhi",
            "pincode": "110001",
            "contact_email": "un@test.in",
            "contact_phone": "+919800080000"
        }, format='json')

        # Admin Approve First Vendor
        self.client.force_authenticate(user=self.admin_user)
        self.client.post(reverse('admin-vendor-approve', kwargs={'pk': self.vendor_id}))

        # Approved Vendor registers a PRODUCT and a SERVICE in Catalog
        self.client.force_authenticate(user=self.vendor_user)
        prod_url = reverse('vendor-catalog-product-list')

        # 1. Physical Couture Product
        resp_prod = self.client.post(prod_url, {
            "name": "Heirloom Ruby Velvet Lehenga",
            "description": "Custom hand-embroidered velvet bridal attire.",
            "price": "250000.00",
            "item_type": CatalogItemType.PRODUCT,
            "stock_status": StockStatus.IN_STOCK,
            "image_url": "https://storage.herarea.internal/lehenga.jpg"
        }, format='json')
        self.product_id = resp_prod.data['id']

        # 2. Bespoke Styling Service
        resp_srv = self.client.post(prod_url, {
            "name": "VIP Bridal Dressing & Draping Suite",
            "description": "Full-day bespoke fitting and event draping service.",
            "price": "35000.00",
            "item_type": CatalogItemType.SERVICE,
            "service_duration_minutes": 180,
            "stock_status": StockStatus.IN_STOCK,
            "image_url": "https://storage.herarea.internal/draping.jpg"
        }, format='json')
        self.service_id = resp_srv.data['id']

    def test_vendor_schedule_management_governance_and_public_discovery(self):
        """
        Verify Approved Studios can configure weekly operating schedules and slot intervals,
        confirm unapproved vendors are blocked by IsApprovedVendor, and verify public discovery.
        """
        # 1. Unapproved Vendor fails schedule creation (403 Forbidden)
        self.client.force_authenticate(user=self.unapproved_vendor_user)
        resp_fail = self.client.post(reverse('vendor-schedule-list-create'), {
            "day_of_week": 0,
            "open_time": "09:00:00",
            "close_time": "17:00:00"
        }, format='json')
        self.assertEqual(resp_fail.status_code, status.HTTP_403_FORBIDDEN)

        # 2. Approved Vendor configures Monday (0) schedule
        self.client.force_authenticate(user=self.vendor_user)
        resp_ok = self.client.post(reverse('vendor-schedule-list-create'), {
            "day_of_week": 0,
            "open_time": "10:30:00",
            "close_time": "19:30:00",
            "slot_duration_minutes": 90
        }, format='json')
        self.assertEqual(resp_ok.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp_ok.data['day_name'], "Monday")
        self.assertEqual(resp_ok.data['slot_duration_minutes'], 90)

        # 3. Public User queries Showroom Schedule
        self.client.logout()
        pub_resp = self.client.get(reverse('public-store-schedule', kwargs={'store_id': self.store_id}))
        self.assertEqual(pub_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(pub_resp.data), 1)
        self.assertEqual(pub_resp.data[0]['open_time'], "10:30:00")

    def test_service_appointment_booking_and_status_workflow_with_notifications(self):
        """
        Verify customer service appointment booking, item type protection, vendor dashboard management, 
        confirmation state transitions, and automatic bidirectional NotificationEngine alerts.
        """
        self.client.force_authenticate(user=self.customer)
        book_url = reverse('customer-booking-list-create')

        # 1. Attempting to book an appointment for a physical PRODUCT must fail with validation error!
        bad_resp = self.client.post(book_url, {
            "service": str(self.product_id),
            "appointment_date": "2026-08-15",
            "start_time": "11:00:00"
        }, format='json')
        self.assertEqual(bad_resp.status_code, status.HTTP_400_BAD_REQUEST)

        # 2. Customer successfully books an appointment for the VIP Dressing SERVICE
        book_resp = self.client.post(book_url, {
            "service": str(self.service_id),
            "appointment_date": "2026-08-15",
            "start_time": "11:00:00",
            "customer_notes": "Please prepare pastel bridal pin suites."
        }, format='json')
        self.assertEqual(book_resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(book_resp.data['status'], "PENDING")
        booking_id = book_resp.data['id']

        # Verify Vendor received real-time booking alert!
        vendor_notifs = Notification.objects.filter(recipient=self.vendor_user, title="New Appointment Booking Request!")
        self.assertTrue(vendor_notifs.exists())

        # 3. Vendor checks dashboard and confirms appointment
        self.client.force_authenticate(user=self.vendor_user)
        list_resp = self.client.get(reverse('vendor-booking-list'), {"status": "PENDING"})
        self.assertEqual(len(list_resp.data), 1)

        update_url = reverse('vendor-booking-status-update', kwargs={'pk': booking_id})
        conf_resp = self.client.patch(update_url, {
            "status": BookingStatus.CONFIRMED,
            "studio_feedback": "We have reserved Suite 1 and our senior stylists for you!"
        }, format='json')
        self.assertEqual(conf_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(conf_resp.data['status'], "CONFIRMED")
        self.assertEqual(conf_resp.data['studio_feedback'], "We have reserved Suite 1 and our senior stylists for you!")

        # Verify Customer received instant confirmation alert!
        cust_notifs = Notification.objects.filter(recipient=self.customer, title__contains="CONFIRMED")
        self.assertTrue(cust_notifs.exists())

        # 4. Customer verifies booking history
        self.client.force_authenticate(user=self.customer)
        hist_resp = self.client.get(book_url, {"status": "CONFIRMED"})
        self.assertEqual(len(hist_resp.data), 1)

    def test_bespoke_product_enquiry_and_studio_quotation_order_workflow(self):
        """
        Verify customer couture product inquiries, studio price quotations, and conversion to orders.
        """
        self.client.force_authenticate(user=self.customer)
        enq_url = reverse('customer-enquiry-list-create')

        # 1. Customer submits inquiry on Heirloom Lehenga
        resp_enq = self.client.post(enq_url, {
            "product": str(self.product_id),
            "message": "Can this lehenga be custom woven in royal emerald green with zardozi borders?",
            "target_delivery_date": "2026-10-01"
        }, format='json')
        self.assertEqual(resp_enq.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp_enq.data['status'], "OPEN")
        enq_id = resp_enq.data['id']

        # 2. Studio Owner responds with quote and updates status to ORDER_PLACED
        self.client.force_authenticate(user=self.vendor_user)
        resp_url = reverse('vendor-enquiry-respond', kwargs={'pk': enq_id})
        quote_resp = self.client.patch(resp_url, {
            "status": EnquiryStatus.ORDER_PLACED,
            "studio_response": "Yes! Emerald green velvet and authentic gold zardozi are available. Order initiated.",
            "quoted_price": "275000.00"
        }, format='json')
        self.assertEqual(quote_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(quote_resp.data['status'], "ORDER_PLACED")
        self.assertEqual(quote_resp.data['quoted_price'], "275000.00")

        # Verify Customer received quotation notification!
        cust_notifs = Notification.objects.filter(recipient=self.customer, title="Studio Responded to Couture Enquiry!")
        self.assertTrue(cust_notifs.exists())

    def test_admin_platform_oversight_and_dispute_intervention(self):
        """
        Verify platform Administrators can oversee all bookings and force-update status with alerts.
        """
        # Create an appointment
        self.client.force_authenticate(user=self.customer)
        b_resp = self.client.post(reverse('customer-booking-list-create'), {
            "service": str(self.service_id),
            "appointment_date": "2026-09-01",
            "start_time": "14:00:00"
        }, format='json')
        b_id = b_resp.data['id']

        # Admin overrides status to RESCHEDULED
        self.client.force_authenticate(user=self.admin_user)
        admin_list_resp = self.client.get(reverse('admin-booking-list'))
        self.assertGreaterEqual(len(admin_list_resp.data), 1)

        override_url = reverse('admin-booking-status-override', kwargs={'pk': b_id})
        ov_resp = self.client.patch(override_url, {
            "status": BookingStatus.RESCHEDULED,
            "studio_feedback": "Rescheduled due to municipal power grid maintenance in showroom zone."
        }, format='json')
        self.assertEqual(ov_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(ov_resp.data['status'], "RESCHEDULED")
