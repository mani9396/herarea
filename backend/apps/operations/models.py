from django.db import models
from rest_framework import exceptions
from apps.common.models import AbstractBaseModel
from apps.catalog.models import CatalogItemType

class DayOfWeek(models.IntegerChoices):
    MONDAY = 0, 'Monday'
    TUESDAY = 1, 'Tuesday'
    WEDNESDAY = 2, 'Wednesday'
    THURSDAY = 3, 'Thursday'
    FRIDAY = 4, 'Friday'
    SATURDAY = 5, 'Saturday'
    SUNDAY = 6, 'Sunday'


class BookingStatus(models.TextChoices):
    PENDING = 'PENDING', 'Awaiting Studio Confirmation'
    CONFIRMED = 'CONFIRMED', 'Appointment Confirmed'
    RESCHEDULED = 'RESCHEDULED', 'Rescheduled by Studio/Client'
    REJECTED = 'REJECTED', 'Declined by Studio'
    CANCELLED = 'CANCELLED', 'Cancelled by Customer'
    COMPLETED = 'COMPLETED', 'Service Fulfilled & Completed'


class EnquiryStatus(models.TextChoices):
    OPEN = 'OPEN', 'New Customer Enquiry'
    RESPONDED = 'RESPONDED', 'Studio Responded & Quoted'
    ORDER_PLACED = 'ORDER_PLACED', 'Converted to Bespoke Order'
    CLOSED = 'CLOSED', 'Enquiry Closed'


class VendorSchedule(AbstractBaseModel):
    """
    Daily operating timings and consultation slot intervals managed by Approved Partner Studios.
    """
    business_profile = models.ForeignKey(
        'business.BusinessProfile', 
        on_delete=models.CASCADE, 
        related_name='schedules',
        db_index=True
    )
    day_of_week = models.IntegerField(choices=DayOfWeek.choices, help_text='0=Monday to 6=Sunday')
    open_time = models.TimeField(default='10:00:00', help_text='Showroom opening hour')
    close_time = models.TimeField(default='19:00:00', help_text='Showroom closing hour')
    is_closed = models.BooleanField(default=False, help_text='Toggle weekly day-off closure')
    slot_duration_minutes = models.PositiveIntegerField(default=60, help_text='Standard booking interval in minutes')

    class Meta:
        verbose_name = 'Vendor Operating Schedule'
        verbose_name_plural = 'Vendor Operating Schedules'
        ordering = ['day_of_week']
        constraints = [
            models.UniqueConstraint(fields=['business_profile', 'day_of_week'], name='unique_studio_day_schedule')
        ]

    def __str__(self):
        status = "CLOSED" if self.is_closed else f"{self.open_time} - {self.close_time}"
        return f"{self.business_profile.business_name} [{self.get_day_of_week_display()}: {status}]"


class AppointmentBooking(AbstractBaseModel):
    """
    Customer service appointment booking reservation targeting an Approved Showroom Service offering.
    Supports complete confirmation and rescheduling workflows.
    """
    customer = models.ForeignKey(
        'accounts.User', 
        on_delete=models.CASCADE, 
        related_name='appointments',
        db_index=True
    )
    business_profile = models.ForeignKey(
        'business.BusinessProfile', 
        on_delete=models.CASCADE, 
        related_name='appointments',
        db_index=True,
        help_text='Studio hosting the appointment'
    )
    service = models.ForeignKey(
        'catalog.Product', 
        on_delete=models.CASCADE, 
        related_name='appointments',
        help_text='Target catalog item (must be item_type=SERVICE)'
    )
    appointment_date = models.DateField(db_index=True)
    start_time = models.TimeField(db_index=True)
    status = models.CharField(max_length=20, choices=BookingStatus.choices, default=BookingStatus.PENDING, db_index=True)
    customer_notes = models.TextField(null=True, blank=True, help_text='Special instructions or style preferences')
    studio_feedback = models.TextField(null=True, blank=True, help_text='Vendor notes upon confirmation or reschedule')

    class Meta:
        verbose_name = 'Service Appointment Booking'
        verbose_name_plural = 'Service Appointment Bookings'
        ordering = ['-appointment_date', '-start_time']

    def clean(self):
        if self.service and self.service.item_type != CatalogItemType.SERVICE:
            raise exceptions.ValidationError({"service": "Appointment bookings must target items classified as SERVICE."})
        if self.service and self.service.business_profile != self.business_profile:
            raise exceptions.ValidationError({"business_profile": "Service does not belong to the specified showroom profile."})

    def __str__(self):
        return f"[{self.status}] {self.service.name} for {self.customer.phone_number} on {self.appointment_date} at {self.start_time}"


class ProductEnquiry(AbstractBaseModel):
    """
    Bespoke couture product enquiry and custom customization order request initiated by customers.
    Enables studio quotation, fabric consultation, and conversion to live orders.
    """
    customer = models.ForeignKey(
        'accounts.User', 
        on_delete=models.CASCADE, 
        related_name='enquiries',
        db_index=True
    )
    business_profile = models.ForeignKey(
        'business.BusinessProfile', 
        on_delete=models.CASCADE, 
        related_name='enquiries',
        db_index=True
    )
    product = models.ForeignKey(
        'catalog.Product', 
        on_delete=models.CASCADE, 
        related_name='enquiries',
        help_text='Target catalog item (must be item_type=PRODUCT)'
    )
    status = models.CharField(max_length=20, choices=EnquiryStatus.choices, default=EnquiryStatus.OPEN, db_index=True)
    message = models.TextField(help_text='Customer query regarding custom sizing, fabrics, or delivery timelines')
    target_delivery_date = models.DateField(null=True, blank=True, help_text='Desired date of custom completion')
    studio_response = models.TextField(null=True, blank=True, help_text='Studio consultation feedback & quote specifics')
    quoted_price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True, help_text='Negotiated custom order price (INR)')

    class Meta:
        verbose_name = 'Product Enquiry & Bespoke Order'
        verbose_name_plural = 'Product Enquiries & Bespoke Orders'
        ordering = ['-created_at']

    def clean(self):
        if self.product and self.product.item_type != CatalogItemType.PRODUCT:
            raise exceptions.ValidationError({"product": "Product enquiries must target items classified as PRODUCT."})
        if self.product and self.product.business_profile != self.business_profile:
            raise exceptions.ValidationError({"business_profile": "Product does not belong to the specified showroom profile."})

    def __str__(self):
        return f"[{self.status}] Enquiry on {self.product.name} by {self.customer.phone_number}"
