import logging
from rest_framework import status, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema
from apps.vendors.permissions import IsApprovedVendor
from apps.catalog.models import Product, GalleryImage, Offer
from apps.catalog.serializers import ProductSerializer, GalleryImageSerializer, OfferSerializer

logger = logging.getLogger('her_area')

class BaseApprovedVendorCatalogView(APIView):
    """
    Base view enforcing strict IsApprovedVendor clearance and binding operations 
    to the authenticated partner studio's Business Showroom Profile.
    """
    permission_classes = [IsApprovedVendor]

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
        serializer = ProductSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        product = serializer.save(business_profile=business, created_by=request.user, updated_by=request.user)
        logger.info(f"Product '{product.name}' created by Approved Studio {business.business_name}")
        return Response(ProductSerializer(product).data, status=status.HTTP_201_CREATED)


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
        return Response(ProductSerializer(product).data, status=status.HTTP_200_OK)

    @extend_schema(summary="Update Showroom Product Specification", request=ProductSerializer, responses={200: ProductSerializer})
    def put(self, request, pk):
        product = self._get_product(request.user, pk)
        serializer = ProductSerializer(product, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save(updated_by=request.user)
        logger.info(f"Product '{product.name}' updated by Studio {request.user.phone_number}")
        return Response(serializer.data, status=status.HTTP_200_OK)

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
        serializer = OfferSerializer(data=request.data)
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
        serializer = OfferSerializer(offer, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save(updated_by=request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(summary="Revoke & Delete Promotional Offer", responses={204: None})
    def delete(self, request, pk):
        offer = self._get_offer(request.user, pk)
        offer.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
