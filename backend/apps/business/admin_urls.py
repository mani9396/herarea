from django.urls import path
from apps.business.admin_views import (
    AdminStoreListView,
    AdminStoreApproveView,
    AdminStoreRejectView,
    AdminStoreSuspendView,
    AdminStoreApplicationDossierView,
)

urlpatterns = [
    path('stores/', AdminStoreListView.as_view(), name='admin-store-list'),
    path('stores/<uuid:pk>/dossier/', AdminStoreApplicationDossierView.as_view(), name='admin-store-dossier'),
    path('stores/<uuid:pk>/approve/', AdminStoreApproveView.as_view(), name='admin-store-approve'),
    path('stores/<uuid:pk>/reject/', AdminStoreRejectView.as_view(), name='admin-store-reject'),
    path('stores/<uuid:pk>/suspend/', AdminStoreSuspendView.as_view(), name='admin-store-suspend'),
]
