from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from apps.accounts.permissions import IsSuperAdminRole
from .models import ListingPlan, VendorSubscription, PaymentRecord
from .serializers import ListingPlanSerializer, VendorSubscriptionSerializer, PaymentRecordSerializer

class AdminListingPlanListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsSuperAdminRole]
    queryset = ListingPlan.objects.all().order_by('display_order', 'price')
    serializer_class = ListingPlanSerializer

class AdminListingPlanDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsSuperAdminRole]
    queryset = ListingPlan.objects.all()
    serializer_class = ListingPlanSerializer
    
    def perform_destroy(self, instance):
        # Prefer soft delete
        instance.is_active = False
        instance.save()

class AdminVendorSubscriptionListView(generics.ListAPIView):
    permission_classes = [IsSuperAdminRole]
    queryset = VendorSubscription.objects.all().order_by('-created_at')
    serializer_class = VendorSubscriptionSerializer
    
class AdminPaymentRecordListView(generics.ListAPIView):
    permission_classes = [IsSuperAdminRole]
    queryset = PaymentRecord.objects.all().order_by('-created_at')
    serializer_class = PaymentRecordSerializer

class AdminDashboardRevenueView(APIView):
    permission_classes = [IsSuperAdminRole]
    
    def get(self, request):
        from django.db.models import Sum
        total_revenue = PaymentRecord.objects.filter(status='SUCCESS').aggregate(total=Sum('amount'))['total'] or 0
        return Response({"total_revenue": total_revenue}, status=status.HTTP_200_OK)
