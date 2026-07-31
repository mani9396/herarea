import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, exceptions
from drf_spectacular.utils import extend_schema, OpenApiResponse
from apps.accounts.permissions import IsVendorRole
from apps.business.models import BusinessProfile
from apps.business.serializers import BusinessProfileSerializer

logger = logging.getLogger('her_area')

class VendorBusinessProfileView(APIView):
    """
    Manage public business showroom identity, address coordinates, contact details, 
    and operation timing schedules for the authenticated partner studio vendor.
    """
    permission_classes = [IsVendorRole]

    def _get_business_profile(self, user):
        if not hasattr(user, 'vendor_profile') or not user.vendor_profile:
            raise exceptions.NotFound("No Vendor Profile exists for this account. Complete basic registration first.")
        if not hasattr(user.vendor_profile, 'business_profile') or not user.vendor_profile.business_profile:
            raise exceptions.NotFound("No Business Showroom Profile exists yet.")
        return user.vendor_profile.business_profile

    @extend_schema(
        summary="Get Partner Business Showroom Profile",
        description="Retrieve live address, contact phone/email, and daily timing schedules for this studio.",
        responses={200: BusinessProfileSerializer}
    )
    def get(self, request):
        business = self._get_business_profile(request.user)
        serializer = BusinessProfileSerializer(business)
        return Response(serializer.data, status=status.HTTP_200_OK)

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
