from django.urls import path
from apps.interactions.views import StoreReviewListView, CustomerReviewDetailView, StoreVisitCreateView

urlpatterns = [
    path('<uuid:store_id>/reviews/', StoreReviewListView.as_view(), name='store-review-list-create'),
    path('<uuid:store_id>/visit/', StoreVisitCreateView.as_view(), name='store-visit-create'),
    path('customer/<uuid:review_id>/', CustomerReviewDetailView.as_view(), name='customer-review-detail'),
]
