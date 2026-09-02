import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, exceptions
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from drf_spectacular.utils import extend_schema, OpenApiResponse
from apps.accounts.permissions import IsVendorRole
from apps.business.models import BusinessProfile, StoreMedia
from apps.business.serializers import BusinessProfileSerializer, StoreMediaSerializer

logger = logging.getLogger('her_area')

class VendorBusinessProfileView(APIView):
    """
    Manage public business showroom identity, address coordinates, contact details, 
    and operation timing schedules for the authenticated partner studio vendor.
    """
    permission_classes = [IsVendorRole]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def _get_business_profile(self, user):
        from apps.vendors.models import VendorProfile
        try:
            vendor = VendorProfile.objects.get(user=user)
            return vendor.business_profile
        except (VendorProfile.DoesNotExist, BusinessProfile.DoesNotExist):
            return None

    @extend_schema(
        summary="Get Partner Business Showroom Profile",
        description="Retrieve live address, contact phone/email, and daily timing schedules for this studio. Returns 404 if not set up.",
        responses={200: BusinessProfileSerializer}
    )
    def get(self, request):
        business = self._get_business_profile(request.user)
        if not business:
            return Response({"detail": "Store profile not set up yet."}, status=status.HTTP_404_NOT_FOUND)
        serializer = BusinessProfileSerializer(business)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Create Business Showroom Profile",
        description="Create the initial store profile for the authenticated vendor.",
        request=BusinessProfileSerializer,
        responses={201: BusinessProfileSerializer}
    )
    def post(self, request):
        from apps.vendors.models import VendorProfile, VendorStatus
        vendor, _ = VendorProfile.objects.get_or_create(
            user=request.user,
            defaults={
                'owner_name': request.user.full_name or "Store Owner",
                'official_email': request.user.email or "",
                'phone_number': request.user.phone_number,
                'status': VendorStatus.PENDING,
                'created_by': request.user,
                'updated_by': request.user
            }
        )
        
        if hasattr(vendor, 'business_profile'):
            raise exceptions.ValidationError("Store profile already exists. Use PUT/PATCH to update.")

        serializer = BusinessProfileSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(vendor=vendor, created_by=request.user, updated_by=request.user)
        logger.info(f"Business Profile created by Vendor {request.user.phone_number}")
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @extend_schema(
        summary="Update Business Showroom Profile & Timings",
        description="Modify studio street address, contact support endpoints, or daily business operational timings.",
        request=BusinessProfileSerializer,
        responses={200: BusinessProfileSerializer}
    )
    def put(self, request):
        business = self._get_business_profile(request.user)
        serializer = BusinessProfileSerializer(business, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save(updated_by=request.user)
        logger.info(f"Business Profile {business.id} updated by Vendor {request.user.phone_number}")
        return Response(serializer.data, status=status.HTTP_200_OK)


class VendorStoreMediaListView(APIView):
    """
    List or add gallery images to the vendor's Store.
    """
    permission_classes = [IsVendorRole]
    parser_classes = [MultiPartParser, FormParser]

    def _get_business_profile(self, user):
        if not hasattr(user, 'vendor_profile') or not user.vendor_profile:
            raise exceptions.PermissionDenied("You must submit vendor onboarding first.")
        if not hasattr(user.vendor_profile, 'business_profile'):
            raise exceptions.NotFound("Business profile not found. Complete studio setup first.")
        return user.vendor_profile.business_profile

    @extend_schema(summary="List Store Gallery Images", responses={200: StoreMediaSerializer(many=True)})
    def get(self, request):
        business = self._get_business_profile(request.user)
        media = business.gallery.all()
        serializer = StoreMediaSerializer(media, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(summary="Add Store Gallery Image", request=StoreMediaSerializer, responses={201: StoreMediaSerializer})
    def post(self, request):
        business = self._get_business_profile(request.user)
        
        # Enforce 10 image limit
        if business.gallery.count() >= 10:
            raise exceptions.ValidationError("Maximum of 10 gallery images allowed per store.")

        serializer = StoreMediaSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(
            business_profile=business,
            created_by=request.user,
            updated_by=request.user
        )
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class VendorStoreMediaDetailView(APIView):
    """
    Manage an individual gallery image.
    """
    permission_classes = [IsVendorRole]

    def _get_media(self, request, pk):
        if not hasattr(request.user, 'vendor_profile') or not hasattr(request.user.vendor_profile, 'business_profile'):
            raise exceptions.PermissionDenied("Business profile not found.")
        business = request.user.vendor_profile.business_profile
        try:
            return StoreMedia.objects.get(pk=pk, business_profile=business)
        except StoreMedia.DoesNotExist:
            raise exceptions.NotFound("Media not found or you don't have permission to modify it.")

    @extend_schema(summary="Delete Store Gallery Image", responses={204: OpenApiResponse(description="Deleted")})
    def delete(self, request, pk):
        media = self._get_media(request, pk)
        media.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

class VendorStoreSubmitView(APIView):
    """
    Submits a draft or rejected store for admin approval.
    """
    permission_classes = [IsVendorRole]

    @extend_schema(
        summary="Submit Store for Admin Approval",
        description="Transitions the store status to PENDING_APPROVAL. Fails if the store is incomplete.",
        responses={200: OpenApiResponse(description="Store submitted successfully"), 400: OpenApiResponse(description="Validation error")}
    )
    def post(self, request):
        if not hasattr(request.user, 'vendor_profile') or not hasattr(request.user.vendor_profile, 'business_profile'):
            raise exceptions.NotFound("Business profile not found. Please complete the setup.")
        
        business = request.user.vendor_profile.business_profile
        
        from apps.business.models import StoreStatus
        if business.status in [StoreStatus.PENDING_APPROVAL, StoreStatus.PUBLISHED]:
            return Response({"detail": f"Store is already {business.status}"}, status=status.HTTP_400_BAD_REQUEST)
            
        missing_fields = []
        if not business.address_line_1: missing_fields.append("address_line_1")
        if not business.city: missing_fields.append("city")
        if not business.latitude or not business.longitude: missing_fields.append("location coordinates")
        if not business.contact_phone: missing_fields.append("contact_phone")
        if not business.category: missing_fields.append("category")
        
        if missing_fields:
            missing_str = ", ".join(missing_fields)
            return Response({
                "detail": f"Store profile is incomplete. Missing: {missing_str}",
                "missing": missing_fields
            }, status=status.HTTP_400_BAD_REQUEST)
            
        if not business.cover_image:
            return Response({"detail": "A cover image is required."}, status=status.HTTP_400_BAD_REQUEST)
            
        from apps.catalog.models import Product
        if not Product.objects.filter(business_profile=business).exists():
            return Response({"detail": "You must add at least one product before submitting your store."}, status=status.HTTP_400_BAD_REQUEST)
            
        if not business.is_listing_eligible:
            return Response({"detail": "An active listing subscription is required before submitting your store."}, status=status.HTTP_400_BAD_REQUEST)
            
        business.status = StoreStatus.PENDING_APPROVAL
        business.save(update_fields=['status'])
        
        logger.info(f"Business Profile {business.id} submitted for approval by Vendor {request.user.phone_number}")
        return Response({"detail": "Store submitted for review."}, status=status.HTTP_200_OK)
