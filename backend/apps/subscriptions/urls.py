from django.urls import path
from .views import ListingPlanListView, PaymentInitiateView, PaymentVerifyView, MySubscriptionView

urlpatterns = [
    path('plans/', ListingPlanListView.as_view(), name='listing-plans'),
    path('payment/initiate/', PaymentInitiateView.as_view(), name='payment-initiate'),
    path('payment/verify/', PaymentVerifyView.as_view(), name='payment-verify'),
    path('me/', MySubscriptionView.as_view(), name='my-subscription'),
]
