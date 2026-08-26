from rest_framework import serializers
from .models import ListingPlan, VendorSubscription, PaymentRecord

class ListingPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = ListingPlan
        fields = ['id', 'name', 'description', 'price', 'currency', 'duration_days', 'is_active', 'display_order', 'created_at']

class VendorSubscriptionSerializer(serializers.ModelSerializer):
    plan_name = serializers.CharField(source='plan.name', read_only=True)
    plan_duration = serializers.IntegerField(source='plan.duration_days', read_only=True)

    class Meta:
        model = VendorSubscription
        fields = [
            'id', 'plan', 'plan_name', 'plan_duration', 'status', 
            'start_date', 'end_date', 'amount_paid', 'currency', 
            'transaction_id', 'provider_payment_id', 'payment_provider', 'created_at'
        ]

class PaymentRecordSerializer(serializers.ModelSerializer):
    plan_name = serializers.CharField(source='plan.name', read_only=True)

    class Meta:
        model = PaymentRecord
        fields = [
            'id', 'subscription', 'plan', 'plan_name', 'amount', 'currency', 
            'transaction_id', 'provider_payment_id', 'payment_provider', 'status', 
            'created_at', 'verified_at'
        ]
