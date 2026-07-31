import logging
from rest_framework import status, permissions, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiParameter
from apps.notifications.models import Notification
from apps.notifications.serializers import NotificationSerializer

logger = logging.getLogger('her_area')

class NotificationListView(APIView):
    """Retrieve chronologically sorted alert notification feed for authenticated user."""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationSerializer

    @extend_schema(
        summary="List User Notifications",
        parameters=[OpenApiParameter(name='unread', description="Filter to unread only (true/false)", required=False, type=str)],
        responses={200: NotificationSerializer(many=True)}
    )
    def get(self, request):
        qs = Notification.objects.filter(recipient=request.user)
        if request.query_params.get('unread', '').lower() in ['true', '1', 'yes']:
            qs = qs.filter(is_read=False)
        qs = qs.order_by('-created_at')
        return Response(NotificationSerializer(qs, many=True).data, status=status.HTTP_200_OK)


class NotificationReadView(APIView):
    """Mark a specific notification item as read when clicked in UI drawer."""
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(summary="Mark Notification as Read", responses={200: NotificationSerializer})
    def patch(self, request, pk):
        try:
            notification = Notification.objects.get(pk=pk, recipient=request.user)
        except Notification.DoesNotExist:
            raise exceptions.NotFound("Notification record not found.")
        
        notification.is_read = True
        notification.save(update_fields=['is_read', 'updated_at'])
        return Response(NotificationSerializer(notification).data, status=status.HTTP_200_OK)


class NotificationReadAllView(APIView):
    """Bulk mark all outstanding alerts as read for authenticated user."""
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(summary="Mark All Notifications as Read", responses={200: None})
    def post(self, request):
        count = Notification.objects.filter(recipient=request.user, is_read=False).update(is_read=True)
        logger.info(f"User {request.user.phone_number} marked {count} notifications as read.")
        return Response({"status": "success", "marked_read_count": count}, status=status.HTTP_200_OK)
