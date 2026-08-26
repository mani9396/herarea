from django.urls import path
from apps.notifications.admin_views import (
    AdminNotificationBroadcastView,
    AdminNotificationListView,
)

urlpatterns = [
    path('notifications/broadcast/', AdminNotificationBroadcastView.as_view(), name='admin-notification-broadcast'),
    path('notifications/', AdminNotificationListView.as_view(), name='admin-notification-list'),
]
