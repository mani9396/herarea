from django.urls import path
from apps.common.views import HealthCheckView

urlpatterns = [
    path('health/', HealthCheckView.as_view(), name='api-health-check'),
]
