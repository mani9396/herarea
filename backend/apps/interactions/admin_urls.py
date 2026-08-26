from django.urls import path
from apps.interactions.admin_views import (
    AdminReviewListView,
    AdminReviewDetailView,
)

urlpatterns = [
    path('reviews/', AdminReviewListView.as_view(), name='admin-review-list'),
    path('reviews/<uuid:pk>/', AdminReviewDetailView.as_view(), name='admin-review-detail'),
]
