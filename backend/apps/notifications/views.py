import logging
from rest_framework import status, permissions, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiResponse
from apps.notifications.models import Notification, DeviceToken
from apps.notifications.serializers import NotificationSerializer, DeviceTokenSerializer

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

    def post(self, request, pk):
        return self.patch(request, pk)


class NotificationDeleteView(APIView):
    """Delete an individual notification record for authenticated user."""
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(summary="Delete Notification", responses={200: OpenApiResponse(description="Notification deleted.")})
    def delete(self, request, pk):
        try:
            notification = Notification.objects.get(pk=pk, recipient=request.user)
        except Notification.DoesNotExist:
            raise exceptions.NotFound("Notification record not found.")
        
        notification.delete()
        return Response({"status": "success", "message": "Notification deleted successfully."}, status=status.HTTP_200_OK)

    def post(self, request, pk):
        return self.delete(request, pk)


class NotificationClearAllView(APIView):
    """Delete all notifications for authenticated user."""
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(summary="Clear All Notifications", responses={200: OpenApiResponse(description="All notifications cleared.")})
    def post(self, request):
        count, _ = Notification.objects.filter(recipient=request.user).delete()
        logger.info(f"User {request.user.email or request.user.phone_number} cleared {count} notifications.")
        return Response({"status": "success", "cleared_count": count}, status=status.HTTP_200_OK)

    def delete(self, request):
        return self.post(request)


class NotificationReadAllView(APIView):
    """Bulk mark all outstanding alerts as read for authenticated user."""
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(summary="Mark All Notifications as Read", responses={200: None})
    def post(self, request):
        count = Notification.objects.filter(recipient=request.user, is_read=False).update(is_read=True)
        logger.info(f"User {request.user.phone_number} marked {count} notifications as read.")
        return Response({"status": "success", "marked_read_count": count}, status=status.HTTP_200_OK)


class DeviceTokenRegisterView(APIView):
    """Register or update an FCM device token for push notifications."""
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Register Device Push Token",
        request=DeviceTokenSerializer,
        responses={200: OpenApiResponse(description="Token registered successfully.")}
    )
    def post(self, request):
        serializer = DeviceTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        token = serializer.validated_data['token']
        platform = serializer.validated_data.get('platform', 'ANDROID')
        app_type = serializer.validated_data.get('app_type', 'CUSTOMER')

        device_token, created = DeviceToken.objects.update_or_create(
            token=token,
            defaults={
                'user': request.user,
                'platform': platform,
                'app_type': app_type,
                'is_active': True,
            }
        )
        logger.info(f"FCM Token {'registered' if created else 'updated'} for {request.user.email or request.user.phone_number} ({platform}/{app_type})")
        return Response({"status": "success", "message": "Device registered for push notifications."}, status=status.HTTP_200_OK)


from apps.notifications.services import NotificationEngine

class DeviceTokenUnregisterView(APIView):
    """Deactivate an FCM device token on user logout."""
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Unregister Device Push Token",
        request=DeviceTokenSerializer,
        responses={200: OpenApiResponse(description="Token unregistered.")}
    )
    def post(self, request):
        token = request.data.get('token')
        if token:
            DeviceToken.objects.filter(token=token, user=request.user).update(is_active=False)
            logger.info(f"FCM Token deactivated for {request.user.email or request.user.phone_number}")
        return Response({"status": "success", "message": "Device token deactivated."}, status=status.HTTP_200_OK)


class NotificationTestPushView(APIView):
    """Trigger an instant test push notification to the calling user's active devices."""
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Send Test Push Notification",
        responses={200: OpenApiResponse(description="Push notification dispatched.")}
    )
    def post(self, request):
        title = request.data.get('title', 'HER AREA Test Notification 🔔')
        message = request.data.get('message', 'Push notifications are working perfectly on your device!')
        action_url = request.data.get('action_url', '/home')
        notification = NotificationEngine.send_notification(
            recipient=request.user,
            title=title,
            message=message,
            action_url=action_url,
        )
        return Response({
            "status": "success",
            "message": "Push notification dispatched.",
            "notification_id": notification.id if notification else None,
        }, status=status.HTTP_200_OK)

