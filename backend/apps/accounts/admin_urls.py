from django.urls import path
from apps.accounts.admin_views import (
    AdminCustomerListView,
    AdminCustomerDetailView,
    AdminActivityLogView,
    AdminAnalyticsView,
)
from apps.accounts.admin_auth_views import AdminOtpRequestView, AdminOtpVerifyView

urlpatterns = [
    path('auth/request-otp/', AdminOtpRequestView.as_view(), name='admin-auth-request-otp'),
    path('auth/verify-otp/', AdminOtpVerifyView.as_view(), name='admin-auth-verify-otp'),
    path('customers/', AdminCustomerListView.as_view(), name='admin-customer-list'),
    path('customers/<uuid:pk>/', AdminCustomerDetailView.as_view(), name='admin-customer-detail'),
    path('activity-logs/', AdminActivityLogView.as_view(), name='admin-activity-logs'),
    path('analytics/', AdminAnalyticsView.as_view(), name='admin-analytics'),
]
