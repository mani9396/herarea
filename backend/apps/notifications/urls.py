from django.urls import path
from apps.notifications.views import (
    NotificationListView, 
    NotificationReadView, 
    NotificationReadAllView,
    NotificationDeleteView,
    NotificationClearAllView,
    DeviceTokenRegisterView,
    DeviceTokenUnregisterView,
    NotificationTestPushView,
)

urlpatterns = [
    path('', NotificationListView.as_view(), name='notification-list'),
    path('<uuid:pk>/read/', NotificationReadView.as_view(), name='notification-mark-read'),
    path('<uuid:pk>/delete/', NotificationDeleteView.as_view(), name='notification-delete-action'),
    path('<uuid:pk>/', NotificationDeleteView.as_view(), name='notification-delete'),
    path('read-all/', NotificationReadAllView.as_view(), name='notification-mark-read-all'),
    path('clear-all/', NotificationClearAllView.as_view(), name='notification-clear-all'),
    path('clear/', NotificationClearAllView.as_view(), name='notification-clear'),
    path('devices/register/', DeviceTokenRegisterView.as_view(), name='device-token-register'),
    path('devices/unregister/', DeviceTokenUnregisterView.as_view(), name='device-token-unregister'),
    path('test-push/', NotificationTestPushView.as_view(), name='notification-test-push'),
]
