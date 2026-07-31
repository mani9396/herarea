from django.urls import path
from apps.interactions.views import FavoriteListView, FavoriteToggleView

urlpatterns = [
    path('', FavoriteListView.as_view(), name='favorite-list'),
    path('toggle/', FavoriteToggleView.as_view(), name='favorite-toggle'),
]
