from django.urls import path
from apps.catalog.public_views import PublicBannerListView

urlpatterns = [
    path('', PublicBannerListView.as_view(), name='public-banner-list'),
]
