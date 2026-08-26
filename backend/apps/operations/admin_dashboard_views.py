import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from drf_spectacular.utils import extend_schema, OpenApiResponse
from apps.accounts.permissions import IsAdminRole
from apps.accounts.models import User, UserRole
from apps.vendors.models import VendorProfile, VendorStatus
from apps.business.models import BusinessProfile

logger = logging.getLogger('her_area')

class AdminDashboardStatsView(APIView):
    """
    Returns real statistics for the Admin Dashboard.
    """
    permission_classes = [IsAdminRole]

    @extend_schema(
        summary="Admin Dashboard Statistics",
        description="Retrieve counts of total customers, verified vendors, pending vendors, and platform GMV.",
        responses={200: OpenApiResponse(description="Returns dashboard statistics")}
    )
    def get(self, request):
        total_customers = User.objects.filter(role=UserRole.CUSTOMER).count()
        verified_vendors = VendorProfile.objects.filter(status=VendorStatus.APPROVED).count()
        pending_vendors = VendorProfile.objects.filter(status=VendorStatus.PENDING).count()
        
        # Payment/GMV not implemented yet, return 0
        total_gmv = 0

        # We can also return stores count if useful
        total_stores = BusinessProfile.objects.count()

        return Response({
            "total_customers": total_customers,
            "verified_vendors": verified_vendors,
            "pending_vendors": pending_vendors,
            "total_stores": total_stores,
            "total_gmv": total_gmv
        }, status=status.HTTP_200_OK)
