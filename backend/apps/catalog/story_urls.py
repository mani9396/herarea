from django.urls import path
from apps.catalog.public_views import PublicStoryListView, PublicStoryDetailView

urlpatterns = [
    path('', PublicStoryListView.as_view(), name='public-story-list'),
    path('<uuid:pk>/', PublicStoryDetailView.as_view(), name='public-story-detail'),
]
