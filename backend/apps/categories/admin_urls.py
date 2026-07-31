from django.urls import path
from apps.categories.admin_views import AdminCategoryListView, AdminCategoryDetailView

urlpatterns = [
    path('', AdminCategoryListView.as_view(), name='admin-category-list'),
    path('<uuid:pk>/', AdminCategoryDetailView.as_view(), name='admin-category-detail'),
]
