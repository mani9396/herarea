from rest_framework import serializers
from apps.operations.models import VendorSchedule, AppointmentBooking, ProductEnquiry, BookingStatus, EnquiryStatus
from apps.catalog.models import CatalogItemType

class VendorScheduleSerializer(serializers.ModelSerializer):
    day_name = serializers.CharField(source='get_day_of_week_display', read_only=True)

    class Meta:
        model = VendorSchedule
        fields = ['id', 'day_of_week', 'day_name', 'open_time', 'close_time', 'is_closed', 'slot_duration_minutes', 'created_at']
        read_only_fields = ['id', 'day_name', 'created_at']


class AppointmentBookingSerializer(serializers.ModelSerializer):
    service_name = serializers.CharField(source='service.name', read_only=True)
    service_price = serializers.DecimalField(source='service.price', max_digits=12, decimal_places=2, read_only=True)
    service_duration_minutes = serializers.IntegerField(source='service.service_duration_minutes', read_only=True)
    store_name = serializers.CharField(source='business_profile.business_name', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone_number', read_only=True)
    business_profile = serializers.UUIDField(source='business_profile.id', read_only=True)

    class Meta:
        model = AppointmentBooking
        fields = [
            'id', 'service', 'service_name', 'service_price', 'service_duration_minutes',
            'business_profile', 'store_name', 'customer_phone',
            'appointment_date', 'start_time', 'status', 
            'customer_notes', 'studio_feedback', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'business_profile', 'store_name', 'service_name', 
            'service_price', 'service_duration_minutes', 'status', 
            'studio_feedback', 'customer_phone', 'created_at', 'updated_at'
        ]

    def validate_service(self, service):
        if service.item_type != CatalogItemType.SERVICE:
            raise serializers.ValidationError("Target item is not classified as an appointment service.")
        if not service.is_active or service.business_profile.vendor.status != 'APPROVED':
            raise serializers.ValidationError("Target studio or service is not active.")
        return service


class VendorBookingStatusUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = AppointmentBooking
        fields = ['status', 'studio_feedback']

    def validate_status(self, value):
        if value not in [BookingStatus.CONFIRMED, BookingStatus.REJECTED, BookingStatus.RESCHEDULED, BookingStatus.COMPLETED]:
            raise serializers.ValidationError("Invalid status transition for vendor.")
        return value


class ProductEnquirySerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_price = serializers.DecimalField(source='product.price', max_digits=12, decimal_places=2, read_only=True)
    product_image_url = serializers.URLField(source='product.image_url', read_only=True)
    store_name = serializers.CharField(source='business_profile.business_name', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone_number', read_only=True)
    business_profile = serializers.UUIDField(source='business_profile.id', read_only=True)

    class Meta:
        model = ProductEnquiry
        fields = [
            'id', 'product', 'product_name', 'product_price', 'product_image_url',
            'business_profile', 'store_name', 'customer_phone',
            'status', 'message', 'target_delivery_date',
            'studio_response', 'quoted_price', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'business_profile', 'store_name', 'product_name', 
            'product_price', 'product_image_url', 'status', 'studio_response', 
            'quoted_price', 'customer_phone', 'created_at', 'updated_at'
        ]

    def validate_product(self, product):
        if product.item_type != CatalogItemType.PRODUCT:
            raise serializers.ValidationError("Target item is not classified as a physical couture product.")
        if not product.is_active or product.business_profile.vendor.status != 'APPROVED':
            raise serializers.ValidationError("Target studio or product is not currently active.")
        return product


class VendorEnquiryResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductEnquiry
        fields = ['status', 'studio_response', 'quoted_price']
