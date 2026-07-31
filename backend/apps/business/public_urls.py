from django.urls import path
from apps.business.public_views import PublicStoreListView, PublicStoreDetailView

urlpatterns = [
    path('', PublicStoreListView.as_view(), name='public-store-list'),
    path('<uuid:pk>/', PublicStoreDetailView.as_view(), name='public-store-detail'),
]
