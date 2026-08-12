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
        from apps.vendors.models import VendorProfile, VendorStatus
        
        vendor, created = VendorProfile.objects.get_or_create(
            user=user,
            defaults={
                'owner_name': user.full_name or "Store Owner",
                'official_email': user.email or "",
                'phone_number': user.phone_number,
                'status': VendorStatus.PENDING,
                'created_by': user,
                'updated_by': user
            }
        )
        
        business, created = BusinessProfile.objects.get_or_create(
            vendor=vendor,
            defaults={
                'business_name': "New Boutique",
                'address_line_1': "To be updated",
                'city': "Unknown",
                'state': "Unknown",
                'postal_code': "000000",
                'contact_email': user.email or "",
                'contact_phone': user.phone_number or ""
            }
        )
        return business

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
