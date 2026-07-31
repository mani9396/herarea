from django.db import models
from apps.common.models import AbstractBaseModel

class StockStatus(models.TextChoices):
    IN_STOCK = 'IN_STOCK', 'In Stock & Available'
    OUT_OF_STOCK = 'OUT_OF_STOCK', 'Temporarily Out of Stock'
    MADE_TO_ORDER = 'MADE_TO_ORDER', 'Bespoke / Made to Order'
    PRE_ORDER = 'PRE_ORDER', 'Pre-Order Collection'


class CatalogItemType(models.TextChoices):
    PRODUCT = 'PRODUCT', 'Physical Couture & Retail Product'
    SERVICE = 'SERVICE', 'Bespoke Studio Service & Consultation'


class Product(AbstractBaseModel):
    """
    Catalog inventory offering (e.g. Designer Couture, Jewelry piece, Wellness Consultation) 
    managed by an APPROVED partner studio and discoverable by Customer App users.
    Architecture designed to gracefully accommodate both physical retail goods and bespoke studio services.
    """
    business_profile = models.ForeignKey(
        'business.BusinessProfile', 
        on_delete=models.CASCADE, 
        related_name='products',
        db_index=True,
        help_text='Partner studio showroom offering this item'
    )
    category = models.ForeignKey(
        'categories.Category', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='products',
        help_text='Taxonomy classification for structured O2O search'
    )
    item_type = models.CharField(
        max_length=20, 
        choices=CatalogItemType.choices, 
        default=CatalogItemType.PRODUCT,
        db_index=True,
        help_text='Extensible discriminator enabling coexistence of physical couture and appointment services'
    )
    name = models.CharField(max_length=200, db_index=True, help_text='Product Title or Service Consultation Name')
    description = models.TextField(help_text='Detailed material, fit, craft specifications, or service scope')
    price = models.DecimalField(max_digits=12, decimal_places=2, help_text='Standard studio retail price (INR)')
    discounted_price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True, help_text='Optional promotional pricing')
    stock_status = models.CharField(max_length=30, choices=StockStatus.choices, default=StockStatus.IN_STOCK)
    service_duration_minutes = models.PositiveIntegerField(
        null=True, 
        blank=True, 
        help_text='Duration in minutes for bespoke appointment services or wellness consultations'
    )
    image_url = models.URLField(max_length=500, help_text='Primary high-resolution photography URI')
    is_featured = models.BooleanField(default=False, db_index=True, help_text='Highlight on studio showroom banner')
    is_active = models.BooleanField(default=True, db_index=True, help_text='Toggle public catalog availability')

    class Meta:
        verbose_name = 'Catalog Item (Product / Service)'
        verbose_name_plural = 'Catalog Items (Products & Services)'
        ordering = ['-is_featured', '-created_at']

    def __str__(self):
        return f"[{self.item_type}] {self.name} — {self.business_profile.business_name}"


class GalleryImage(AbstractBaseModel):
    """
    Visual portfolio media uploaded by approved studios to showcase store ambiance, 
    craftsmanship studios, and real-life bridal transformations.
    """
    business_profile = models.ForeignKey(
        'business.BusinessProfile', 
        on_delete=models.CASCADE, 
        related_name='gallery_images',
        db_index=True
    )
    image_url = models.URLField(max_length=500, help_text='Cloud Blob Storage URI for showroom imagery')
    caption = models.CharField(max_length=255, null=True, blank=True, help_text='Short narrative descriptive caption')
    display_order = models.PositiveIntegerField(default=0, help_text='Sort sequence in showroom gallery carousel')

    class Meta:
        verbose_name = 'Gallery Image'
        verbose_name_plural = 'Gallery Images'
        ordering = ['display_order', '-created_at']

    def __str__(self):
        return f"Gallery Image ({self.id}) — {self.business_profile.business_name}"


class Offer(AbstractBaseModel):
    """
    Time-sensitive promotional promotions and discount campaigns deployed by approved studios 
    to drive footfall and client reservations.
    """
    business_profile = models.ForeignKey(
        'business.BusinessProfile', 
        on_delete=models.CASCADE, 
        related_name='offers',
        db_index=True
    )
    title = models.CharField(max_length=150, help_text='Campaign headline e.g. Monsoon Wedding Festival Deal')
    promo_code = models.CharField(max_length=50, null=True, blank=True, help_text='Alphanumeric verification voucher code')
    description = models.TextField(help_text='Terms of promotion and redemption inclusions')
    discount_percentage = models.PositiveIntegerField(null=True, blank=True, help_text='Percentage reduction e.g. 25 for 25% off')
    valid_until = models.DateTimeField(null=True, blank=True, help_text='Campaign expiration timestamp')
    is_active = models.BooleanField(default=True, db_index=True, help_text='Toggle promotion active state')

    class Meta:
        verbose_name = 'Promotional Offer'
        verbose_name_plural = 'Promotional Offers'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.promo_code}) — {self.business_profile.business_name}"
