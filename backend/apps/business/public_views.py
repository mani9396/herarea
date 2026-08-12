import logging
from django.db.models import Q, F, ExpressionWrapper, FloatField
from django.db.models.functions import Cos, Sin, Radians, ACos
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


class PublicStoreNearbyView(APIView):
    """
    Customer App O2O Discovery: Retrieve showrooms sorted by geographic distance
    from a provided GPS coordinate.
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="List Nearby Approved Showrooms",
        description="Fetch stores using exact GPS coordinates and radius filtering.",
        parameters=[
            OpenApiParameter(name='latitude', description="User GPS Latitude", required=True, type=float),
            OpenApiParameter(name='longitude', description="User GPS Longitude", required=True, type=float),
            OpenApiParameter(name='radius_km', description="Search radius in kilometers", required=False, type=float),
            OpenApiParameter(name='category', description="Optional category filter", required=False, type=str),
        ],
        responses={200: PublicStoreShowroomSerializer(many=True)}
    )
    def get(self, request):
        try:
            lat = float(request.query_params.get('latitude'))
            lon = float(request.query_params.get('longitude'))
        except (TypeError, ValueError):
            return Response({'detail': 'Valid latitude and longitude are required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            radius = float(request.query_params.get('radius_km', 25.0))
        except (TypeError, ValueError):
            radius = 25.0
        
        if radius > 25.0:
            radius = 25.0

        # Base filter: Only approved vendors with valid coordinates
        showrooms = BusinessProfile.objects.filter(
            vendor__status=VendorStatus.APPROVED,
            latitude__isnull=False,
            longitude__isnull=False
        ).select_related('category', 'vendor')

        category_id = request.query_params.get('category')
        if category_id:
            showrooms = showrooms.filter(category_id=category_id)

        # Haversine calculation expression in Django ORM
        # Distance = 6371 * Acos(Cos(lat1)*Cos(lat2)*Cos(lon2-lon1) + Sin(lat1)*Sin(lat2))
        target_lat = Radians(lat)
        target_lon = Radians(lon)
        db_lat = Radians(F('latitude'))
        db_lon = Radians(F('longitude'))

        # Add distance_km to each record using expression
        distance_expr = ExpressionWrapper(
            6371.0 * ACos(
                Cos(target_lat) * Cos(db_lat) * Cos(db_lon - target_lon) +
                Sin(target_lat) * Sin(db_lat)
            ),
            output_field=FloatField()
        )

        showrooms = showrooms.annotate(distance_km=distance_expr).filter(distance_km__lte=radius).order_by('distance_km')

        serializer = PublicStoreShowroomSerializer(showrooms, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
