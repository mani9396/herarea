import uuid
from django.conf import settings
from django.db import models
from django.utils import timezone
from apps.common.managers import SoftDeleteManager

class AbstractTimestampUUIDModel(models.Model):
    """
    Core base model providing immutable UUID primary key, audit creation/update timestamps,
    and soft-deletion tracking. Used directly by root identity entities (User).
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_deleted = models.BooleanField(default=False, db_index=True)
    deleted_at = models.DateTimeField(null=True, blank=True)

    objects = SoftDeleteManager()
    all_objects = models.Manager()  # Unfiltered standard queryset access

    class Meta:
        abstract = True

    def delete(self, using=None, keep_parents=False):
        """Execute soft deletion instead of permanent database removal."""
        self.is_deleted = True
        self.deleted_at = timezone.now()
        self.save(update_fields=['is_deleted', 'deleted_at', 'updated_at'])

    def hard_delete(self, using=None, keep_parents=False):
        """Permanently erase record from database table."""
        super().delete(using=using, keep_parents=keep_parents)


class AbstractBaseModel(AbstractTimestampUUIDModel):
    """
    Universal domain base model extending timestamp tracking with user actor logging
    (created_by / updated_by). Inherited by all marketplace commercial entities.
    """
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name="%(app_label)s_%(class)s_created"
    )
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name="%(app_label)s_%(class)s_updated"
    )

    class Meta:
        abstract = True
