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


class PlatformType(models.TextChoices):
    ANDROID = 'ANDROID', 'Android Device'
    IOS = 'IOS', 'iOS Device'
    WEB = 'WEB', 'Web Browser'


class DeviceToken(AbstractBaseModel):
    """
    Push notification device registration token (FCM / APNs / Web Push).
    Associates an authenticated user session with a hardware or browser client.
    """
    user = models.ForeignKey(
        'accounts.User',
        on_delete=models.CASCADE,
        related_name='device_tokens',
        db_index=True
    )
    token = models.CharField(max_length=500, unique=True, help_text='Firebase Cloud Messaging registration token')
    platform = models.CharField(max_length=10, choices=PlatformType.choices, default=PlatformType.ANDROID)
    app_type = models.CharField(max_length=20, default='CUSTOMER', help_text='CUSTOMER, VENDOR, or ADMIN')
    is_active = models.BooleanField(default=True, db_index=True)

    class Meta:
        verbose_name = 'Device Token'
        verbose_name_plural = 'Device Tokens'
        indexes = [
            models.Index(fields=['user', 'is_active']),
        ]

    def __str__(self):
        return f"{self.user.email or self.user.phone_number} ({self.platform}/{self.app_type})"
