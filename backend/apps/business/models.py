from django.db import models
from apps.common.models import AbstractBaseModel

class BusinessProfile(AbstractBaseModel):
    """
    Public showroom identity, operational contact details, location address, and business timings 
    associated with a partner studio vendor. Evaluated during admin approval before going public.
    """
    vendor = models.OneToOneField(
        'vendors.VendorProfile', 
        on_delete=models.CASCADE, 
        related_name='business_profile',
        db_index=True,
        help_text='Partner vendor owning this showroom profile'
    )
    category = models.ForeignKey(
        'categories.Category',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='showrooms',
        db_index=True,
        help_text='Primary marketplace taxonomy category for this studio showroom'
    )
    business_name = models.CharField(max_length=200, db_index=True, help_text='Official Brand or Studio Showroom Name')
    description = models.TextField(null=True, blank=True, help_text='Detailed narrative of studio specialty and offerings')
    
    # Physical Location & Address
    address_line_1 = models.CharField(max_length=255, help_text='Street number, building, complex name')
    address_line_2 = models.CharField(max_length=255, null=True, blank=True, help_text='Floor, landmark, neighborhood')
    area = models.CharField(max_length=100, help_text='Sub-locality or specific neighborhood zone')
    city = models.CharField(max_length=100, db_index=True)
    state = models.CharField(max_length=100)
    country = models.CharField(max_length=100, default='India')
    postal_code = models.CharField(max_length=20, db_index=True)
    
    # Public Contact & Support
    contact_email = models.EmailField(help_text='Public customer inquiry support email')
    contact_phone = models.CharField(max_length=20, help_text='Public studio concierge or booking number')
    
    # Geolocation Coordinates
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True, help_text='GPS Latitude coordinates')
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True, help_text='GPS Longitude coordinates')
    
    # Business Timings Configuration
    business_timings = models.JSONField(
        default=dict, 
        help_text='Daily operation hour schedules (e.g. {"Monday": "10:00 - 20:00", "Saturday": "Closed"})'
    )
    
    # Branding Media URIs
    logo_url = models.URLField(max_length=500, null=True, blank=True, help_text='Studio brand emblem logo URL')
    cover_url = models.URLField(max_length=500, null=True, blank=True, help_text='Showroom header banner image URL')

    class Meta:
        verbose_name = 'Business Profile'
        verbose_name_plural = 'Business Profiles'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.business_name} ({self.city})"
