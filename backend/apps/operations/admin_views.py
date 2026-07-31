import logging
from rest_framework import status, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiParameter
from apps.accounts.permissions import IsAdminRole
from apps.operations.models import AppointmentBooking, ProductEnquiry, BookingStatus, EnquiryStatus
from apps.operations.serializers import AppointmentBookingSerializer, ProductEnquirySerializer
from apps.notifications.services import NotificationEngine
from apps.notifications.models import NotificationType

logger = logging.getLogger('her_area')

class AdminBookingListView(APIView):
    """
    Executive platform oversight queue allowing Administrators to monitor all showroom appointments
    across the entire HER AREA marketplace for quality governance and resolution.
    """
    permission_classes = [IsAdminRole]
    serializer_class = AppointmentBookingSerializer

    @extend_schema(
        summary="Admin Platform Appointments Oversight",
        parameters=[
            OpenApiParameter(name='status', description="Filter by BookingStatus", required=False, type=str),
            OpenApiParameter(name='store_id', description="Filter by specific BusinessProfile UUID", required=False, type=str)
        ],
        responses={200: AppointmentBookingSerializer(many=True)}
    )
    def get(self, request):
        bookings = AppointmentBooking.objects.select_related('service', 'business_profile', 'customer', 'business_profile__vendor').order_by('-appointment_date', '-start_time')
        stat = request.query_params.get('status')
        if stat:
            bookings = bookings.filter(status__iexact=stat)
        store_id = request.query_params.get('store_id')
        if store_id:
            bookings = bookings.filter(business_profile_id=store_id)
        return Response(AppointmentBookingSerializer(bookings, many=True).data, status=status.HTTP_200_OK)


class AdminEnquiryListView(APIView):
    """
    Executive monitoring queue for all bespoke product customization enquiries and order quotes.
    """
    permission_classes = [IsAdminRole]
    serializer_class = ProductEnquirySerializer

    @extend_schema(summary="Admin Bespoke Orders & Enquiries Oversight", responses={200: ProductEnquirySerializer(many=True)})
    def get(self, request):
        enquiries = ProductEnquiry.objects.select_related('product', 'business_profile', 'customer', 'business_profile__vendor').order_by('-created_at')
        return Response(ProductEnquirySerializer(enquiries, many=True).data, status=status.HTTP_200_OK)


class AdminBookingStatusOverrideView(APIView):
    """
    Executive intervention allowing Administrators to resolve disputes, force-cancel, 
    or audit any appointment on the platform, notifying both parties.
    """
    permission_classes = [IsAdminRole]
    serializer_class = AppointmentBookingSerializer

    @extend_schema(summary="Admin Override Appointment Status", responses={200: AppointmentBookingSerializer})
    def patch(self, request, pk):
        try:
            booking = AppointmentBooking.objects.select_related('customer', 'service', 'business_profile__vendor__user').get(pk=pk)
        except AppointmentBooking.DoesNotExist:
            raise exceptions.NotFound("Appointment booking not found.")

        new_status = request.data.get('status')
        feedback = request.data.get('studio_feedback', 'Status overridden by Platform Administrator.')

        if not new_status or new_status not in [choice[0] for choice in BookingStatus.choices]:
            raise exceptions.ValidationError("Valid status parameter required.")

        booking.status = new_status
        booking.studio_feedback = feedback
        booking.updated_by = request.user
        booking.save(update_fields=['status', 'studio_feedback', 'updated_by'])

        logger.warning(f"Admin {request.user.phone_number} forced status {new_status} on Booking {booking.id}")

        # Notify both Customer and Studio
        NotificationEngine.send_notification(
            recipient=booking.customer,
            title="Platform Administrative Update",
            message=f"Your appointment for '{booking.service.name}' was updated to {new_status} by an Administrator.",
            notification_type=NotificationType.SYSTEM,
            action_url="/user/appointments"
        )
        NotificationEngine.send_notification(
            recipient=booking.business_profile.vendor.user,
            title="Platform Administrative Intervention",
            message=f"Appointment {booking.id} for '{booking.service.name}' was overridden to {new_status} by Admin.",
            notification_type=NotificationType.SYSTEM,
            action_url="/vendor/bookings"
        )
        return Response(AppointmentBookingSerializer(booking).data, status=status.HTTP_200_OK)


class AdminEnquiryStatusOverrideView(APIView):
    """
    Executive intervention for bespoke orders and product inquiries.
    """
    permission_classes = [IsAdminRole]
    serializer_class = ProductEnquirySerializer

    @extend_schema(summary="Admin Override Enquiry Status", responses={200: ProductEnquirySerializer})
    def patch(self, request, pk):
        try:
            enquiry = ProductEnquiry.objects.select_related('customer', 'product', 'business_profile').get(pk=pk)
        except ProductEnquiry.DoesNotExist:
            raise exceptions.NotFound("Product enquiry not found.")

        new_status = request.data.get('status')
        if not new_status or new_status not in [choice[0] for choice in EnquiryStatus.choices]:
            raise exceptions.ValidationError("Valid status parameter required.")

        enquiry.status = new_status
        enquiry.updated_by = request.user
        enquiry.save(update_fields=['status', 'updated_by'])

        logger.warning(f"Admin {request.user.phone_number} forced status {new_status} on Enquiry {enquiry.id}")
        return Response(ProductEnquirySerializer(enquiry).data, status=status.HTTP_200_OK)
