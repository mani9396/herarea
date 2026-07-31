import logging
from apps.notifications.models import Notification, NotificationType

logger = logging.getLogger('her_area')

class NotificationEngine:
    """
    Centralized service dispatching notifications across HER AREA applications.
    Decouples event generators (Admin review, customer feedback, KYC audit) from delivery mechanics.
    """
    @classmethod
    def send_notification(cls, recipient, title, message, notification_type=NotificationType.SYSTEM, action_url=None):
        if not recipient:
            return None
        notification = Notification.objects.create(
            recipient=recipient,
            title=title,
            message=message,
            notification_type=notification_type,
            action_url=action_url
        )
        logger.info(f"Notification [{notification_type}] dispatched to User {recipient.id} ({title})")
        return notification
