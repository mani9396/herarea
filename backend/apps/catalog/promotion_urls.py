from django.urls import path
from apps.catalog.public_views import PublicPromotionListView

urlpatterns = [
    path('', PublicPromotionListView.as_view(), name='public-promotion-list'),
]
