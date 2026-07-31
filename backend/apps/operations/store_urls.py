from django.urls import path
from apps.operations.customer_views import PublicShowroomScheduleView

urlpatterns = [
    path('<uuid:store_id>/schedules/', PublicShowroomScheduleView.as_view(), name='public-store-schedule'),
]
