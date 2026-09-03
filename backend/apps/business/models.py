from django.db import models
from apps.common.models import AbstractBaseModel
from PIL import Image
import os
from io import BytesIO
from django.core.files.base import ContentFile

class StoreStatus(models.TextChoices):
    DRAFT = 'DRAFT', 'Draft'
    PENDING_APPROVAL = 'PENDING_APPROVAL', 'Pending Approval'
    PUBLISHED = 'PUBLISHED', 'Published'
    REJECTED = 'REJECTED', 'Rejected'
    SUSPENDED = 'SUSPENDED', 'Suspended'

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
    subcategory = models.ForeignKey(
        'categories.Category',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='showrooms_as_sub',
        db_index=True,
        help_text='Specific subcategory for this studio showroom'
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
    
    # Branding Media
    logo = models.ImageField(upload_to='stores/logos/', null=True, blank=True, help_text='Studio brand emblem logo image')
    cover_image = models.ImageField(upload_to='stores/covers/', null=True, blank=True, help_text='Showroom header banner image')

    # Governance
    status = models.CharField(
        max_length=20,
        choices=StoreStatus.choices,
        default=StoreStatus.DRAFT,
        db_index=True,
        help_text='Current governance status of the store'
    )
    admin_remarks = models.TextField(
        null=True,
        blank=True,
        help_text='Feedback or rejection reasons provided by admin'
    )

    class Meta:
        verbose_name = 'Business Profile'
        verbose_name_plural = 'Business Profiles'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.business_name} ({self.city})"

    def save(self, *args, **kwargs):
        # We need to check if the image is newly uploaded before super.save() commits it
        from django.core.files.uploadedfile import UploadedFile
        from PIL import Image
        from io import BytesIO
        from django.core.files.base import ContentFile
        import os
        
        def process_image(field, max_size):
            if field and hasattr(field, 'file') and isinstance(field.file, UploadedFile):
                try:
                    img = Image.open(field.file)
                    # Use a generous max size to only resize if significantly large
                    if img.width > max_size[0] or img.height > max_size[1]:
                        img.thumbnail(max_size, Image.Resampling.LANCZOS)
                        
                        if img.mode != 'RGB':
                            img = img.convert('RGB')
                            
                        buffer = BytesIO()
                        img.save(buffer, format='JPEG', quality=85)
                        buffer.seek(0)
                        
                        # Replace the UploadedFile with the resized ContentFile
                        new_name = os.path.splitext(field.name)[0] + '.jpg'
                        field.file = ContentFile(buffer.read())
                        field.file.name = new_name
                        field.name = new_name
                        field.file.seek(0)
                    else:
                        field.file.seek(0) # Reset pointer
                except Exception:
                    try:
                        field.file.seek(0)
                    except Exception:
                        pass
                        
        process_image(self.logo, (800, 800))
        process_image(self.cover_image, (1600, 1000))

        # We now save normally, and it uploads the (possibly resized) file efficiently
        super().save(*args, **kwargs)

    @property
    def is_listing_eligible(self):
        # A store is eligible if it has an ACTIVE subscription
        return self.subscriptions.filter(status='ACTIVE').exists()

class StoreMedia(AbstractBaseModel):
    """
    Gallery images associated with a Store/BusinessProfile.
    """
    business_profile = models.ForeignKey(
        BusinessProfile,
        on_delete=models.CASCADE,
        related_name='gallery',
        db_index=True
    )
    image = models.ImageField(upload_to='stores/gallery/')
    display_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Store Media'
        verbose_name_plural = 'Store Media'
        ordering = ['display_order', '-created_at']

    def __str__(self):
        return f"Media for {self.business_profile.business_name}"
        
    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if self.image:
            try:
                self.image.open()
                img = Image.open(self.image)
                if img.format != 'JPEG' or img.width > 1200 or img.height > 1200:
                    img.thumbnail((1200, 1200), Image.Resampling.LANCZOS)
                    if img.mode != 'RGB':
                        img = img.convert('RGB')
                    buffer = BytesIO()
                    img.save(buffer, format='JPEG', quality=85)
                    self.image.save(self.image.name, ContentFile(buffer.getvalue()), save=False)
                    StoreMedia.objects.filter(pk=self.pk).update(image=self.image.name)
            except Exception:
                pass
