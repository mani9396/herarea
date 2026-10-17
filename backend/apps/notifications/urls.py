from django.urls import path
from apps.notifications.views import (
    NotificationListView, 
    NotificationReadView, 
    NotificationReadAllView,
    DeviceTokenRegisterView,
    DeviceTokenUnregisterView,
    NotificationTestPushView,
)

urlpatterns = [
    path('', NotificationListView.as_view(), name='notification-list'),
    path('<uuid:pk>/read/', NotificationReadView.as_view(), name='notification-mark-read'),
    path('read-all/', NotificationReadAllView.as_view(), name='notification-mark-read-all'),
    path('devices/register/', DeviceTokenRegisterView.as_view(), name='device-token-register'),
    path('devices/unregister/', DeviceTokenUnregisterView.as_view(), name='device-token-unregister'),
    path('test-push/', NotificationTestPushView.as_view(), name='notification-test-push'),
]
