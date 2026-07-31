import logging
from django.utils import timezone
from django.db import transaction
from rest_framework import status, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiResponse
from apps.accounts.permissions import IsAdminRole
from apps.vendors.models import VendorProfile, VendorStatus, KycDocStatus
from apps.vendors.serializers import VendorProfileSerializer, AdminVendorActionSerializer
from apps.notifications.services import NotificationEngine
from apps.notifications.models import NotificationType

logger = logging.getLogger('her_area')

class AdminPendingVendorsListView(APIView):
    """
    Governance queue: Enumerate all partner studio vendor accounts awaiting administrative approval review.
    """
    permission_classes = [IsAdminRole]
    serializer_class = VendorProfileSerializer

    @extend_schema(
        summary="List Pending Vendor Studio Applications",
        description="Retrieve all partner studios currently in PENDING state along with submitted KYC documents and showroom details.",
        responses={200: VendorProfileSerializer(many=True)}
    )
    def get(self, request):
        vendors = VendorProfile.objects.filter(status=VendorStatus.PENDING).select_related('business_profile', 'user').prefetch_related('kyc_documents')
        serializer = VendorProfileSerializer(vendors, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class AdminVendorDetailView(APIView):
    """Inspect full legal KYC audit trail, showroom profile, and operational contacts of any partner vendor."""
    permission_classes = [IsAdminRole]
    serializer_class = VendorProfileSerializer

    @extend_schema(summary="Get Vendor Application & KYC Dossier", responses={200: VendorProfileSerializer})
    def get(self, request, pk):
        try:
            vendor = VendorProfile.objects.select_related('business_profile').prefetch_related('kyc_documents').get(pk=pk)
        except VendorProfile.DoesNotExist:
            raise exceptions.NotFound("Vendor studio profile not found in governance repository.")
        serializer = VendorProfileSerializer(vendor)
        return Response(serializer.data, status=status.HTTP_200_OK)


class AdminVendorApproveView(APIView):
    """
    Execute executive marketplace approval: Grants live studio status, verifies submitted KYC files, 
    and authorizes showroom catalog management capabilities.
    """
    permission_classes = [IsAdminRole]
    serializer_class = VendorProfileSerializer

    @extend_schema(
        summary="Approve Partner Studio Vendor",
        description="Verify vendor legal compliance and grant live APPROVED marketplace status.",
        request=None,
        responses={200: VendorProfileSerializer}
    )
    def post(self, request, pk):
        try:
            vendor = VendorProfile.objects.get(pk=pk)
        except VendorProfile.DoesNotExist:
            raise exceptions.NotFound("Target vendor profile does not exist.")

        with transaction.atomic():
            vendor.status = VendorStatus.APPROVED
            vendor.approved_by = request.user
            vendor.approved_at = timezone.now()
            vendor.rejection_reason = ""
            vendor.updated_by = request.user
            vendor.save(update_fields=['status', 'approved_by', 'approved_at', 'rejection_reason', 'updated_by'])

            # Automatically stamp pending KYC documentation as officially verified
            vendor.kyc_documents.filter(status=KycDocStatus.PENDING).update(
                status=KycDocStatus.VERIFIED,
                verified_by=request.user,
                verified_at=timezone.now()
            )

        logger.info(f"Vendor {vendor.owner_name} ({vendor.id}) officially APPROVED by Admin {request.user.phone_number}")
        NotificationEngine.send_notification(
            recipient=vendor.user,
            title="Studio Onboarding Approved!",
            message="Congratulations! Your partner studio application has been approved. You can now publish products, services, gallery images, and promotional offers.",
            notification_type=NotificationType.ONBOARDING,
            action_url="/vendor/dashboard"
        )
        serializer = VendorProfileSerializer(vendor)
        return Response(serializer.data, status=status.HTTP_200_OK)


class AdminVendorRejectView(APIView):
    """Deny onboarding application with mandatory rejection feedback reasoning for studio correction."""
    permission_classes = [IsAdminRole]
    serializer_class = AdminVendorActionSerializer

    @extend_schema(
        summary="Reject Partner Studio Application",
        description="Deny vendor approval and record mandatory rejection explanation for user visibility.",
        request=AdminVendorActionSerializer,
        responses={200: VendorProfileSerializer}
    )
    def post(self, request, pk):
        try:
            vendor = VendorProfile.objects.get(pk=pk)
        except VendorProfile.DoesNotExist:
            raise exceptions.NotFound("Target vendor profile does not exist.")

        serializer = AdminVendorActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        reason = serializer.validated_data['rejection_reason']

        with transaction.atomic():
            vendor.status = VendorStatus.REJECTED
            vendor.rejection_reason = reason
            vendor.updated_by = request.user
            vendor.save(update_fields=['status', 'rejection_reason', 'updated_by'])

            vendor.kyc_documents.filter(status=KycDocStatus.PENDING).update(status=KycDocStatus.REJECTED)

        logger.warning(f"Vendor {vendor.owner_name} REJECTED by Admin {request.user.phone_number}. Reason: {reason}")
        NotificationEngine.send_notification(
            recipient=vendor.user,
            title="Studio Application Update",
            message=f"Your onboarding application requires modification before clearance. Reason: {reason}",
            notification_type=NotificationType.ONBOARDING,
            action_url="/vendor/profile/edit"
        )
        response_serializer = VendorProfileSerializer(vendor)
        return Response(response_serializer.data, status=status.HTTP_200_OK)


class AdminVendorSuspendView(APIView):
    """Temporarily revoke active catalog privileges and suspend operational studio status."""
    permission_classes = [IsAdminRole]
    serializer_class = AdminVendorActionSerializer

    @extend_schema(
        summary="Suspend Active Partner Studio",
        description="Temporarily disable showroom catalog access and transition account state to SUSPENDED.",
        request=AdminVendorActionSerializer,
        responses={200: VendorProfileSerializer}
    )
    def post(self, request, pk):
        try:
            vendor = VendorProfile.objects.get(pk=pk)
        except VendorProfile.DoesNotExist:
            raise exceptions.NotFound("Target vendor profile does not exist.")

        serializer = AdminVendorActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        reason = serializer.validated_data['rejection_reason']

        vendor.status = VendorStatus.SUSPENDED
        vendor.rejection_reason = reason
        vendor.updated_by = request.user
        vendor.save(update_fields=['status', 'rejection_reason', 'updated_by'])

        logger.warning(f"Vendor {vendor.owner_name} SUSPENDED by Admin {request.user.phone_number}. Reason: {reason}")
        NotificationEngine.send_notification(
            recipient=vendor.user,
            title="Studio Account Suspended",
            message=f"Your studio catalog access has been temporarily suspended by an Administrator. Reason: {reason}",
            notification_type=NotificationType.ONBOARDING,
            action_url="/vendor/support"
        )
        response_serializer = VendorProfileSerializer(vendor)
        return Response(response_serializer.data, status=status.HTTP_200_OK)
