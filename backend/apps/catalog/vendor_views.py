import logging
from rest_framework import status, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema
from django.utils import timezone
from apps.accounts.permissions import IsVendorRole
from apps.catalog.models import Product, GalleryImage, Offer, Story, StoryStatus
from apps.catalog.serializers import ProductSerializer, GalleryImageSerializer, OfferSerializer, StorySerializer, VendorStoryCreateSerializer

logger = logging.getLogger('her_area')

class BaseApprovedVendorCatalogView(APIView):
    """
    Base view enforcing strict IsVendorRole clearance and binding operations 
    to the authenticated partner studio's Business Showroom Profile.
    """
    permission_classes = [IsVendorRole]

    def get_business_profile(self, user):
        if not hasattr(user.vendor_profile, 'business_profile') or not user.vendor_profile.business_profile:
            raise exceptions.NotFound("Showroom Business Profile required before configuring inventory catalog.")
        return user.vendor_profile.business_profile


class VendorProductListView(BaseApprovedVendorCatalogView):
    """List showroom products or publish new inventory collection items."""
    serializer_class = ProductSerializer

    @extend_schema(summary="List Studio Showroom Products", responses={200: ProductSerializer(many=True)})
    def get(self, request):
        business = self.get_business_profile(request.user)
        products = Product.objects.filter(business_profile=business).select_related('business_profile', 'category').order_by('-created_at')
        return Response(ProductSerializer(products, many=True).data, status=status.HTTP_200_OK)

    @extend_schema(summary="Create Showroom Product Item", request=ProductSerializer, responses={201: ProductSerializer})
    def post(self, request):
        business = self.get_business_profile(request.user)
        serializer = ProductSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        product = serializer.save(business_profile=business, created_by=request.user, updated_by=request.user)
        logger.info(f"Product '{product.name}' created by Approved Studio {business.business_name}")
        return Response(ProductSerializer(product, context={'request': request}).data, status=status.HTTP_201_CREATED)


class VendorProductDetailView(BaseApprovedVendorCatalogView):
    """Inspect, edit pricing/stock, or remove specific product inventory items."""
    serializer_class = ProductSerializer

    def _get_product(self, user, pk):
        business = self.get_business_profile(user)
        try:
            return Product.objects.select_related('business_profile', 'category').get(pk=pk, business_profile=business)
        except Product.DoesNotExist:
            raise exceptions.NotFound("Product item not found in your showroom catalog.")

    @extend_schema(summary="Get Showroom Product Detail", responses={200: ProductSerializer})
    def get(self, request, pk):
        product = self._get_product(request.user, pk)
        return Response(ProductSerializer(product, context={'request': request}).data, status=status.HTTP_200_OK)

    @extend_schema(summary="Update Showroom Product Specification", request=ProductSerializer, responses={200: ProductSerializer})
    def put(self, request, pk):
        product = self._get_product(request.user, pk)
        
        # Phase 11: Allow edit only if DRAFT, REJECTED, or APPROVED
        if product.status in ['PENDING_APPROVAL', 'SUSPENDED', 'HIDDEN']:
            raise exceptions.PermissionDenied(f"Cannot edit product while it is {product.status}.")

        serializer = ProductSerializer(product, data=request.data, partial=True, context={'request': request})
        serializer.is_valid(raise_exception=True)
        
        # Revert to PENDING_APPROVAL if editing an APPROVED product
        if product.status == 'APPROVED':
            serializer.save(status='PENDING_APPROVAL', updated_by=request.user)
            logger.info(f"Product '{product.name}' updated by Studio {request.user.phone_number} and reverted to PENDING_APPROVAL")
        else:
            serializer.save(updated_by=request.user)
            logger.info(f"Product '{product.name}' updated by Studio {request.user.phone_number}")
            
        return Response(ProductSerializer(product, context={'request': request}).data, status=status.HTTP_200_OK)

    @extend_schema(summary="Delete Showroom Product (Soft Delete)", responses={204: None})
    def delete(self, request, pk):
        product = self._get_product(request.user, pk)
        product_name = product.name
        product.delete()  # Inherits soft delete setting is_deleted=True
        logger.warning(f"Product '{product_name}' soft-deleted by Studio {request.user.phone_number}")
        return Response(status=status.HTTP_204_NO_CONTENT)


