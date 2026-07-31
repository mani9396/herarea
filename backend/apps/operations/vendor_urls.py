from django.urls import path
from apps.operations.vendor_views import (
    VendorScheduleListCreateView,
    VendorBookingListView,
    VendorBookingStatusUpdateView,
    VendorEnquiryListView,
    VendorEnquiryResponseView
)

urlpatterns = [
    path('schedules/', VendorScheduleListCreateView.as_view(), name='vendor-schedule-list-create'),
    path('bookings/', VendorBookingListView.as_view(), name='vendor-booking-list'),
    path('bookings/<uuid:pk>/status/', VendorBookingStatusUpdateView.as_view(), name='vendor-booking-status-update'),
    path('enquiries/', VendorEnquiryListView.as_view(), name='vendor-enquiry-list'),
    path('enquiries/<uuid:pk>/respond/', VendorEnquiryResponseView.as_view(), name='vendor-enquiry-respond'),
]
