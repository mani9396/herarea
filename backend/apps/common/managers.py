from django.db import models
from django.utils import timezone

class SoftDeleteQuerySet(models.QuerySet):
    def delete(self):
        """Perform soft delete by marking is_deleted=True and timestamping deleted_at."""
        return self.update(is_deleted=True, deleted_at=timezone.now())
        
    def hard_delete(self):
        """Permanently remove records from database storage."""
        return super().delete()
        
    def active(self):
        """Return only non-deleted active records."""
        return self.filter(is_deleted=False)
        
    def deleted(self):
        """Return only soft-deleted records."""
        return self.filter(is_deleted=True)

class SoftDeleteManager(models.Manager):
    def get_queryset(self):
        """Default queryset excludes soft-deleted records."""
        return SoftDeleteQuerySet(self.model, using=self._db).filter(is_deleted=False)
        
    def all_with_deleted(self):
        """Return all records regardless of soft-delete status."""
        return SoftDeleteQuerySet(self.model, using=self._db)
        
    def deleted_only(self):
        """Return only soft-deleted records."""
        return SoftDeleteQuerySet(self.model, using=self._db).filter(is_deleted=True)
