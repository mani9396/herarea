from rest_framework import serializers
from apps.notifications.models import Notification, DeviceToken

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'title', 'message', 'notification_type', 'is_read', 'action_url', 'created_at']
        read_only_fields = ['id', 'title', 'message', 'notification_type', 'action_url', 'created_at']


class DeviceTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceToken
        fields = ['token', 'platform', 'app_type']
