from django.db import models
from apps.common.models import AbstractBaseModel
from rest_framework import exceptions

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

    class Meta:
        verbose_name = 'Showroom Review & Rating'
        verbose_name_plural = 'Showroom Reviews & Ratings'
        ordering = ['-created_at']

    def clean(self):
        if not (1 <= self.rating <= 5):
            raise exceptions.ValidationError({"rating": "Rating value must be strictly between 1 and 5 stars."})

    def __str__(self):
        return f"{self.rating}★ Review for {self.store.business_name} by {self.user.phone_number}"
