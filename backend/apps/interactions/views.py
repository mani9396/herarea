import logging
from django.db.models import Q, Avg, Count
from rest_framework import status, permissions, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiParameter
from apps.interactions.models import Favorite, Review
from apps.interactions.serializers import FavoriteSerializer, ReviewSerializer, GlobalO2OSearchPayloadSerializer
from apps.business.models import BusinessProfile
from apps.catalog.models import Product, CatalogItemType
from apps.vendors.models import VendorStatus
from apps.notifications.services import NotificationEngine
from apps.notifications.models import NotificationType

logger = logging.getLogger('her_area')

class FavoriteListView(APIView):
    """Retrieve all active wishlist bookmarks (showrooms and catalog items) for authenticated customer."""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = FavoriteSerializer

    @extend_schema(summary="List Customer Wishlist Bookmarks", responses={200: FavoriteSerializer(many=True)})
    def get(self, request):
        favorites = Favorite.objects.filter(user=request.user).select_related('store', 'product', 'product__business_profile', 'product__category').order_by('-created_at')
        return Response(FavoriteSerializer(favorites, many=True).data, status=status.HTTP_200_OK)


class FavoriteToggleView(APIView):
    """
    High-efficiency single-call toggle:
    If target store or product is already in user's wishlist, it removes the bookmark.
    If absent, it creates and persists the bookmark.
    """
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = FavoriteSerializer

    @extend_schema(summary="Toggle Wishlist Bookmark for Store or Product", request=FavoriteSerializer, responses={200: dict, 201: dict})
    def post(self, request):
        store_id = request.data.get('store')
        product_id = request.data.get('product')

        if not store_id and not product_id:
            raise exceptions.ValidationError("Must submit either 'store' (UUID) or 'product' (UUID) parameter.")
        if store_id and product_id:
            raise exceptions.ValidationError("Cannot toggle both a store and a product in the same call.")

        if store_id:
            try:
                store = BusinessProfile.objects.get(pk=store_id, vendor__status=VendorStatus.APPROVED)
            except BusinessProfile.DoesNotExist:
                raise exceptions.NotFound("Target store showroom does not exist or is unapproved.")
            
            existing = Favorite.objects.filter(user=request.user, store=store).first()
            if existing:
                existing.delete()
                return Response({"status": "removed", "bookmarked": False, "target": "store", "store_id": str(store_id)}, status=status.HTTP_200_OK)
            else:
                fav = Favorite.objects.create(user=request.user, store=store, created_by=request.user, updated_by=request.user)
                return Response({"status": "added", "bookmarked": True, "favorite": FavoriteSerializer(fav).data}, status=status.HTTP_201_CREATED)

        if product_id:
            try:
                product = Product.objects.get(pk=product_id, is_active=True, business_profile__vendor__status=VendorStatus.APPROVED)
            except Product.DoesNotExist:
                raise exceptions.NotFound("Target catalog item does not exist or studio is inactive.")

            existing = Favorite.objects.filter(user=request.user, product=product).first()
            if existing:
                existing.delete()
                return Response({"status": "removed", "bookmarked": False, "target": "product", "product_id": str(product_id)}, status=status.HTTP_200_OK)
            else:
                fav = Favorite.objects.create(user=request.user, product=product, created_by=request.user, updated_by=request.user)
                return Response({"status": "added", "bookmarked": True, "favorite": FavoriteSerializer(fav).data}, status=status.HTTP_201_CREATED)


