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


class ProductStatus(models.TextChoices):
    DRAFT = 'DRAFT', 'Draft'
    PENDING_APPROVAL = 'PENDING_APPROVAL', 'Pending Approval'
    APPROVED = 'APPROVED', 'Approved'
    REJECTED = 'REJECTED', 'Rejected'
    HIDDEN = 'HIDDEN', 'Hidden'
    SUSPENDED = 'SUSPENDED', 'Suspended'


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
    subcategory = models.ForeignKey(
        'categories.Category', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='subcategory_products',
        help_text='Sub-taxonomy classification'
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
    additional_images = models.JSONField(default=list, blank=True, help_text='Array of additional image URLs')
    is_featured = models.BooleanField(default=False, db_index=True, help_text='Highlight on studio showroom banner')
    is_active = models.BooleanField(default=True, db_index=True, help_text='Toggle public catalog availability')
    
    status = models.CharField(max_length=30, choices=ProductStatus.choices, default=ProductStatus.DRAFT, db_index=True)
    admin_remarks = models.TextField(null=True, blank=True, help_text='Feedback from admin moderation')

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


class OfferStatus(models.TextChoices):
    DRAFT = 'DRAFT', 'Draft'
    PENDING_APPROVAL = 'PENDING_APPROVAL', 'Pending Approval'
    APPROVED = 'APPROVED', 'Approved'
    REJECTED = 'REJECTED', 'Rejected'
    SUSPENDED = 'SUSPENDED', 'Suspended'
    EXPIRED = 'EXPIRED', 'Expired'


class OfferType(models.TextChoices):
    PERCENTAGE = 'PERCENTAGE', 'Percentage Discount'
    FLAT = 'FLAT', 'Flat Discount'
    SPECIAL = 'SPECIAL', 'Special Offer'
    ANNOUNCEMENT = 'ANNOUNCEMENT', 'Store Announcement'


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
    
    offer_type = models.CharField(max_length=20, choices=OfferType.choices, default=OfferType.PERCENTAGE)
    discount_value = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, help_text='Discount amount or percentage')
    
    start_date = models.DateTimeField(null=True, blank=True, help_text='Campaign start timestamp')
    end_date = models.DateTimeField(null=True, blank=True, help_text='Campaign expiration timestamp')
    
    status = models.CharField(max_length=30, choices=OfferStatus.choices, default=OfferStatus.DRAFT, db_index=True)
    admin_remarks = models.TextField(null=True, blank=True, help_text='Feedback from admin moderation')

    class Meta:
        verbose_name = 'Promotional Offer'
        verbose_name_plural = 'Promotional Offers'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.status}) — {self.business_profile.business_name}"
