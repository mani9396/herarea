import logging
from django.db.models import Q
from rest_framework import status, permissions, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiParameter
from apps.business.models import BusinessProfile
from apps.business.serializers import PublicStoreShowroomSerializer
from apps.vendors.models import VendorStatus

logger = logging.getLogger('her_area')

class PublicStoreListView(APIView):
    """
    Customer App O2O Discovery Hub: Enumerate and filter all active studio showrooms 
    owned by officially APPROVED marketplace vendors.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = PublicStoreShowroomSerializer

    @extend_schema(
        summary="List Approved Public Store Showrooms",
        description="Filterable studio discovery engine. Strictly limited to APPROVED partner vendors.",
        parameters=[
            OpenApiParameter(name='category', description="Category ID (UUID)", required=False, type=str),
            OpenApiParameter(name='city', description="Filter by geographical city", required=False, type=str),
            OpenApiParameter(name='search', description="Search store name or description", required=False, type=str),
        ],
        responses={200: PublicStoreShowroomSerializer(many=True)}
    )
    def get(self, request):
        showrooms = BusinessProfile.objects.filter(vendor__status=VendorStatus.APPROVED).select_related('category', 'vendor')

        category_id = request.query_params.get('category')
        if category_id:
            showrooms = showrooms.filter(category_id=category_id)

        city = request.query_params.get('city')
        if city:
            showrooms = showrooms.filter(city__iexact=city)

        search = request.query_params.get('search')
        if search:
            showrooms = showrooms.filter(Q(business_name__icontains=search) | Q(description__icontains=search))

        showrooms = showrooms.order_by('business_name')
        serializer = PublicStoreShowroomSerializer(showrooms, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class PublicStoreDetailView(APIView):
    """Retrieve full location credentials, contact endpoints, and timings for a specific approved studio showroom."""
    permission_classes = [permissions.AllowAny]
    serializer_class = PublicStoreShowroomSerializer

    @extend_schema(summary="Get Approved Store Showroom Profile", responses={200: PublicStoreShowroomSerializer})
    def get(self, request, pk):
        try:
            showroom = BusinessProfile.objects.select_related('category', 'vendor').get(
                pk=pk, 
                vendor__status=VendorStatus.APPROVED
            )
        except BusinessProfile.DoesNotExist:
            raise exceptions.NotFound("Showroom not found, or partner studio has not completed Admin clearance.")
        
        serializer = PublicStoreShowroomSerializer(showroom)
        return Response(serializer.data, status=status.HTTP_200_OK)
