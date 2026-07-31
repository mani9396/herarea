from django.urls import path
from apps.operations.customer_views import (
    CustomerBookingListCreateView, 
    CustomerBookingCancelView, 
    CustomerEnquiryListCreateView
)

urlpatterns = [
    path('bookings/', CustomerBookingListCreateView.as_view(), name='customer-booking-list-create'),
    path('bookings/<uuid:pk>/cancel/', CustomerBookingCancelView.as_view(), name='customer-booking-cancel'),
    path('enquiries/', CustomerEnquiryListCreateView.as_view(), name='customer-enquiry-list-create'),
]
