import logging
from django.db.models import Q
from rest_framework import status, permissions, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiParameter
from apps.catalog.models import Product, GalleryImage, Offer
from apps.catalog.serializers import ProductSerializer, GalleryImageSerializer, OfferSerializer, StoreCompleteCatalogSerializer, PublicPromotionSerializer
from apps.vendors.models import VendorStatus
from apps.business.models import BusinessProfile

logger = logging.getLogger('her_area')

class PublicProductListView(APIView):
    """
    Customer App Global O2O Catalog Engine: Search and filter live product offerings 
    across all officially APPROVED partner studio showrooms.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = ProductSerializer

    @extend_schema(
        summary="Search & Filter Public Marketplace Products",
        description="Enumerate active products from APPROVED showrooms only. Supports multi-faceted filtering.",
        parameters=[
            OpenApiParameter(name='category', description="Category ID (UUID)", required=False, type=str),
            OpenApiParameter(name='store', description="Store Showroom ID (UUID)", required=False, type=str),
            OpenApiParameter(name='search', description="Search product name or specs", required=False, type=str),
            OpenApiParameter(name='featured', description="Filter strictly to featured showroom items (true/false)", required=False, type=str),
        ],
        responses={200: ProductSerializer(many=True)}
    )
    def get(self, request):
        # Guarantee exclusion of unapproved or inactive studios
        products = Product.objects.filter(
            is_active=True, 
            business_profile__vendor__status=VendorStatus.APPROVED
        ).select_related('business_profile', 'category')

        category_id = request.query_params.get('category')
        if category_id:
            products = products.filter(category_id=category_id)

        store_id = request.query_params.get('store')
        if store_id:
            products = products.filter(business_profile_id=store_id)

        search = request.query_params.get('search')
        if search:
            products = products.filter(Q(name__icontains=search) | Q(description__icontains=search))

        featured = request.query_params.get('featured')
        if featured and featured.lower() in ['true', '1', 'yes']:
            products = products.filter(is_featured=True)

        products = products.order_by('-is_featured', '-created_at')
        return Response(ProductSerializer(products, many=True).data, status=status.HTTP_200_OK)


class PublicProductDetailView(APIView):
    """Inspect complete pricing, stock readiness, and studio coordinates for a specific product."""
    permission_classes = [permissions.AllowAny]
    serializer_class = ProductSerializer

    @extend_schema(summary="Get Approved Product Details", responses={200: ProductSerializer})
    def get(self, request, pk):
        try:
            product = Product.objects.select_related('business_profile', 'category').get(
                pk=pk,
                is_active=True,
                business_profile__vendor__status=VendorStatus.APPROVED
            )
        except Product.DoesNotExist:
            raise exceptions.NotFound("Requested product offering is unavailable or studio is under administrative review.")
        
        return Response(ProductSerializer(product).data, status=status.HTTP_200_OK)


class PublicStoreCatalogDossierView(APIView):
    """
    Unified O2O Store Detail Aggregated Dossier:
    Delivers all active products, gallery images, and valid promotional offers for a specific approved store in a single call.
    Optimizes Customer App Store Detail screen performance.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = StoreCompleteCatalogSerializer

    @extend_schema(
        summary="Get Store Complete Catalog Dossier (Products, Gallery & Offers)",
        description="Retrieve aggregated active catalog inventory, ambiance photography, and promotional campaigns for an approved store.",
        responses={200: StoreCompleteCatalogSerializer}
    )
    def get(self, request, store_id):
        try:
            store = BusinessProfile.objects.get(pk=store_id, vendor__status=VendorStatus.APPROVED)
        except BusinessProfile.DoesNotExist:
            raise exceptions.NotFound("Target studio showroom not found or awaiting Admin clearance.")

        products = Product.objects.filter(business_profile=store, is_active=True).select_related('business_profile', 'category').order_by('-is_featured', '-created_at')
        gallery = GalleryImage.objects.filter(business_profile=store).order_by('display_order', '-created_at')
        offers = Offer.objects.filter(business_profile=store, is_active=True).order_by('-created_at')

        payload = {
            "products": ProductSerializer(products, many=True).data,
            "gallery": GalleryImageSerializer(gallery, many=True).data,
            "offers": OfferSerializer(offers, many=True).data
        }
        return Response(payload, status=status.HTTP_200_OK)


class PublicPromotionListView(APIView):
    """
    Customer App Global O2O Promotions Engine: Enumerate active promotional campaigns and discount deals
    across all officially APPROVED partner studio showrooms.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = PublicPromotionSerializer

    @extend_schema(
        summary="List Public Marketplace Promotional Campaigns",
        description="Enumerate active promotions and deals from APPROVED showrooms only.",
        responses={200: PublicPromotionSerializer(many=True)}
    )
    def get(self, request):
        offers = Offer.objects.filter(
            is_active=True,
            business_profile__vendor__status=VendorStatus.APPROVED
        ).select_related('business_profile').order_by('-created_at')
        return Response(PublicPromotionSerializer(offers, many=True).data, status=status.HTTP_200_OK)
