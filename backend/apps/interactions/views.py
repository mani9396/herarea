import logging
from django.db.models import Q, Avg, Count
from rest_framework import status, permissions, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiParameter
import math
from django.utils import timezone
from apps.interactions.models import Favorite, Review, StoreVisit, StoreVisitStatus, ReviewStatus
from apps.interactions.serializers import FavoriteSerializer, ReviewSerializer, GlobalO2OSearchPayloadSerializer, StoreVisitSerializer
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


class RecentlyViewedListView(APIView):
    """Retrieve up to 20 recently viewed showrooms for authenticated customer."""
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(summary="List Recently Viewed Stores", responses={200: dict})
    def get(self, request):
        from apps.interactions.models import RecentlyViewedStore
        from apps.interactions.serializers import RecentlyViewedStoreSerializer
        
        recent = RecentlyViewedStore.objects.filter(
            user=request.user,
            store__vendor__status=VendorStatus.APPROVED,
            store__status='PUBLISHED',
            store__subscriptions__status='ACTIVE'
        ).select_related('store').order_by('-viewed_at')[:20]
        
        return Response({"results": RecentlyViewedStoreSerializer(recent, many=True).data}, status=status.HTTP_200_OK)


class RecentlyViewedLogView(APIView):
    """Log a store visit and enforce the 20-entry limit per user."""
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(summary="Log a store view", request=dict, responses={201: dict})
    def post(self, request, store_id):
        from apps.interactions.models import RecentlyViewedStore
        try:
            store = BusinessProfile.objects.get(pk=store_id, vendor__status=VendorStatus.APPROVED, status='PUBLISHED', subscriptions__status='ACTIVE')
        except BusinessProfile.DoesNotExist:
            raise exceptions.NotFound("Store not found or ineligible.")

        view_entry, created = RecentlyViewedStore.objects.get_or_create(
            user=request.user,
            store=store,
            defaults={'created_by': request.user, 'updated_by': request.user}
        )
        
        if not created:
            view_entry.viewed_at = timezone.now()
            view_entry.save()

        # Enforce 20 store limit
        user_recent_count = RecentlyViewedStore.objects.filter(user=request.user).count()
        if user_recent_count > 20:
            excess = user_recent_count - 20
            oldest_ids = RecentlyViewedStore.objects.filter(user=request.user).order_by('viewed_at').values_list('id', flat=True)[:excess]
            RecentlyViewedStore.objects.filter(id__in=list(oldest_ids)).delete()

        return Response({"status": "logged", "store_id": str(store_id)}, status=status.HTTP_201_CREATED)



class StoreReviewListView(APIView):
    """
    Public discovery & submission of customer reviews and ratings for Approved Showrooms.
    Automatically calculates real-time aggregated average rating scores from APPROVED reviews.
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

        reviews = Review.objects.filter(store=store, status=ReviewStatus.APPROVED).select_related('user', 'store').order_by('-created_at')
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

        # Check for active store visit
        active_visit = StoreVisit.objects.filter(
            user=request.user,
            store=store,
            status=StoreVisitStatus.VERIFIED,
            expires_at__gte=timezone.now()
        ).order_by('-created_at').first()

        if not active_visit:
            raise exceptions.ValidationError("You must have a verified physical visit to this store before submitting a review.")

        # Check if review already exists
        if Review.objects.filter(user=request.user, store=store).exists():
            raise exceptions.ValidationError("You have already reviewed this store.")

        serializer = ReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        review = serializer.save(
            user=request.user,
            store=store,
            visit=active_visit,
            status=ReviewStatus.PENDING,
            is_verified_visit=True,
            created_by=request.user,
            updated_by=request.user
        )

        logger.info(f"New {review.rating}-star PENDING review submitted for {store.business_name} by {request.user.email}")
        return Response(ReviewSerializer(review).data, status=status.HTTP_201_CREATED)


class CustomerReviewDetailView(APIView):
    """
    Manage own review (edit or delete).
    """
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ReviewSerializer

    def get_object(self, review_id, user):
        try:
            return Review.objects.get(pk=review_id, user=user)
        except Review.DoesNotExist:
            raise exceptions.NotFound("Review not found.")

    @extend_schema(summary="Get Own Review", responses={200: ReviewSerializer})
    def get(self, request, review_id):
        review = self.get_object(review_id, request.user)
        return Response(ReviewSerializer(review).data)

    @extend_schema(summary="Edit Own Review", request=ReviewSerializer, responses={200: ReviewSerializer})
    def patch(self, request, review_id):
        review = self.get_object(review_id, request.user)
        serializer = ReviewSerializer(review, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        
        # When a review is edited, it returns to PENDING status
        updated_review = serializer.save(status=ReviewStatus.PENDING, updated_by=request.user)
        return Response(ReviewSerializer(updated_review).data)

    @extend_schema(summary="Delete Own Review", responses={204: None})
    def delete(self, request, review_id):
        review = self.get_object(review_id, request.user)
        review.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class StoreVisitCreateView(APIView):
    """
    Verify physical store visit by comparing coordinates.
    """
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = StoreVisitSerializer

    def haversine(self, lat1, lon1, lat2, lon2):
        R = 6371.0 # km
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c

    @extend_schema(
        summary="Create & Verify Store Visit",
        parameters=[
            OpenApiParameter(name='latitude', description='Customer latitude', required=True, type=float),
            OpenApiParameter(name='longitude', description='Customer longitude', required=True, type=float),
        ],
        responses={200: StoreVisitSerializer, 201: StoreVisitSerializer}
    )
    def post(self, request, store_id):
        try:
            store = BusinessProfile.objects.get(pk=store_id, vendor__status=VendorStatus.APPROVED, status='PUBLISHED', subscriptions__status='ACTIVE')
        except BusinessProfile.DoesNotExist:
            raise exceptions.NotFound("Showroom not found or not eligible for visits.")

        if store.latitude is None or store.longitude is None:
            raise exceptions.ValidationError("Store location not available for proximity check.")

        try:
            lat = float(request.data.get('latitude'))
            lon = float(request.data.get('longitude'))
        except (TypeError, ValueError):
            raise exceptions.ValidationError("Valid latitude and longitude must be provided in the request body.")

        distance_km = self.haversine(lat, lon, float(store.latitude), float(store.longitude))
        
        # 100 meters = 0.1 km
        VERIFICATION_RADIUS_KM = 0.1
        
        visit = StoreVisit.objects.create(
            user=request.user,
            store=store,
            created_by=request.user,
            updated_by=request.user
        )

        if distance_km <= VERIFICATION_RADIUS_KM:
            visit.verify_visit()
            return Response(StoreVisitSerializer(visit).data, status=status.HTTP_201_CREATED)
        else:
            visit.status = StoreVisitStatus.EXPIRED
            visit.save()
            raise exceptions.ValidationError(f"You must be within {VERIFICATION_RADIUS_KM * 1000}m of the store to verify a visit. Current distance: {distance_km * 1000:.0f}m.")


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
