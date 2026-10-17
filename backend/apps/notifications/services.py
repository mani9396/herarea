import logging
import os
from django.conf import settings
from apps.notifications.models import Notification, NotificationType, DeviceToken

logger = logging.getLogger('her_area')

try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    HAS_FIREBASE = True
except ImportError:
    firebase_admin = None
    credentials = None
    messaging = None
    HAS_FIREBASE = False
    logger.warning("firebase_admin package is not installed. Push notifications will be disabled.")

_firebase_initialized = False

def init_firebase_admin():
    global _firebase_initialized
    if _firebase_initialized:
        return True
    if not HAS_FIREBASE:
        return False
    
    cred_path = getattr(settings, 'FIREBASE_SERVICE_ACCOUNT_KEY', None)
    if cred_path and os.path.exists(cred_path):
        try:
            if not firebase_admin._apps:
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
            _firebase_initialized = True
            logger.info("Firebase Admin SDK initialized successfully.")
            return True
        except Exception as e:
            logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
            return False
    else:
        logger.debug(f"Firebase service account file not found at: {cred_path}. Push notification dispatch will be skipped until configured.")
        return False


class NotificationEngine:
    """
    Centralized service dispatching notifications across HER AREA applications.
    Decouples event generators (Admin review, customer feedback, KYC audit) from delivery mechanics.
    """
    @classmethod
    def send_notification(cls, recipient, title, message, notification_type=NotificationType.SYSTEM, action_url=None, extra_data=None):
        if not recipient:
            return None
        notification = Notification.objects.create(
            recipient=recipient,
            title=title,
            message=message,
            notification_type=notification_type,
            action_url=action_url,
        )
        logger.info(f"Notification [{notification_type}] created for User {recipient.id}")

        # Dispatch FCM push notifications to active registered devices
        try:
            cls.dispatch_push_notification(recipient, title, message, action_url, extra_data)
        except Exception as e:
            logger.warning(f"Push notification dispatch encountered error: {e}")

        return notification

    @classmethod
    def dispatch_push_notification(cls, recipient, title, message, action_url=None, extra_data=None):
        """
        Dispatches FCM Multicast push notification to all active devices registered by the recipient.
        """
        if not init_firebase_admin():
            return

        device_tokens_qs = DeviceToken.objects.filter(user=recipient, is_active=True)
        tokens = list(device_tokens_qs.values_list('token', flat=True))
        if not tokens:
            logger.debug(f"No active device tokens found for User {recipient.id}")
            return

        payload_data = {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'action_url': str(action_url or ''),
        }
        if extra_data and isinstance(extra_data, dict):
            for k, v in extra_data.items():
                payload_data[str(k)] = str(v)

        webpush_fcm_options = None
        if action_url and str(action_url).startswith('https://'):
            webpush_fcm_options = messaging.WebpushFCMOptions(link=str(action_url))

        multicast = messaging.MulticastMessage(
            tokens=tokens,
            notification=messaging.Notification(
                title=title,
                body=message,
            ),
            data=payload_data,
            webpush=messaging.WebpushConfig(
                notification=messaging.WebpushNotification(
                    title=title,
                    body=message,
                    icon='/icons/Icon-192.png',
                ),
                fcm_options=webpush_fcm_options,
            ),
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    title=title,
                    body=message,
                    channel_id='her_area_high_importance',
                    sound='default',
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound='default',
                        badge=1,
                    ),
                ),
            ),
        )

        try:
            response = messaging.send_each_for_multicast(multicast)
            logger.info(
                f"Push notification sent to User {recipient.id}: "
                f"{response.success_count} succeeded, {response.failure_count} failed."
            )

            # Clean up stale/invalid tokens
            if response.failure_count > 0:
                invalid_tokens = []
                for idx, resp in enumerate(response.responses):
                    if not resp.success:
                        err = resp.exception
                        if err and hasattr(err, 'code') and err.code in [
                            'messaging/invalid-registration-token',
                            'messaging/registration-token-not-registered',
                        ]:
                            invalid_tokens.append(tokens[idx])
                if invalid_tokens:
                    DeviceToken.objects.filter(token__in=invalid_tokens).update(is_active=False)
                    logger.info(f"Deactivated {len(invalid_tokens)} stale FCM device tokens.")
        except Exception as e:
            logger.error(f"Failed to dispatch multicast push message: {e}")

    @classmethod
    def broadcast_promotion_to_customers(cls, promotion):
        """
        Broadcasts a personalized push notification to all active Customers
        when a new promotional card/banner is created or published by Admin.
        Message format: Hey <Name>! From HER AREA, you have a new offer: <Title>...
        """
        import threading
        from django.contrib.auth import get_user_model

        def _do_broadcast():
            try:
                User = get_user_model()
                customers = User.objects.filter(role='CUSTOMER', is_active=True)
                count = 0
                for customer in customers:
                    first_name = (customer.full_name or '').strip().split(' ')[0]
                    if not first_name and customer.email:
                        first_name = customer.email.split('@')[0].capitalize()
                    if not first_name:
                        first_name = 'there'

                    title = "HER AREA Special Offer ✨"
                    subtitle_part = f" — {promotion.subtitle}" if promotion.subtitle else ""
                    message = (
                        f"Hey {first_name}! From HER AREA, you have a special new offer: "
                        f"{promotion.title}{subtitle_part}. Tap to explore now!"
                    )

                    cls.send_notification(
                        recipient=customer,
                        title=title,
                        message=message,
                        notification_type=NotificationType.PROMOTION,
                        action_url="/",
                        extra_data={
                            'promotion_id': str(promotion.id),
                            'promotion_title': str(promotion.title),
                        }
                    )
                    count += 1
                logger.info(f"Broadcasted promotional push notification for '{promotion.title}' to {count} customer(s).")
            except Exception as e:
                logger.error(f"Failed to broadcast promotional notification: {e}")

        threading.Thread(target=_do_broadcast, daemon=True).start()

