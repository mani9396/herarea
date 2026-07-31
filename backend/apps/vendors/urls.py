from django.urls import path
from apps.vendors.views import (
    VendorRegistrationView,
    VendorProfileMeView,
    VendorKycDocumentView,
    ApprovedVendorCatalogTestView,
)

urlpatterns = [
    path('register/', VendorRegistrationView.as_view(), name='vendor-onboarding-register'),
    path('me/', VendorProfileMeView.as_view(), name='vendor-profile-me'),
    path('kyc/', VendorKycDocumentView.as_view(), name='vendor-kyc-documents'),
    path('catalog-check/', ApprovedVendorCatalogTestView.as_view(), name='vendor-approved-catalog-check'),
]
