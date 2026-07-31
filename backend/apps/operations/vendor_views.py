import logging
from rest_framework import status, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiParameter
from apps.vendors.permissions import IsApprovedVendor
from apps.operations.models import VendorSchedule, AppointmentBooking, ProductEnquiry
from apps.operations.serializers import (
    VendorScheduleSerializer, 
    AppointmentBookingSerializer, 
    VendorBookingStatusUpdateSerializer, 
    ProductEnquirySerializer, 
    VendorEnquiryResponseSerializer
)
from apps.notifications.services import NotificationEngine
from apps.notifications.models import NotificationType

logger = logging.getLogger('her_area')

class VendorScheduleListCreateView(APIView):
    """
    Approved Partner Studios configure daily operating hours and appointment slot duration.
    Strictly protected by IsApprovedVendor to enforce HER AREA governance.
    """
    permission_classes = [IsApprovedVendor]
    serializer_class = VendorScheduleSerializer

    def _get_store(self, request):
        if not hasattr(request.user, 'vendor_profile') or not hasattr(request.user.vendor_profile, 'business_profile'):
            raise exceptions.ValidationError("No business profile associated with your studio.")
        return request.user.vendor_profile.business_profile

    @extend_schema(summary="Get Studio Operating Schedule", responses={200: VendorScheduleSerializer(many=True)})
    def get(self, request):
        store = self._get_store(request)
        schedules = VendorSchedule.objects.filter(business_profile=store).order_by('day_of_week')
        return Response(VendorScheduleSerializer(schedules, many=True).data, status=status.HTTP_200_OK)

    @extend_schema(summary="Configure Daily Operating Schedule & Slots", request=VendorScheduleSerializer, responses={200: VendorScheduleSerializer, 201: VendorScheduleSerializer})
    def post(self, request):
        store = self._get_store(request)
        serializer = VendorScheduleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        day_of_week = serializer.validated_data['day_of_week']
        open_time = serializer.validated_data.get('open_time', '10:00:00')
        close_time = serializer.validated_data.get('close_time', '19:00:00')
        is_closed = serializer.validated_data.get('is_closed', False)
        slot_duration = serializer.validated_data.get('slot_duration_minutes', 60)

        schedule, created = VendorSchedule.objects.update_or_create(
            business_profile=store,
            day_of_week=day_of_week,
            defaults={
                'open_time': open_time,
                'close_time': close_time,
                'is_closed': is_closed,
                'slot_duration_minutes': slot_duration,
                'created_by': request.user,
                'updated_by': request.user
            }
        )
        status_code = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        logger.info(f"Vendor {request.user.phone_number} updated schedule for Day {day_of_week} at {store.business_name}")
        return Response(VendorScheduleSerializer(schedule).data, status=status_code)


class VendorBookingListView(APIView):
    """
    Vendor Booking Dashboard: Enumerate upcoming service appointments and filter by status.
    Protected strictly by IsApprovedVendor.
    """
    permission_classes = [IsApprovedVendor]
    serializer_class = AppointmentBookingSerializer

    @extend_schema(
        summary="Vendor Appointment Booking Dashboard",
        parameters=[OpenApiParameter(name='status', description="Filter by status (PENDING, CONFIRMED, RESCHEDULED, REJECTED, COMPLETED)", required=False, type=str)],
        responses={200: AppointmentBookingSerializer(many=True)}
    )
    def get(self, request):
        store = request.user.vendor_profile.business_profile
        bookings = AppointmentBooking.objects.filter(business_profile=store).select_related('service', 'customer', 'business_profile').order_by('-appointment_date', '-start_time')
        stat = request.query_params.get('status')
        if stat:
            bookings = bookings.filter(status__iexact=stat)
        return Response(AppointmentBookingSerializer(bookings, many=True).data, status=status.HTTP_200_OK)


