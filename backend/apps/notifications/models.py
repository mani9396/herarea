from django.db import models
from apps.common.models import AbstractBaseModel

class NotificationType(models.TextChoices):
    SYSTEM = 'SYSTEM', 'Platform System Message'
    ONBOARDING = 'ONBOARDING', 'Studio Onboarding & Governance'
    REVIEW = 'REVIEW', 'Customer Review & Rating Alert'
    PROMOTION = 'PROMOTION', 'Promotional Offer & Discount Campaign'
    SECURITY = 'SECURITY', 'Authentication & Security Alert'


class Notification(AbstractBaseModel):
    """
    Real-time platform alert message delivered to Customers, Partner Studios, or Admins.
    Supports activity tracking, deep link routing, and unread badge counting.
    """
    recipient = models.ForeignKey(
        'accounts.User', 
        on_delete=models.CASCADE, 
        related_name='notifications',
        db_index=True,
        help_text='User account targeted by this notification'
    )
    title = models.CharField(max_length=200, help_text='Headline e.g. Studio Onboarding Approved!')
    message = models.TextField(help_text='Full narrative message body')
    notification_type = models.CharField(
        max_length=30, 
        choices=NotificationType.choices, 
        default=NotificationType.SYSTEM,
        db_index=True
    )
    is_read = models.BooleanField(default=False, db_index=True, help_text='Tracks read/unread state for UI badges')
    action_url = models.CharField(
        max_length=255, 
        null=True, 
        blank=True, 
        help_text='Optional internal navigation deep link e.g. /vendor/profile or /store/details/<id>'
    )

    class Meta:
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.notification_type}] To: {self.recipient.phone_number} — {self.title}"
