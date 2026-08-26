from django.urls import path
from apps.operations.admin_dashboard_views import AdminDashboardStatsView
from apps.operations.admin_views import (
    AdminBookingListView,
    AdminBookingStatusOverrideView,
    AdminEnquiryListView,
    AdminEnquiryStatusOverrideView
)

urlpatterns = [
    path('dashboard/stats/', AdminDashboardStatsView.as_view(), name='admin-dashboard-stats'),
    path('bookings/', AdminBookingListView.as_view(), name='admin-booking-list'),
    path('bookings/<uuid:pk>/status/', AdminBookingStatusOverrideView.as_view(), name='admin-booking-status-override'),
    path('enquiries/', AdminEnquiryListView.as_view(), name='admin-enquiry-list'),
    path('enquiries/<uuid:pk>/status/', AdminEnquiryStatusOverrideView.as_view(), name='admin-enquiry-status-override'),
]
