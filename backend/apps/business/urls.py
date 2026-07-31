from django.urls import path
from apps.business.views import VendorBusinessProfileView

urlpatterns = [
    path('me/', VendorBusinessProfileView.as_view(), name='business-profile-me'),
]
