import logging
from rest_framework import status, permissions, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiParameter
from apps.operations.models import AppointmentBooking, ProductEnquiry, VendorSchedule, BookingStatus
from apps.operations.serializers import AppointmentBookingSerializer, ProductEnquirySerializer, VendorScheduleSerializer
from apps.business.models import BusinessProfile
from apps.vendors.models import VendorStatus
from apps.notifications.services import NotificationEngine
from apps.notifications.models import NotificationType

logger = logging.getLogger('her_area')

class CustomerBookingListCreateView(APIView):
    """Customer discovery and reservation of Bespoke Service Appointments with Approved Partner Studios."""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = AppointmentBookingSerializer

    @extend_schema(
        summary="List Customer Service Appointments",
        parameters=[OpenApiParameter(name='status', description="Filter by BookingStatus (e.g. PENDING, CONFIRMED)", required=False, type=str)],
        responses={200: AppointmentBookingSerializer(many=True)}
    )
    def get(self, request):
        bookings = AppointmentBooking.objects.filter(customer=request.user).select_related('service', 'business_profile', 'customer').order_by('-appointment_date', '-start_time')
        stat_filter = request.query_params.get('status')
        if stat_filter:
            bookings = bookings.filter(status__iexact=stat_filter)
        return Response(AppointmentBookingSerializer(bookings, many=True).data, status=status.HTTP_200_OK)

    @extend_schema(summary="Reserve Service Appointment with Studio", request=AppointmentBookingSerializer, responses={201: AppointmentBookingSerializer})
    def post(self, request):
        serializer = AppointmentBookingSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        service = serializer.validated_data['service']
        store = service.business_profile
        
        booking = serializer.save(
            customer=request.user, 
            business_profile=store, 
            status=BookingStatus.PENDING,
            created_by=request.user, 
            updated_by=request.user
        )

        logger.info(f"Customer {request.user.phone_number} booked appointment for {service.name} at {store.business_name}")

        # Dispatch real-time alert to Studio Owner!
        NotificationEngine.send_notification(
            recipient=store.vendor.user,
            title="New Appointment Booking Request!",
            message=f"New appointment request for '{service.name}' on {booking.appointment_date} at {booking.start_time}.",
            notification_type=NotificationType.SYSTEM,
            action_url="/vendor/bookings"
        )
        return Response(AppointmentBookingSerializer(booking).data, status=status.HTTP_201_CREATED)


class CustomerBookingCancelView(APIView):
    """Allow customer to cancel an un-fulfilled service appointment with automatic studio notification."""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = AppointmentBookingSerializer

    @extend_schema(summary="Cancel Customer Appointment Booking", responses={200: AppointmentBookingSerializer})
    def patch(self, request, pk):
        try:
            booking = AppointmentBooking.objects.select_related('business_profile__vendor__user', 'service').get(pk=pk, customer=request.user)
        except AppointmentBooking.DoesNotExist:
            raise exceptions.NotFound("Target appointment booking not found.")

        if booking.status in [BookingStatus.COMPLETED, BookingStatus.CANCELLED]:
            raise exceptions.ValidationError("Cannot cancel an already completed or cancelled appointment.")

        booking.status = BookingStatus.CANCELLED
        booking.updated_by = request.user
        booking.save(update_fields=['status', 'updated_by'])

        logger.warning(f"Appointment {booking.id} cancelled by customer {request.user.phone_number}")

        NotificationEngine.send_notification(
            recipient=booking.business_profile.vendor.user,
            title="Appointment Cancelled by Client",
            message=f"Customer cancelled their consultation for '{booking.service.name}' scheduled on {booking.appointment_date}.",
            notification_type=NotificationType.SYSTEM,
            action_url="/vendor/bookings"
        )
        return Response(AppointmentBookingSerializer(booking).data, status=status.HTTP_200_OK)


class CustomerEnquiryListCreateView(APIView):
    """Customer submissions and history of Bespoke Couture Product Enquiries and customization orders."""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ProductEnquirySerializer

    @extend_schema(summary="List Customer Couture Enquiries & Bespoke Orders", responses={200: ProductEnquirySerializer(many=True)})
    def get(self, request):
        enquiries = ProductEnquiry.objects.filter(customer=request.user).select_related('product', 'business_profile', 'customer').order_by('-created_at')
        return Response(ProductEnquirySerializer(enquiries, many=True).data, status=status.HTTP_200_OK)

    @extend_schema(summary="Submit Couture Product Enquiry & Customization Order", request=ProductEnquirySerializer, responses={201: ProductEnquirySerializer})
    def post(self, request):
        serializer = ProductEnquirySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        product = serializer.validated_data['product']
        store = product.business_profile

        enquiry = serializer.save(
            customer=request.user, 
            business_profile=store, 
            created_by=request.user, 
            updated_by=request.user
        )

        logger.info(f"Customer {request.user.phone_number} submitted enquiry on {product.name} to {store.business_name}")

        NotificationEngine.send_notification(
            recipient=store.vendor.user,
            title="New Couture Product Enquiry!",
            message=f"Customer submitted customization enquiry for '{product.name}': '{enquiry.message}'",
            notification_type=NotificationType.SYSTEM,
            action_url="/vendor/enquiries"
        )
        return Response(ProductEnquirySerializer(enquiry).data, status=status.HTTP_201_CREATED)


class PublicShowroomScheduleView(APIView):
    """Public view to discover operating timings and consultation intervals for Approved Showrooms."""
    permission_classes = [permissions.AllowAny]
    serializer_class = VendorScheduleSerializer

    @extend_schema(summary="Get Showroom Daily Operating Schedule", responses={200: VendorScheduleSerializer(many=True)})
    def get(self, request, store_id):
        try:
            store = BusinessProfile.objects.get(pk=store_id, vendor__status=VendorStatus.APPROVED)
        except BusinessProfile.DoesNotExist:
            raise exceptions.NotFound("Showroom not found or awaiting administrative approval.")

        schedules = VendorSchedule.objects.filter(business_profile=store).order_by('day_of_week')
        return Response(VendorScheduleSerializer(schedules, many=True).data, status=status.HTTP_200_OK)
