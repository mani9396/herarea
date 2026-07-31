from django.urls import path
from apps.interactions.views import StoreReviewListView

urlpatterns = [
    path('<uuid:store_id>/reviews/', StoreReviewListView.as_view(), name='store-review-list-create'),
]
