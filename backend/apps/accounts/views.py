import logging
from rest_framework import serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status
from rest_framework_simplejwt.tokens import RefreshToken
from drf_spectacular.utils import extend_schema, OpenApiResponse
from apps.accounts.models import User
from apps.accounts.serializers import UserSerializer, OtpSendSerializer, OtpVerifySerializer
from apps.accounts.permissions import IsCustomerRole, IsVendorRole, IsAdminRole, IsSuperAdminRole

logger = logging.getLogger('her_area')

class OtpSendView(APIView):
    """
    Dispatch cryptographic OTP challenge to mobile handset via Twilio/WhatsApp gateway simulation.
    In development & Sprint 1 validation, always issues standard dev code '123456'.
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Request Passwordless OTP Code",
        description="Initiate login or signup flow by dispatching a 6-digit SMS OTP challenge.",
        request=OtpSendSerializer,
        responses={
            200: OpenApiResponse(description="OTP successfully dispatched to handset.")
        }
    )
    def post(self, request):
        serializer = OtpSendSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data['phone_number']
        logger.info(f"Dispatching OTP challenge to {phone}")

        return Response({
            "message": "OTP challenge dispatched successfully.",
            "expires_in_seconds": 300,
            "dev_test_otp": "123456",
        }, status=status.HTTP_200_OK)


class OtpVerifyView(APIView):
    """
    Verify 6-digit OTP code and return secure short-lived JWT Access Token & rotating Refresh Token.
    Creates new account identity if phone number is first-time visitor.
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Validate OTP & Obtain JWT Credentials",
        description="Exchange valid SMS OTP for signed JWT bearer token and user role assertions.",
        request=OtpVerifySerializer,
        responses={
            200: OpenApiResponse(description="Successful authentication credentials granted."),
            400: OpenApiResponse(description="Invalid verification OTP.")
        }
    )
    def post(self, request):
        serializer = OtpVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data['phone_number']
        otp = serializer.validated_data['otp']
        requested_role = serializer.validated_data.get('role', 'CUSTOMER')

        if otp != "123456":
            raise serializers.ValidationError("Invalid OTP cryptographic signature.")

        user, created = User.objects.get_or_create(
            phone_number=phone,
            defaults={"role": requested_role, "is_verified": True}
        )
        if not created and not user.is_verified:
            user.is_verified = True
            user.save(update_fields=['is_verified'])

        refresh = RefreshToken.for_user(user)
        refresh['role'] = user.role
        refresh['phone_number'] = user.phone_number

        logger.info(f"User {user.id} ({user.role}) authenticated successfully.")

        return Response({
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "user_id": str(user.id),
            "role": user.role,
            "is_new_user": created,
        }, status=status.HTTP_200_OK)


class UserProfileView(APIView):
    """Retrieve or inspect authenticated user identity profile."""
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(summary="Get Current Authenticated Identity", responses=UserSerializer)
    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)


# RBAC Verification Endpoints for Automated Test and Swagger Auditing
class CustomerRoleVerificationView(APIView):
    permission_classes = [IsCustomerRole]
    @extend_schema(summary="Verify Customer Role Access", responses={200: OpenApiResponse(description="Verified Customer Tier.")})
    def get(self, request):
        return Response({"message": "Access granted: Verified Customer Tier."})

class VendorRoleVerificationView(APIView):
    permission_classes = [IsVendorRole]
    @extend_schema(summary="Verify Vendor Role Access", responses={200: OpenApiResponse(description="Verified Vendor Tier.")})
    def get(self, request):
        return Response({"message": "Access granted: Verified Partner Studio Vendor Tier."})

class AdminRoleVerificationView(APIView):
    permission_classes = [IsAdminRole]
    @extend_schema(summary="Verify Admin Role Access", responses={200: OpenApiResponse(description="Verified Admin Tier.")})
    def get(self, request):
        return Response({"message": "Access granted: Verified Governance Admin Tier."})

class SuperAdminRoleVerificationView(APIView):
    permission_classes = [IsSuperAdminRole]
    @extend_schema(summary="Verify SuperAdmin Role Access", responses={200: OpenApiResponse(description="Verified SuperAdmin Tier.")})
    def get(self, request):
        return Response({"message": "Access granted: Verified Founder Superadmin Tier."})
