from django.urls import path
from apps.catalog.public_views import (
    PublicProductListView,
    PublicProductDetailView,
    PublicStoreCatalogDossierView,
)

urlpatterns = [
    path('', PublicProductListView.as_view(), name='public-product-list'),
    path('<uuid:pk>/', PublicProductDetailView.as_view(), name='public-product-detail'),
    path('store/<uuid:store_id>/dossier/', PublicStoreCatalogDossierView.as_view(), name='public-store-catalog-dossier'),
]
