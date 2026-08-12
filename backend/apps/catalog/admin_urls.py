from django.urls import path
from apps.catalog.admin_views import (
    AdminProductListView,
    AdminProductDetailView,
    AdminOfferListView,
    AdminOfferDetailView,
    AdminGalleryListView,
    AdminGalleryDetailView,
)

urlpatterns = [
    path('products/', AdminProductListView.as_view(), name='admin-product-list'),
    path('products/<uuid:pk>/', AdminProductDetailView.as_view(), name='admin-product-detail'),
    path('offers/', AdminOfferListView.as_view(), name='admin-offer-list'),
    path('offers/<uuid:pk>/', AdminOfferDetailView.as_view(), name='admin-offer-detail'),
    path('gallery/', AdminGalleryListView.as_view(), name='admin-gallery-list'),
    path('gallery/<uuid:pk>/', AdminGalleryDetailView.as_view(), name='admin-gallery-detail'),
]
