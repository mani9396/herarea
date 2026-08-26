import logging
from django.db import transaction
from rest_framework import status, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiResponse
from apps.accounts.permissions import IsVendorRole
from apps.vendors.models import VendorProfile, VendorStatus, KycDocument
from apps.vendors.serializers import (
    VendorProfileSerializer, 
    VendorOnboardingRegistrationSerializer, 
    KycDocumentSerializer
)
from apps.business.models import BusinessProfile
from apps.vendors.permissions import IsApprovedVendor

logger = logging.getLogger('her_area')




class VendorProfileMeView(APIView):
    """Inspect or update authenticated vendor legal identity profile."""
    permission_classes = [IsVendorRole]

    def _get_vendor(self, user):
        if not hasattr(user, 'vendor_profile') or not user.vendor_profile:
            raise exceptions.NotFound("Vendor profile not found. Submit onboarding application first.")
        return user.vendor_profile

    @extend_schema(summary="Get Authenticated Vendor Status & Profile", responses={200: VendorProfileSerializer})
    def get(self, request):
        vendor = self._get_vendor(request.user)
        serializer = VendorProfileSerializer(vendor)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(summary="Update Vendor Legal Owner Details", request=VendorProfileSerializer, responses={200: VendorProfileSerializer})
    def put(self, request):
        vendor = self._get_vendor(request.user)
        serializer = VendorProfileSerializer(vendor, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save(updated_by=request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)


class VendorKycDocumentView(APIView):
    """
    Step 2 of Vendor Onboarding: Upload mandatory legal compliance documents (GSTIN, PAN, Trade License, Address Proof) 
    for admin audit and verification.
    """
    permission_classes = [IsVendorRole]

    def _get_vendor(self, user):
        if not hasattr(user, 'vendor_profile') or not user.vendor_profile:
            raise exceptions.NotFound("Vendor profile required before uploading KYC compliance documentation.")
        return user.vendor_profile

    @extend_schema(summary="List Submitted KYC Compliance Documents", responses={200: KycDocumentSerializer(many=True)})
    def get(self, request):
        vendor = self._get_vendor(request.user)
        docs = vendor.kyc_documents.all()
        serializer = KycDocumentSerializer(docs, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(summary="Submit KYC Legal Document File", request=KycDocumentSerializer, responses={201: KycDocumentSerializer})
    def post(self, request):
        vendor = self._get_vendor(request.user)
        serializer = KycDocumentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        doc = serializer.save(vendor=vendor, created_by=request.user, updated_by=request.user)
        logger.info(f"KYC Document ({doc.document_type}) submitted by Vendor {vendor.owner_name}")
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class ApprovedVendorCatalogTestView(APIView):
    """
    RBAC Governance Checkpoint: Verifies that ONLY vendors with an APPROVED administrative status 
    can pass through to catalog management operations.
    """
    permission_classes = [IsApprovedVendor]

    @extend_schema(
        summary="Verify Approved Partner Studio Clearance",
        responses={
            200: OpenApiResponse(description="Authorized: Approved partner studio account."),
            403: OpenApiResponse(description="Forbidden: Account status is PENDING, REJECTED, or SUSPENDED.")
        }
    )
    def get(self, request):
        return Response({
            "status": "authorized",
            "message": "Access Granted: Approved Partner Studio account. You are cleared to manage showrooms, products, and promotional offers."
        }, status=status.HTTP_200_OK)

class VendorSelfRegistrationView(APIView):
    """
    Path B Vendor Registration: Allow unauthenticated vendors to register and create an account.
    """
    permission_classes = [] # Public API

    @extend_schema(
        summary="Self Register Partner Studio Vendor",
        description="Public endpoint for vendors to self-register. Creates User and VendorProfile in PENDING status.",
        responses={201: OpenApiResponse(description="Vendor registered successfully.")}
    )
    def post(self, request):
        from apps.accounts.models import User, UserRole # Local import to avoid circular imports if any, or just import here
        from apps.vendors.serializers import VendorSelfRegistrationSerializer
        
        serializer = VendorSelfRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        email = data['email'].lower()
        if User.objects.filter(email=email).exists():
            raise exceptions.ValidationError({"email": ["A user with this email already exists."]})
            
        phone = data['phone_number']
        if User.objects.filter(phone_number=phone).exists():
            raise exceptions.ValidationError({"phone_number": ["A user with this phone number already exists."]})

        with transaction.atomic():
            user = User.objects.create(
                phone_number=phone,
                email=email,
                full_name=data['owner_name'],
                role=UserRole.VENDOR,
                is_active=True,
                is_verified=False, # Wait, let's keep is_verified true for now or false, the prompt says no SMS OTP, so let's set is_verified=True or we might need email verification later.
                must_change_password=False,
            )
            user.set_password(data['password'])
            user.save()

            vendor = VendorProfile.objects.create(
                user=user,
                owner_name=data['owner_name'],
                official_email=email,
                phone_number=phone,
                status=VendorStatus.PENDING,
                created_by=user,
                updated_by=user
            )

            # BusinessProfile creation is deferred until the Vendor completes
            # the onboarding flow from the frontend via POST /api/v1/business/me/

        logger.info(f"Vendor self-registered: {email}")
        
        return Response({
            "message": "Vendor registered successfully. Awaiting approval."
        }, status=status.HTTP_201_CREATED)
