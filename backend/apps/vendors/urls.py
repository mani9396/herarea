from django.urls import path
from apps.vendors.views import (
    VendorProfileMeView,
    VendorKycDocumentView,
    ApprovedVendorCatalogTestView,
    VendorSelfRegistrationView,
)
from apps.vendors.dashboard_views import VendorDashboardStatsView, VendorReviewListView

urlpatterns = [
    path('auth/register/', VendorSelfRegistrationView.as_view(), name='vendor-auth-register'),
    path('me/', VendorProfileMeView.as_view(), name='vendor-profile-me'),
    path('kyc/', VendorKycDocumentView.as_view(), name='vendor-kyc-documents'),
    path('catalog-check/', ApprovedVendorCatalogTestView.as_view(), name='vendor-approved-catalog-check'),
    path('dashboard/stats/', VendorDashboardStatsView.as_view(), name='vendor-dashboard-stats'),
    path('store/reviews/', VendorReviewListView.as_view(), name='vendor-store-reviews'),
]
