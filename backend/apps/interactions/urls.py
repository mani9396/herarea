from django.urls import path
from apps.interactions.views import FavoriteListView, FavoriteToggleView, RecentlyViewedListView, RecentlyViewedLogView

urlpatterns = [
    path('', FavoriteListView.as_view(), name='favorite-list'),
    path('toggle/', FavoriteToggleView.as_view(), name='favorite-toggle'),
    path('recently-viewed/', RecentlyViewedListView.as_view(), name='recently-viewed-list'),
    path('recently-viewed/<uuid:store_id>/', RecentlyViewedLogView.as_view(), name='recently-viewed-log'),
]
