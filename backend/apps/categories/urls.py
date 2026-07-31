from django.urls import path
from apps.categories.views import PublicCategoryListView, PublicCategoryDetailView

urlpatterns = [
    path('', PublicCategoryListView.as_view(), name='public-category-list'),
    path('<uuid:pk>/', PublicCategoryDetailView.as_view(), name='public-category-detail'),
]