class VendorProductSubmitView(BaseApprovedVendorCatalogView):
    """Submit a DRAFT or REJECTED product for Admin Approval."""
    
    @extend_schema(summary="Submit Product for Admin Approval", responses={200: ProductSerializer})
    def post(self, request, pk):
        business = self.get_business_profile(request.user)
        try:
            product = Product.objects.get(pk=pk, business_profile=business)
        except Product.DoesNotExist:
            raise exceptions.NotFound("Product item not found in your showroom catalog.")
            
        if product.status not in ['DRAFT', 'REJECTED']:
            raise exceptions.PermissionDenied(f"Cannot submit product. Current status is {product.status}.")
            
        product.status = 'PENDING_APPROVAL'
        product.updated_by = request.user
        product.save()
        
        logger.info(f"Product '{product.name}' submitted for approval by Studio {business.business_name}")
        return Response(ProductSerializer(product).data, status=status.HTTP_200_OK)

    @extend_schema(summary="Delete Showroom Product (Soft Delete)", responses={204: None})
    def delete(self, request, pk):
        product = self._get_product(request.user, pk)
        product_name = product.name
        product.delete()  # Inherits soft delete setting is_deleted=True
        logger.warning(f"Product '{product_name}' soft-deleted by Studio {request.user.phone_number}")
        return Response(status=status.HTTP_204_NO_CONTENT)


class VendorGalleryListView(BaseApprovedVendorCatalogView):
    """Manage visual ambiance gallery portfolio displayed on Customer App showroom profiles."""
    serializer_class = GalleryImageSerializer

    @extend_schema(summary="List Showroom Gallery Photos", responses={200: GalleryImageSerializer(many=True)})
    def get(self, request):
        business = self.get_business_profile(request.user)
        images = GalleryImage.objects.filter(business_profile=business).order_by('display_order', '-created_at')
        return Response(GalleryImageSerializer(images, many=True).data, status=status.HTTP_200_OK)

    @extend_schema(summary="Upload Showroom Gallery Photo", request=GalleryImageSerializer, responses={201: GalleryImageSerializer})
    def post(self, request):
        business = self.get_business_profile(request.user)
        serializer = GalleryImageSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        image = serializer.save(business_profile=business, created_by=request.user, updated_by=request.user)
        logger.info(f"Gallery image uploaded by Studio {business.business_name}")
        return Response(GalleryImageSerializer(image).data, status=status.HTTP_201_CREATED)


class VendorGalleryDetailView(BaseApprovedVendorCatalogView):
    """Remove outdated gallery imagery from showroom portfolio."""
    serializer_class = GalleryImageSerializer

    @extend_schema(summary="Delete Showroom Gallery Photo", responses={204: None})
    def delete(self, request, pk):
        business = self.get_business_profile(request.user)
        try:
            image = GalleryImage.objects.get(pk=pk, business_profile=business)
        except GalleryImage.DoesNotExist:
            raise exceptions.NotFound("Gallery photograph not found in your studio portfolio.")
        image.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class VendorOfferListView(BaseApprovedVendorCatalogView):
    """Publish time-sensitive promotional campaigns and booking discount offers."""
    serializer_class = OfferSerializer

    @extend_schema(summary="List Showroom Promotional Offers", responses={200: OfferSerializer(many=True)})
    def get(self, request):
        business = self.get_business_profile(request.user)
        offers = Offer.objects.filter(business_profile=business).order_by('-created_at')
        return Response(OfferSerializer(offers, many=True).data, status=status.HTTP_200_OK)

    @extend_schema(summary="Create Promotional Campaign Offer", request=OfferSerializer, responses={201: OfferSerializer})
    def post(self, request):
        business = self.get_business_profile(request.user)
        data = request.data.copy()
        
        if 'status' in data:
            if data['status'] not in ['DRAFT', 'PENDING_APPROVAL']:
                raise exceptions.PermissionDenied("Vendors can only set status to DRAFT or PENDING_APPROVAL.")
                
        serializer = OfferSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        offer = serializer.save(business_profile=business, created_by=request.user, updated_by=request.user)
        logger.info(f"Offer '{offer.title}' deployed by Studio {business.business_name}")
        return Response(OfferSerializer(offer).data, status=status.HTTP_201_CREATED)


