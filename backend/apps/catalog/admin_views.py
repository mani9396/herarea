import logging
from rest_framework import status, exceptions, serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema
from apps.accounts.permissions import IsAdminRole
from apps.catalog.models import Product, Offer, GalleryImage
from apps.catalog.serializers import ProductSerializer, PublicPromotionSerializer, GalleryImageSerializer

logger = logging.getLogger('her_area')

class AdminGalleryEnrichedSerializer(GalleryImageSerializer):
    vendor_name = serializers.CharField(source='business_profile.business_name', read_only=True)
    title = serializers.CharField(source='caption', read_only=True)
    uploaded_at = serializers.DateTimeField(source='created_at', read_only=True)
    status = serializers.SerializerMethodField()

    class Meta(GalleryImageSerializer.Meta):
        fields = GalleryImageSerializer.Meta.fields + ['vendor_name', 'title', 'uploaded_at', 'status']

    def get_status(self, obj) -> str:
        return 'APPROVED' if getattr(obj, 'is_active', True) else 'PENDING'


class AdminProductListView(APIView):
    """
    Executive platform queue allowing Administrators to inspect all showroom products and services.
    """
    permission_classes = [IsAdminRole]
    serializer_class = ProductSerializer

    @extend_schema(summary="List All Catalog Products & Services for Moderation")
    def get(self, request):
        products = Product.objects.select_related('business_profile', 'category').order_by('-created_at')
        return Response(ProductSerializer(products, many=True).data, status=status.HTTP_200_OK)


class AdminProductDetailView(APIView):
    """
    Executive moderation operations for an individual product item (removal or approval state override).
    """
    permission_classes = [IsAdminRole]

    @extend_schema(summary="Delete or Reject a Catalog Product Item")
    def delete(self, request, pk):
        try:
            product = Product.objects.get(pk=pk)
            # Use hard delete if supported by manager, otherwise delete
            if hasattr(Product, 'all_objects') and hasattr(product, 'hard_delete'):
                product.hard_delete()
            else:
                product.delete()
            logger.info(f"Admin {request.user.phone_number} removed product item {pk}.")
            return Response({"detail": "Product removed successfully."}, status=status.HTTP_204_NO_CONTENT)
        except Product.DoesNotExist:
            raise exceptions.NotFound("Product item not found in repository.")


class AdminProductActionView(APIView):
    """
    Executive moderation operations for products (approve, reject, hide, suspend).
    """
    permission_classes = [IsAdminRole]

    @extend_schema(summary="Moderate Product (Approve, Reject, Hide, Suspend)")
    def post(self, request, pk, action):
        try:
            product = Product.objects.get(pk=pk)
        except Product.DoesNotExist:
            raise exceptions.NotFound("Product not found.")
        
        remarks = request.data.get('admin_remarks', '')

        if action == 'approve':
            product.status = 'APPROVED'
            product.admin_remarks = remarks
        elif action == 'reject':
            product.status = 'REJECTED'
            product.admin_remarks = remarks
        elif action == 'hide':
            if product.status != 'APPROVED':
                raise exceptions.ValidationError("Only approved products can be hidden.")
            product.status = 'HIDDEN'
            product.admin_remarks = remarks
        elif action == 'suspend':
            if product.status != 'APPROVED':
                raise exceptions.ValidationError("Only approved products can be suspended.")
            product.status = 'SUSPENDED'
            product.admin_remarks = remarks
        else:
            raise exceptions.ValidationError("Invalid action.")
            
        product.updated_by = request.user
        product.save()
        logger.info(f"Admin {request.user.phone_number} performed '{action}' on Product {pk}")
        
        return Response(ProductSerializer(product).data, status=status.HTTP_200_OK)


class AdminOfferListView(APIView):
    """
    Executive platform oversight queue allowing Administrators to monitor promotional campaigns and deals.
    """
    permission_classes = [IsAdminRole]
    serializer_class = PublicPromotionSerializer

    @extend_schema(summary="List All Promotional Campaigns & Offers for Moderation")
    def get(self, request):
        offers = Offer.objects.select_related('business_profile').order_by('-created_at')
        return Response(PublicPromotionSerializer(offers, many=True).data, status=status.HTTP_200_OK)


class AdminOfferDetailView(APIView):
    """
    Executive moderation operations for promotional campaigns (expiration or removal).
    """
    permission_classes = [IsAdminRole]

    @extend_schema(summary="Remove or Terminate a Promotional Offer")
    def delete(self, request, pk):
        try:
            offer = Offer.objects.get(pk=pk)
            offer.delete()
            logger.info(f"Admin {request.user.phone_number} terminated promotional offer {pk}.")
            return Response({"detail": "Promotional offer removed successfully."}, status=status.HTTP_204_NO_CONTENT)
        except Offer.DoesNotExist:
            raise exceptions.NotFound("Promotional offer not found.")

class AdminOfferActionView(APIView):
    permission_classes = [IsAdminRole]

    @extend_schema(summary="Moderate Promotional Offer (Approve, Reject, Suspend)")
    def post(self, request, pk, action):
        try:
            offer = Offer.objects.get(pk=pk)
        except Offer.DoesNotExist:
            raise exceptions.NotFound("Promotional offer not found.")
        
        remarks = request.data.get('admin_remarks', '')

        if action == 'approve':
            offer.status = 'APPROVED'
        elif action == 'reject':
            offer.status = 'REJECTED'
            offer.admin_remarks = remarks
        elif action == 'suspend':
            offer.status = 'SUSPENDED'
            offer.admin_remarks = remarks
        else:
            return Response({"error": "Invalid action"}, status=status.HTTP_400_BAD_REQUEST)
        
        offer.save()
        logger.info(f"Admin {request.user.phone_number} {action}d offer {pk}.")
        from apps.catalog.serializers import OfferSerializer
        return Response(OfferSerializer(offer).data, status=status.HTTP_200_OK)


class AdminGalleryListView(APIView):
    """
    Executive platform gallery oversight allowing Administrators to moderate studio showcase media.
    """
    permission_classes = [IsAdminRole]
    serializer_class = AdminGalleryEnrichedSerializer

    @extend_schema(summary="List All Showroom Gallery Images for Moderation")
    def get(self, request):
        images = GalleryImage.objects.select_related('business_profile').order_by('-created_at')
        return Response(AdminGalleryEnrichedSerializer(images, many=True).data, status=status.HTTP_200_OK)


class AdminGalleryDetailView(APIView):
    """
    Executive moderation operations for gallery imagery (removal of flagged media).
    """
    permission_classes = [IsAdminRole]

    @extend_schema(summary="Delete a Gallery Showcase Image")
    def delete(self, request, pk):
        try:
            image = GalleryImage.objects.get(pk=pk)
            image.delete()
            logger.info(f"Admin {request.user.phone_number} removed gallery image {pk}.")
            return Response({"detail": "Gallery image deleted successfully."}, status=status.HTTP_204_NO_CONTENT)
        except GalleryImage.DoesNotExist:
            raise exceptions.NotFound("Gallery image not found.")
