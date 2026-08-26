from django.db import models
from apps.common.models import AbstractBaseModel
from rest_framework import exceptions
from django.utils import timezone
from datetime import timedelta

class Favorite(AbstractBaseModel):
    """
    Customer Wishlist & Bookmark entity:
    Allows authenticated customers to bookmark either an entire Approved Showroom Store 
    OR individual Catalog Items (both Products and Services).
    """
    user = models.ForeignKey(
        'accounts.User', 
        on_delete=models.CASCADE, 
        related_name='favorites',
        db_index=True
    )
    store = models.ForeignKey(
        'business.BusinessProfile', 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True, 
        related_name='favorited_by',
        help_text='Bookmarked partner studio showroom'
    )
    product = models.ForeignKey(
        'catalog.Product', 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True, 
        related_name='favorited_by',
        help_text='Bookmarked catalog offering (product or service)'
    )

    class Meta:
        verbose_name = 'Favorite Bookmark'
        verbose_name_plural = 'Favorite Bookmarks'
        ordering = ['-created_at']
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'store'], 
                condition=models.Q(store__isnull=False),
                name='unique_user_store_favorite'
            ),
            models.UniqueConstraint(
                fields=['user', 'product'], 
                condition=models.Q(product__isnull=False),
                name='unique_user_product_favorite'
            ),
        ]

    def clean(self):
        if not self.store and not self.product:
            raise exceptions.ValidationError("Favorite bookmark must target either a store showroom or a catalog item.")
        if self.store and self.product:
            raise exceptions.ValidationError("Bookmark cannot simultaneously reference both a store and a specific item.")

    def __str__(self):
        target = f"Store: {self.store.business_name}" if self.store else f"Item: {self.product.name}"
        return f"User {self.user.phone_number} Favorited [{target}]"


class RecentlyViewedStore(AbstractBaseModel):
    """
    Tracks stores recently visited by a customer for quick access later.
    Limited to 20 entries per customer.
    """
    user = models.ForeignKey(
        'accounts.User',
        on_delete=models.CASCADE,
        related_name='recently_viewed_stores',
        db_index=True
    )
    store = models.ForeignKey(
        'business.BusinessProfile',
        on_delete=models.CASCADE,
        related_name='viewed_by_customers',
        db_index=True
    )
    viewed_at = models.DateTimeField(auto_now=True, db_index=True)

    class Meta:
        verbose_name = 'Recently Viewed Store'
        verbose_name_plural = 'Recently Viewed Stores'
        ordering = ['-viewed_at']
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'store'],
                name='unique_user_recently_viewed_store'
            ),
        ]

    def __str__(self):
        return f"{self.user.email} viewed {self.store.business_name} at {self.viewed_at}"

class StoreVisitStatus(models.TextChoices):
    PENDING = 'PENDING', 'Pending'
    VERIFIED = 'VERIFIED', 'Verified'
    EXPIRED = 'EXPIRED', 'Expired'
    CANCELLED = 'CANCELLED', 'Cancelled'

class StoreVisit(AbstractBaseModel):
    user = models.ForeignKey(
        'accounts.User',
        on_delete=models.CASCADE,
        related_name='store_visits',
        db_index=True
    )
    store = models.ForeignKey(
        'business.BusinessProfile',
        on_delete=models.CASCADE,
        related_name='customer_visits',
        db_index=True
    )
    status = models.CharField(
        max_length=20,
        choices=StoreVisitStatus.choices,
        default=StoreVisitStatus.PENDING
    )
    verified_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = 'Store Visit'
        verbose_name_plural = 'Store Visits'
        ordering = ['-created_at']

    def __str__(self):
        return f"Visit by {self.user.email} to {self.store.business_name} ({self.status})"

    def verify_visit(self):
        now = timezone.now()
        self.status = StoreVisitStatus.VERIFIED
        self.verified_at = now
        self.expires_at = now + timedelta(hours=24)
        self.save()

    @property
    def is_review_eligible(self):
        if self.status != StoreVisitStatus.VERIFIED:
            return False
        if not self.expires_at:
            return False
        return timezone.now() <= self.expires_at


class ReviewStatus(models.TextChoices):
    PENDING = 'PENDING', 'Pending'
    APPROVED = 'APPROVED', 'Approved'
    REJECTED = 'REJECTED', 'Rejected'
    HIDDEN = 'HIDDEN', 'Hidden'
class Review(AbstractBaseModel):
    """
    Verified customer rating and narrative feedback submitted against an Approved Studio Showroom.
    Drives public social proof and dynamic O2O review scores.
    """
    user = models.ForeignKey(
        'accounts.User', 
        on_delete=models.CASCADE, 
        related_name='reviews',
        db_index=True
    )
    store = models.ForeignKey(
        'business.BusinessProfile', 
        on_delete=models.CASCADE, 
        related_name='reviews',
        db_index=True
    )
    rating = models.PositiveSmallIntegerField(help_text='Score from 1 (poor) to 5 (flawless luxury experience)')
    title = models.CharField(max_length=150, null=True, blank=True, help_text='Review summary headline')
    comment = models.TextField(help_text='Narrative appraisal of craftsmanship, ambiance, and service quality')
    is_verified_visit = models.BooleanField(default=False, help_text='True if validated via store appointment Check-In')

    visit = models.ForeignKey(
        StoreVisit,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviews'
    )
    status = models.CharField(
        max_length=20,
        choices=ReviewStatus.choices,
        default=ReviewStatus.PENDING
    )
    admin_remarks = models.TextField(null=True, blank=True)

    class Meta:
        verbose_name = 'Showroom Review & Rating'
        verbose_name_plural = 'Showroom Reviews & Ratings'
        ordering = ['-created_at']
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'store'],
                name='unique_user_store_review'
            ),
        ]

    def clean(self):
        if not (1 <= self.rating <= 5):
            raise exceptions.ValidationError({"rating": "Rating value must be strictly between 1 and 5 stars."})

    def __str__(self):
        return f"{self.rating}★ Review for {self.store.business_name} by {self.user.email}"
