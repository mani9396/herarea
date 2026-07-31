from django.db import models
from django.utils.text import slugify
from apps.common.models import AbstractBaseModel

class Category(AbstractBaseModel):
    """
    Hierarchical marketplace taxonomy structure organizing partner studios, 
    showrooms, bespoke fashion catalogs, wellness experiences, and event curation.
    """
    name = models.CharField(max_length=150, db_index=True, help_text='Category Display Name')
    slug = models.SlugField(max_length=150, unique=True, db_index=True, help_text='URL-friendly unique identifier')
    description = models.TextField(null=True, blank=True, help_text='Narrative overview of this taxonomy classification')
    icon_url = models.URLField(max_length=500, null=True, blank=True, help_text='Material vector icon or illustration URI')
    parent_category = models.ForeignKey(
        'self', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='subcategories',
        help_text='Parent category for nested taxonomy hierarchies'
    )
    is_active = models.BooleanField(default=True, db_index=True, help_text='Toggle public visibility across customer and vendor apps')
    display_order = models.PositiveIntegerField(default=0, help_text='Sort hierarchy order on Customer App Home Dashboard')

    class Meta:
        verbose_name = 'Category'
        verbose_name_plural = 'Categories'
        ordering = ['display_order', 'name']

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name
