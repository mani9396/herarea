from rest_framework import generics, status, views, exceptions
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiResponse
from apps.accounts.permissions import IsAdminRole
from apps.business.models import BusinessProfile, StoreStatus
from apps.business.serializers import BusinessProfileSerializer

class AdminStoreListView(generics.ListAPIView):
    """
    List all business profiles (stores) for admin review.
    """
    permission_classes = [IsAdminRole]
    serializer_class = BusinessProfileSerializer

    def get_queryset(self):
        queryset = BusinessProfile.objects.all().order_by('-created_at')
        status_param = self.request.query_params.get('status')
        if status_param:
            queryset = queryset.filter(status=status_param)
        return queryset

class AdminStoreApproveView(views.APIView):
    """
    Approve a pending store.
    """
    permission_classes = [IsAdminRole]

    def post(self, request, pk):
        try:
            store = BusinessProfile.objects.get(pk=pk)
        except BusinessProfile.DoesNotExist:
            raise exceptions.NotFound("Store not found")

        if store.status != StoreStatus.PENDING_APPROVAL:
            return Response({"detail": "Only stores pending approval can be approved."}, status=status.HTTP_400_BAD_REQUEST)
            
        if not store.is_listing_eligible:
            return Response({"detail": "Cannot publish a store without an active subscription."}, status=status.HTTP_400_BAD_REQUEST)

        store.status = StoreStatus.PUBLISHED
        store.admin_remarks = ""
        store.save(update_fields=['status', 'admin_remarks'])

        return Response({"detail": "Store approved and published."}, status=status.HTTP_200_OK)

class AdminStoreRejectView(views.APIView):
    """
    Reject a pending store with a reason.
    """
    permission_classes = [IsAdminRole]

    def post(self, request, pk):
        try:
            store = BusinessProfile.objects.get(pk=pk)
        except BusinessProfile.DoesNotExist:
            raise exceptions.NotFound("Store not found")

        reason = request.data.get("reason")
        if not reason:
            return Response({"detail": "Reason is required for rejection."}, status=status.HTTP_400_BAD_REQUEST)

        store.status = StoreStatus.REJECTED
        store.admin_remarks = reason
        store.save(update_fields=['status', 'admin_remarks'])

        return Response({"detail": "Store rejected."}, status=status.HTTP_200_OK)

class AdminStoreSuspendView(views.APIView):
    """
    Suspend a published store with a reason.
    """
    permission_classes = [IsAdminRole]

    def post(self, request, pk):
        try:
            store = BusinessProfile.objects.get(pk=pk)
        except BusinessProfile.DoesNotExist:
            raise exceptions.NotFound("Store not found")

        reason = request.data.get("reason")
        if not reason:
            return Response({"detail": "Reason is required for suspension."}, status=status.HTTP_400_BAD_REQUEST)

        store.status = StoreStatus.SUSPENDED
        store.admin_remarks = reason
        store.save(update_fields=['status', 'admin_remarks'])

        return Response({"detail": "Store suspended."}, status=status.HTTP_200_OK)

class AdminStoreApplicationDossierView(views.APIView):
    """
    Fetches the complete application for admin review, including Vendor, Store, Media, Products, Offers, and Subscriptions.
    """
    permission_classes = [IsAdminRole]

    @extend_schema(summary="Get Complete Application Dossier", description="Returns aggregated data for admin review.")
    def get(self, request, pk):
        try:
            store = BusinessProfile.objects.get(pk=pk)
        except BusinessProfile.DoesNotExist:
            raise exceptions.NotFound("Store not found")
            
        from apps.catalog.models import Product, Offer
        from apps.catalog.serializers import ProductSerializer, OfferSerializer
        from apps.vendors.serializers import VendorProfileSerializer
        from apps.business.serializers import StoreMediaSerializer
        from apps.subscriptions.models import VendorSubscription
        from apps.subscriptions.serializers import VendorSubscriptionSerializer

        products = Product.objects.filter(business_profile=store)
        offers = Offer.objects.filter(business_profile=store)
        media = store.gallery_images.all()
        subs = VendorSubscription.objects.filter(store=store).order_by('-created_at')

        return Response({
            "vendor": VendorProfileSerializer(store.vendor).data if store.vendor else None,
            "store": BusinessProfileSerializer(store).data,
            "media": StoreMediaSerializer(media, many=True).data,
            "products": ProductSerializer(products, many=True).data,
            "offers": OfferSerializer(offers, many=True).data,
            "subscription": VendorSubscriptionSerializer(subs.first()).data if subs.exists() else None
        }, status=status.HTTP_200_OK)
