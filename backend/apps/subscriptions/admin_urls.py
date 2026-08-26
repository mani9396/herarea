from django.urls import path
from .admin_views import (
    AdminListingPlanListCreateView, 
    AdminListingPlanDetailView,
    AdminVendorSubscriptionListView,
    AdminPaymentRecordListView,
    AdminDashboardRevenueView
)

urlpatterns = [
    path('plans/', AdminListingPlanListCreateView.as_view(), name='admin-listing-plans'),
    path('plans/<int:pk>/', AdminListingPlanDetailView.as_view(), name='admin-listing-plan-detail'),
    path('subscriptions/', AdminVendorSubscriptionListView.as_view(), name='admin-subscriptions-list'),
    path('payments/', AdminPaymentRecordListView.as_view(), name='admin-payments-list'),
    path('revenue/', AdminDashboardRevenueView.as_view(), name='admin-dashboard-revenue'),
]