class VendorBookingStatusUpdateView(APIView):
    """
    Studio Owner accepts (CONFIRMED), reschedules (RESCHEDULED), declines (REJECTED), 
    or completes (COMPLETED) an appointment, triggering real-time customer notifications!
    """
    permission_classes = [IsApprovedVendor]
    serializer_class = VendorBookingStatusUpdateSerializer

    @extend_schema(summary="Update Appointment Status & Feedback", request=VendorBookingStatusUpdateSerializer, responses={200: AppointmentBookingSerializer})
    def patch(self, request, pk):
        store = request.user.vendor_profile.business_profile
        try:
            booking = AppointmentBooking.objects.select_related('customer', 'service', 'business_profile').get(pk=pk, business_profile=store)
        except AppointmentBooking.DoesNotExist:
            raise exceptions.NotFound("Appointment booking not found in your studio dashboard.")

        serializer = VendorBookingStatusUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        new_status = serializer.validated_data['status']
        feedback = serializer.validated_data.get('studio_feedback', '')

        booking.status = new_status
        if feedback:
            booking.studio_feedback = feedback
        booking.updated_by = request.user
        booking.save(update_fields=['status', 'studio_feedback', 'updated_by'])

        logger.info(f"Vendor {request.user.phone_number} updated appointment {booking.id} to {new_status}")

        NotificationEngine.send_notification(
            recipient=booking.customer,
            title=f"Appointment Status Update: {new_status}",
            message=f"Your appointment for '{booking.service.name}' at '{store.business_name}' is now {new_status}. {feedback}",
            notification_type=NotificationType.SYSTEM,
            action_url="/user/appointments"
        )
        return Response(AppointmentBookingSerializer(booking).data, status=status.HTTP_200_OK)


class VendorEnquiryListView(APIView):
    """
    Vendor Enquiries & Bespoke Orders Queue: Enumerate customer product customization requests.
    Protected strictly by IsApprovedVendor.
    """
    permission_classes = [IsApprovedVendor]
    serializer_class = ProductEnquirySerializer

    @extend_schema(summary="Vendor Bespoke Couture Enquiries Queue", responses={200: ProductEnquirySerializer(many=True)})
    def get(self, request):
        store = request.user.vendor_profile.business_profile
        enquiries = ProductEnquiry.objects.filter(business_profile=store).select_related('product', 'customer', 'business_profile').order_by('-created_at')
        return Response(ProductEnquirySerializer(enquiries, many=True).data, status=status.HTTP_200_OK)


class VendorEnquiryResponseView(APIView):
    """
    Studio submits pricing quotation (quoted_price) and consultation readiness (studio_response),
    transitioning state to RESPONDED or ORDER_PLACED with instant customer alert!
    """
    permission_classes = [IsApprovedVendor]
    serializer_class = VendorEnquiryResponseSerializer

    @extend_schema(summary="Respond to Couture Enquiry & Submit Quote", request=VendorEnquiryResponseSerializer, responses={200: ProductEnquirySerializer})
    def patch(self, request, pk):
        store = request.user.vendor_profile.business_profile
        try:
            enquiry = ProductEnquiry.objects.select_related('customer', 'product', 'business_profile').get(pk=pk, business_profile=store)
        except ProductEnquiry.DoesNotExist:
            raise exceptions.NotFound("Product enquiry not found in your studio dashboard.")

        serializer = VendorEnquiryResponseSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        enquiry.status = serializer.validated_data.get('status', enquiry.status)
        enquiry.studio_response = serializer.validated_data.get('studio_response', enquiry.studio_response)
        if 'quoted_price' in serializer.validated_data:
            enquiry.quoted_price = serializer.validated_data['quoted_price']
        enquiry.updated_by = request.user
        enquiry.save()

        logger.info(f"Vendor {request.user.phone_number} responded to enquiry {enquiry.id} with status {enquiry.status}")

        NotificationEngine.send_notification(
            recipient=enquiry.customer,
            title=f"Studio Responded to Couture Enquiry!",
            message=f"Studio '{store.business_name}' sent a price quote and response for '{enquiry.product.name}': {enquiry.studio_response}",
            notification_type=NotificationType.SYSTEM,
            action_url="/user/enquiries"
        )
        return Response(ProductEnquirySerializer(enquiry).data, status=status.HTTP_200_OK)