class StoreReviewListView(APIView):
    """
    Public discovery & submission of customer reviews and ratings for Approved Showrooms.
    Automatically calculates real-time aggregated average rating scores.
    """
    serializer_class = ReviewSerializer

    def get_permissions(self):
        if self.request.method == 'POST':
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    @extend_schema(summary="Get Store Showroom Reviews & Average Score", responses={200: ReviewSerializer(many=True)})
    def get(self, request, store_id):
        try:
            store = BusinessProfile.objects.get(pk=store_id, vendor__status=VendorStatus.APPROVED)
        except BusinessProfile.DoesNotExist:
            raise exceptions.NotFound("Showroom not found or awaiting administrative clearance.")

        reviews = Review.objects.filter(store=store).select_related('user', 'store').order_by('-created_at')
        stats = reviews.aggregate(avg_rating=Avg('rating'), total_count=Count('id'))

        serializer = ReviewSerializer(reviews, many=True)
        return Response({
            "store_id": str(store.id),
            "store_name": store.business_name,
            "average_rating": round(stats['avg_rating'], 2) if stats['avg_rating'] else 0.0,
            "review_count": stats['total_count'],
            "reviews": serializer.data
        }, status=status.HTTP_200_OK)

    @extend_schema(summary="Submit Showroom Customer Review", request=ReviewSerializer, responses={201: ReviewSerializer})
    def post(self, request, store_id):
        try:
            store = BusinessProfile.objects.select_related('vendor', 'vendor__user').get(pk=store_id, vendor__status=VendorStatus.APPROVED)
        except BusinessProfile.DoesNotExist:
            raise exceptions.NotFound("Showroom not found or awaiting administrative clearance.")

        serializer = ReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        review = serializer.save(user=request.user, store=store, created_by=request.user, updated_by=request.user)

        logger.info(f"New {review.rating}★ review submitted for {store.business_name} by {request.user.phone_number}")

        # Dispatch real-time notification to Studio Owner!
        NotificationEngine.send_notification(
            recipient=store.vendor.user,
            title="New Customer Review & Rating!",
            message=f"Your showroom '{store.business_name}' just received a {review.rating}-star review: '{review.comment}'",
            notification_type=NotificationType.REVIEW,
            action_url="/vendor/reviews"
        )
        return Response(ReviewSerializer(review).data, status=status.HTTP_201_CREATED)


class GlobalO2OSearchView(APIView):
    """
    Unified Marketplace Search Engine:
    Simultaneously queries Approved Showroom brands, retail couture Products, 
    and appointment Services in one coherent discovery payload.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = GlobalO2OSearchPayloadSerializer

    @extend_schema(
        summary="Execute Global O2O Marketplace Search",
        parameters=[OpenApiParameter(name='q', description="Keyword search string e.g. 'Bridal', 'Silk', 'Facial'", required=True, type=str)],
        responses={200: GlobalO2OSearchPayloadSerializer}
    )
    def get(self, request):
        query = request.query_params.get('q', '').strip()
        if not query:
            return Response({
                "query": "",
                "matching_stores": [],
                "matching_products": [],
                "matching_services": []
            }, status=status.HTTP_200_OK)

        # 1. Search Approved Studios
        stores = BusinessProfile.objects.filter(
            vendor__status=VendorStatus.APPROVED
        ).filter(
            Q(business_name__icontains=query) | Q(description__icontains=query) | Q(city__icontains=query)
        ).order_by('business_name')

        # 2. Search Active Catalog Items across Approved Studios
        items = Product.objects.filter(
            is_active=True, 
            business_profile__vendor__status=VendorStatus.APPROVED
        ).filter(
            Q(name__icontains=query) | Q(description__icontains=query) | Q(category__name__icontains=query)
        ).select_related('business_profile', 'category').order_by('-is_featured', '-created_at')

        products = [item for item in items if item.item_type == CatalogItemType.PRODUCT]
        services = [item for item in items if item.item_type == CatalogItemType.SERVICE]

        from apps.business.serializers import PublicStoreShowroomSerializer
        from apps.catalog.serializers import ProductSerializer

        payload = {
            "query": query,
            "matching_stores": PublicStoreShowroomSerializer(stores, many=True).data,
            "matching_products": ProductSerializer(products, many=True).data,
            "matching_services": ProductSerializer(services, many=True).data,
        }
        return Response(payload, status=status.HTTP_200_OK)
