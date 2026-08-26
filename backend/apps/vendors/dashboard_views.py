import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from drf_spectacular.utils import extend_schema, OpenApiResponse
from apps.accounts.permissions import IsVendorRole
from apps.interactions.models import Review
from apps.interactions.serializers import ReviewSerializer

logger = logging.getLogger('her_area')

class VendorDashboardStatsView(APIView):
    """
    Returns real statistics for the Vendor Dashboard.
    For Phase 2, this returns 0s since analytics are not yet tracked.
    """
    permission_classes = [IsVendorRole]

    @extend_schema(
        summary="Vendor Dashboard Statistics",
        description="Retrieve counts of profile views, inquiries, WhatsApp taps, and estimated lead value.",
        responses={200: OpenApiResponse(description="Returns dashboard statistics")}
    )
    def get(self, request):
        return Response({
            "profile_views": 0,
            "trial_inquiries": 0,
            "whatsapp_taps": 0,
            "estimated_lead_value": 0
        }, status=status.HTTP_200_OK)


class VendorReviewListView(APIView):
    """
    Vendor-facing read-only review endpoint.
    Retrieves reviews strictly for the vendor's own store.
    """
    permission_classes = [IsVendorRole]

    @extend_schema(summary="List Reviews for Vendor's Store", responses={200: ReviewSerializer(many=True)})
    def get(self, request):
        try:
            profile = request.user.vendor_profile
            store = profile.business_profile
        except AttributeError:
            return Response([], status=status.HTTP_200_OK)

        reviews = Review.objects.filter(store=store).select_related('user').order_by('-created_at')
        serializer = ReviewSerializer(reviews, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
