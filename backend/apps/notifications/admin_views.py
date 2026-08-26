import logging
from rest_framework import status, exceptions, serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema
from apps.accounts.permissions import IsAdminRole
from apps.accounts.models import User, UserRole
from apps.notifications.models import Notification, NotificationType

logger = logging.getLogger('her_area')

class AdminNotificationItemSerializer(serializers.ModelSerializer):
    target_group = serializers.SerializerMethodField()
    sent_at = serializers.SerializerMethodField()
    body = serializers.CharField(source='message', read_only=True)

    class Meta:
        model = Notification
        fields = ['id', 'title', 'body', 'target_group', 'sent_at']

    def get_target_group(self, obj) -> str:
        role = obj.recipient.role if obj.recipient else "ALL"
        if role == UserRole.VENDOR:
            return "Vendors"
        elif role == UserRole.CUSTOMER:
            return "Customers"
        return "All Users"

    def get_sent_at(self, obj) -> str:
        return obj.created_at.strftime('%b %d, %H:%M') if obj.created_at else "Just now"


class AdminNotificationListView(APIView):
    """
    Executive announcements broadcast log enumerating system notifications dispatched across HER AREA.
    """
    permission_classes = [IsAdminRole]
    serializer_class = AdminNotificationItemSerializer

    @extend_schema(summary="List Admin Broadcast Notifications & Announcements")
    def get(self, request):
        # Retrieve recent systemic broadcast alerts or general system notifications
        notifications = Notification.objects.select_related('recipient').order_by('-created_at')[:30]
        return Response(AdminNotificationItemSerializer(notifications, many=True).data, status=status.HTTP_200_OK)


class AdminNotificationBroadcastView(APIView):
    """
    Executive announcement transmitter capable of broadcasting push messaging alerts to all users,
    exclusive partner studio segments, or consumer accounts.
    """
    permission_classes = [IsAdminRole]

    @extend_schema(summary="Broadcast System Push Notification to User Segments")
    def post(self, request):
        title = request.data.get('title') or "Platform Announcement"
        body = request.data.get('body') or "Important notification from HER AREA Executive team."
        target_group = request.data.get('targetGroup') or request.data.get('target_group') or "All Users"

        query = User.objects.filter(is_active=True)
        if target_group.lower() in ['vendors', 'partner studios']:
            query = query.filter(role=UserRole.VENDOR)
        elif target_group.lower() in ['customers', 'consumers']:
            query = query.filter(role=UserRole.CUSTOMER)

        recipients = list(query[:50]) # Cap batch creation to active top 50 in real-time loop
        notifications_to_create = [
            Notification(
                recipient=user,
                title=title,
                message=body,
                notification_type=NotificationType.SYSTEM,
                is_read=False,
            )
            for user in recipients
        ]
        
        if notifications_to_create:
            Notification.objects.bulk_create(notifications_to_create)
            logger.info(f"Admin {request.user.phone_number} broadcasted announcement '{title}' to {len(recipients)} users ({target_group}).")

        return Response({
            "detail": f"Announcement successfully dispatched to {len(recipients)} targeted accounts.",
            "target_group": target_group,
            "title": title
        }, status=status.HTTP_201_CREATED)
