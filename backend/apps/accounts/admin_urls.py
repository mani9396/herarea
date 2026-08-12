from django.urls import path
from apps.accounts.admin_views import (
    AdminCustomerListView,
    AdminCustomerDetailView,
    AdminActivityLogView,
    AdminAnalyticsView,
)

urlpatterns = [
    path('customers/', AdminCustomerListView.as_view(), name='admin-customer-list'),
    path('customers/<uuid:pk>/', AdminCustomerDetailView.as_view(), name='admin-customer-detail'),
    path('activity-logs/', AdminActivityLogView.as_view(), name='admin-activity-logs'),
    path('analytics/', AdminAnalyticsView.as_view(), name='admin-analytics'),
]
