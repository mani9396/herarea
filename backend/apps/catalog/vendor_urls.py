from django.urls import path
from apps.catalog.vendor_views import (
    VendorProductListView,
    VendorProductDetailView,
    VendorGalleryListView,
    VendorGalleryDetailView,
    VendorOfferListView,
    VendorOfferDetailView,
)

urlpatterns = [
    path('products/', VendorProductListView.as_view(), name='vendor-catalog-product-list'),
    path('products/<uuid:pk>/', VendorProductDetailView.as_view(), name='vendor-catalog-product-detail'),
    path('gallery/', VendorGalleryListView.as_view(), name='vendor-catalog-gallery-list'),
    path('gallery/<uuid:pk>/', VendorGalleryDetailView.as_view(), name='vendor-catalog-gallery-detail'),
    path('offers/', VendorOfferListView.as_view(), name='vendor-catalog-offer-list'),
    path('offers/<uuid:pk>/', VendorOfferDetailView.as_view(), name='vendor-catalog-offer-detail'),
]
