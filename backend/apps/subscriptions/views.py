import hmac
import hashlib
from django.conf import settings
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from apps.accounts.permissions import IsVendorRole, IsSuperAdminRole
from apps.business.models import BusinessProfile
from .models import ListingPlan, VendorSubscription, PaymentRecord
from .serializers import ListingPlanSerializer, VendorSubscriptionSerializer, PaymentRecordSerializer
import uuid
import logging

logger = logging.getLogger(__name__)

class ListingPlanListView(APIView):
    """
    Vendor facing endpoint to list active plans.
    """
    permission_classes = [IsVendorRole]

    def get(self, request):
        plans = ListingPlan.objects.filter(is_active=True).order_by('display_order', 'price')
        serializer = ListingPlanSerializer(plans, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class PaymentInitiateView(APIView):
    """
    Creates a payment order for a selected Listing Plan using a Dummy provider.
    Vendor must have an active store.
    """
    permission_classes = [IsVendorRole]

    def post(self, request):
        plan_id = request.data.get('plan_id')
        if not plan_id:
            return Response({"detail": "plan_id is required."}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            plan = ListingPlan.objects.get(id=plan_id, is_active=True)
        except ListingPlan.DoesNotExist:
            return Response({"detail": "Invalid or inactive plan."}, status=status.HTTP_404_NOT_FOUND)
        
        try:
            store = BusinessProfile.objects.get(vendor=request.user.vendor_profile)
        except BusinessProfile.DoesNotExist:
            return Response({"detail": "You must create a store before choosing a listing plan."}, status=status.HTTP_400_BAD_REQUEST)

        transaction_id = f"txn_{uuid.uuid4().hex}"
        
        # Create Subscription (PENDING)
        subscription = VendorSubscription.objects.create(
            vendor=request.user,
            store=store,
            plan=plan,
            status='PENDING',
            amount_paid=plan.price,
            currency=plan.currency,
            transaction_id=transaction_id,
            payment_provider='DUMMY'
        )
        
        # Create Payment Record (PENDING)
        PaymentRecord.objects.create(
            vendor=request.user,
            store=store,
            subscription=subscription,
            plan=plan,
            amount=plan.price,
            currency=plan.currency,
            transaction_id=transaction_id,
            payment_provider='DUMMY',
            status='PENDING'
        )

        return Response({
            "transaction_id": transaction_id,
            "amount": plan.price,
            "currency": plan.currency,
            "subscription_id": subscription.id
        }, status=status.HTTP_201_CREATED)

class PaymentVerifyView(APIView):
    """
    Verifies dummy payment and activates the subscription.
    """
    permission_classes = [IsVendorRole]

    def post(self, request):
        transaction_id = request.data.get('transaction_id')
        action = request.data.get('action', 'simulate_success')

        if not transaction_id:
            return Response({"detail": "transaction_id is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            subscription = VendorSubscription.objects.get(transaction_id=transaction_id, vendor=request.user)
            payment_record = PaymentRecord.objects.get(transaction_id=transaction_id, vendor=request.user)
        except (VendorSubscription.DoesNotExist, PaymentRecord.DoesNotExist):
            return Response({"detail": "Invalid transaction ID."}, status=status.HTTP_404_NOT_FOUND)

        if subscription.status == 'ACTIVE':
            return Response({"detail": "Subscription is already active."}, status=status.HTTP_200_OK)

        now = timezone.now()

        if action == 'simulate_failure':
            subscription.status = 'PAYMENT_FAILED'
            subscription.save()
            payment_record.status = 'FAILED'
            payment_record.save()
            return Response({"detail": "Payment simulation failed."}, status=status.HTTP_400_BAD_REQUEST)

        # Activation
        subscription.status = 'ACTIVE'
        subscription.start_date = now
        subscription.end_date = now + timezone.timedelta(days=subscription.plan.duration_days) if subscription.plan else now
        subscription.provider_payment_id = f"dummy_{uuid.uuid4().hex[:8]}"
        subscription.signature = "dummy_signature_verified"
        subscription.save()

        payment_record.status = 'SUCCESS'
        payment_record.provider_payment_id = subscription.provider_payment_id
        payment_record.save()

        # Disable previous active subscriptions for the same store
        VendorSubscription.objects.filter(store=subscription.store, status='ACTIVE').exclude(id=subscription.id).update(status='EXPIRED')

        return Response({
            "detail": "Payment successful. Subscription activated.", 
            "subscription": VendorSubscriptionSerializer(subscription).data
        }, status=status.HTTP_200_OK)

class MySubscriptionView(APIView):
    """
    Get current vendor's active or latest subscription.
    """
    permission_classes = [IsVendorRole]

    def get(self, request):
        try:
            store = BusinessProfile.objects.get(vendor=request.user.vendor_profile)
        except BusinessProfile.DoesNotExist:
            return Response({"detail": "No store found."}, status=status.HTTP_404_NOT_FOUND)

        subs = VendorSubscription.objects.filter(store=store).exclude(status='PENDING').order_by('-created_at')
        if not subs.exists():
            return Response({"detail": "No active subscription."}, status=status.HTTP_404_NOT_FOUND)
        
        serializer = VendorSubscriptionSerializer(subs.first())
        return Response(serializer.data, status=status.HTTP_200_OK)
