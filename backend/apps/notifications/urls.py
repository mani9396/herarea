from django.urls import path
from apps.notifications.views import NotificationListView, NotificationReadView, NotificationReadAllView

urlpatterns = [
    path('', NotificationListView.as_view(), name='notification-list'),
    path('<uuid:pk>/read/', NotificationReadView.as_view(), name='notification-mark-read'),
    path('read-all/', NotificationReadAllView.as_view(), name='notification-mark-read-all'),
]
