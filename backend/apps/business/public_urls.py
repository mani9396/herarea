from django.urls import path
from apps.business.public_views import PublicStoreListView, PublicStoreDetailView, PublicStoreNearbyView

urlpatterns = [
    path('', PublicStoreListView.as_view(), name='public-store-list'),
    path('nearby/', PublicStoreNearbyView.as_view(), name='public-store-nearby'),
    path('<uuid:pk>/', PublicStoreDetailView.as_view(), name='public-store-detail'),
]