class VendorOfferDetailView(BaseApprovedVendorCatalogView):
    """Modify discount parameters, expiration dates, or revoke active campaigns."""
    serializer_class = OfferSerializer

    def _get_offer(self, user, pk):
        business = self.get_business_profile(user)
        try:
            return Offer.objects.get(pk=pk, business_profile=business)
        except Offer.DoesNotExist:
            raise exceptions.NotFound("Promotional offer not found in your showroom records.")

    @extend_schema(summary="Update Promotional Offer", request=OfferSerializer, responses={200: OfferSerializer})
    def put(self, request, pk):
        offer = self._get_offer(request.user, pk)
        data = request.data.copy()
        
        # Prevent vendor from self-approving or bypassing moderation
        if 'status' in data:
            if data['status'] not in ['DRAFT', 'PENDING_APPROVAL']:
                raise exceptions.PermissionDenied("Vendors can only set status to DRAFT or PENDING_APPROVAL.")
                
        serializer = OfferSerializer(offer, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save(updated_by=request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(summary="Revoke & Delete Promotional Offer", responses={204: None})
    def delete(self, request, pk):
        offer = self._get_offer(request.user, pk)
        offer.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class VendorStoryListView(BaseApprovedVendorCatalogView):
    """
    Manage episodic 24-hour Stories for the partner boutique.
    Enforces subscription eligibility and maximum 25 active stories limit.
    """
    serializer_class = StorySerializer

    @extend_schema(summary="List Showroom Stories", responses={200: StorySerializer(many=True)})
    def get(self, request):
        business = self.get_business_profile(request.user)
        stories = Story.objects.filter(
            business_profile=business,
            is_active=True
        ).order_by('-published_at')
        return Response(StorySerializer(stories, many=True).data, status=status.HTTP_200_OK)

    @extend_schema(summary="Publish Showroom Story", request=VendorStoryCreateSerializer, responses={201: StorySerializer})
    def post(self, request):
        business = self.get_business_profile(request.user)

        # 1. Vendor verification & subscription eligibility check
        vendor_profile = getattr(request.user, 'vendor_profile', None)
        if not vendor_profile or vendor_profile.status != 'APPROVED':
            raise exceptions.PermissionDenied("Only approved vendor studios can publish Stories.")

        if not business.is_listing_eligible:
            raise exceptions.PermissionDenied("An active subscription plan is required to publish Stories.")

        # 2. Check 25-active-Story cap (expired stories do not count toward cap)
        now = timezone.now()
        active_stories_count = Story.objects.filter(
            business_profile=business,
            is_active=True,
            status=StoryStatus.ACTIVE,
            expires_at__gt=now
        ).count()
        if active_stories_count >= 25:
            raise exceptions.ValidationError({
                "detail": "Maximum limit of 25 active Stories reached. Please delete an active story or wait for existing stories to expire."
            })

        serializer = VendorStoryCreateSerializer(
            data=request.data,
            context={'request': request, 'business_profile': business}
        )
        serializer.is_valid(raise_exception=True)
        story = serializer.save()
        logger.info(f"Story ({story.story_type}) published by studio {business.business_name}")
        return Response(StorySerializer(story).data, status=status.HTTP_201_CREATED)


class VendorStoryDetailView(BaseApprovedVendorCatalogView):
    """
    Inspect or immediately remove a Story from active listings.
    """
    serializer_class = StorySerializer

    def _get_story(self, user, pk):
        business = self.get_business_profile(user)
        try:
            return Story.objects.get(pk=pk, business_profile=business)
        except Story.DoesNotExist:
            raise exceptions.NotFound("Story not found in your showroom records.")

    @extend_schema(summary="Get Story Details", responses={200: StorySerializer})
    def get(self, request, pk):
        story = self._get_story(request.user, pk)
        return Response(StorySerializer(story).data, status=status.HTTP_200_OK)

    @extend_schema(summary="Delete Story", responses={204: None})
    def delete(self, request, pk):
        story = self._get_story(request.user, pk)
        # Deleting immediately removes from active listings
        story.is_active = False
        story.status = StoryStatus.ARCHIVED
        story.save()
        logger.info(f"Story {pk} deleted by studio {request.user.phone_number}")
        return Response(status=status.HTTP_204_NO_CONTENT)

