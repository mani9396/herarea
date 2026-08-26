from django.urls import path
from apps.business.views import VendorBusinessProfileView, VendorStoreMediaListView, VendorStoreMediaDetailView, VendorStoreSubmitView

urlpatterns = [
    path('me/', VendorBusinessProfileView.as_view(), name='business-profile-me'),
    path('me/submit/', VendorStoreSubmitView.as_view(), name='vendor-business-submit'),
    path('media/', VendorStoreMediaListView.as_view(), name='business-profile-media-list'),
    path('media/<int:pk>/', VendorStoreMediaDetailView.as_view(), name='business-profile-media-detail'),
]
