import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from drf_spectacular.utils import extend_schema, OpenApiResponse
from apps.accounts.permissions import IsAdminRole
from apps.accounts.models import User, UserRole
from apps.vendors.models import VendorProfile, VendorStatus, KycDocument, KycDocStatus
from apps.business.models import BusinessProfile, StoreStatus
from apps.catalog.models import Product, GalleryImage, Offer
from apps.interactions.models import Review, ReviewStatus

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
        
        pending_profile_updates = KycDocument.objects.filter(status=KycDocStatus.PENDING).count()
        pending_stores = BusinessProfile.objects.filter(status=StoreStatus.PENDING_APPROVAL).count()
        pending_products = Product.objects.filter(status='PENDING_APPROVAL').count()
        pending_gallery = 0 # GalleryImage currently does not have a moderation status
        pending_offers = Offer.objects.filter(status='PENDING_APPROVAL').count()
        pending_reviews = Review.objects.filter(status=ReviewStatus.PENDING).count()

        # Payment/GMV not implemented yet, return 0
        total_gmv = 0
        total_stores_all = BusinessProfile.objects.count()

        return Response({
            "total_customers": total_customers,
            "verified_vendors": verified_vendors,
            "pending_vendors": pending_vendors,
            "pending_profile_updates": pending_profile_updates,
            "pending_stores": pending_stores,
            "pending_products": pending_products,
            "pending_gallery": pending_gallery,
            "pending_offers": pending_offers,
            "pending_reviews": pending_reviews,
            "total_stores": total_stores_all,
            "total_gmv": total_gmv
        }, status=status.HTTP_200_OK)
