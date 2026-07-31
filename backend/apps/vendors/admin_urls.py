from django.urls import path
from apps.vendors.admin_views import (
    AdminPendingVendorsListView,
    AdminVendorDetailView,
    AdminVendorApproveView,
    AdminVendorRejectView,
    AdminVendorSuspendView,
)

urlpatterns = [
    path('pending/', AdminPendingVendorsListView.as_view(), name='admin-vendors-pending-list'),
    path('<uuid:pk>/', AdminVendorDetailView.as_view(), name='admin-vendor-detail'),
    path('<uuid:pk>/approve/', AdminVendorApproveView.as_view(), name='admin-vendor-approve'),
    path('<uuid:pk>/reject/', AdminVendorRejectView.as_view(), name='admin-vendor-reject'),
    path('<uuid:pk>/suspend/', AdminVendorSuspendView.as_view(), name='admin-vendor-suspend'),
]
