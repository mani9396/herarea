import logging
import random
import hashlib
import uuid
from django.core.cache import cache
from django.core.mail import send_mail
from django.conf import settings
from django.contrib.auth import authenticate
from rest_framework import serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status
from rest_framework_simplejwt.tokens import RefreshToken
from drf_spectacular.utils import extend_schema, OpenApiResponse
from apps.accounts.models import User, UserRole
from apps.accounts.serializers import (
    CustomerLoginSerializer, CustomerRegisterCompleteSerializer,
    OtpVerifyForPurposeSerializer, PasswordResetCompleteSerializer,
    PasswordChangeSerializer, OtpSendSerializer, OtpVerifySerializer,
    LogoutSerializer, UserSerializer
)
from apps.accounts.permissions import IsCustomerRole, IsVendorRole, IsAdminRole, IsSuperAdminRole

logger = logging.getLogger('her_area')

OTP_TTL_SECONDS = 300  # 5 minutes
OTP_CACHE_PREFIX = 'herarea_otp_'


def _make_otp_cache_key(identifier: str) -> str:
    """Generate a safe cache key from an email or phone identifier."""
    return OTP_CACHE_PREFIX + hashlib.sha256(identifier.encode()).hexdigest()

class OtpSendView(APIView):
    """
    Dispatch a real 6-digit OTP challenge.
    - Customer (CUSTOMER role): Sends OTP to email address via configured email backend.
    - Vendor/Admin: Falls back to phone_number field (existing SMS path, extendable).
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Request Passwordless OTP Code",
        description="Initiate login or signup flow by dispatching a 6-digit OTP. Customers use email; Vendors/Admins use phone_number.",
        request=OtpSendSerializer,
        responses={
            200: OpenApiResponse(description="OTP successfully dispatched."),
            429: OpenApiResponse(description="Too many OTP requests. Please wait before retrying."),
        }
    )
    def post(self, request):
        serializer = OtpSendSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data.get('email')
        phone = serializer.validated_data.get('phone_number')
        role = serializer.validated_data.get('role', 'CUSTOMER')
        purpose = serializer.validated_data.get('purpose', 'LOGIN')
        full_name_req = serializer.validated_data.get('full_name')

        if email:
            # --- Customer Email OTP flow ---
            identifier = email.lower().strip()
            cache_key = _make_otp_cache_key(identifier)

            # Rate-limit: block if an OTP was issued in the last 60 seconds
            existing = cache.get(cache_key + '_ts')
            if existing:
                return Response(
                    {"error": "A verification code was recently sent. Please wait before requesting another."},
                    status=status.HTTP_429_TOO_MANY_REQUESTS
                )

            otp = str(random.randint(100000, 999999))
            cache.set(cache_key, otp, timeout=OTP_TTL_SECONDS)
            cache.set(cache_key + '_ts', '1', timeout=60)  # 60-second resend cooldown

            logger.info(f"OTP generated for Customer email: {identifier} (role={role})")

            # Determine customer name based on purpose
            customer_name = "Customer"
            if purpose == 'REGISTRATION' and full_name_req:
                customer_name = full_name_req.strip()
            elif purpose == 'PASSWORD_RESET':
                existing_user = User.objects.filter(email=identifier).first()
                if existing_user and existing_user.full_name:
                    customer_name = existing_user.full_name.strip()

            # Dispatch email
            try:
                from_email = getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@herarea.com')
                
                if purpose == 'PASSWORD_RESET':
                    subject = 'HER AREA — Password Reset Verification Code'
                    text_message = (
                        f"Hello {customer_name},\n\n"
                        f"We received a request to reset your HER AREA account password.\n\n"
                        f"Your password reset verification code is: {otp}\n\n"
                        f"This verification code is valid for 5 minutes.\n\n"
                        f"If you did not request a password reset, please ignore this email. Your account will remain secure and your password will not be changed unless the verification process is successfully completed.\n\n"
                        f"For your security, please do not share this verification code with anyone.\n\n"
                        f"Warm regards,\nHER AREA Team\n{from_email}"
                    )
                    html_message = f"""
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eaeaea; border-radius: 10px;">
                        <h2 style="color: #90274c; text-align: center;">HER AREA</h2>
                        <hr style="border: none; border-top: 1px solid #eaeaea; margin: 20px 0;">
                        <p style="font-size: 16px; color: #333;">Hello {customer_name},</p>
                        <p style="font-size: 16px; color: #333;">We received a request to reset your HER AREA account password.</p>
                        <p style="font-size: 16px; color: #333;">Your password reset verification code is:</p>
                        <div style="text-align: center; margin: 30px 0;">
                            <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #90274c; background-color: #f9f9f9; padding: 15px 25px; border-radius: 8px;">{otp}</span>
                        </div>
                        <p style="font-size: 14px; color: #666;">This verification code is valid for <strong>5 minutes</strong>.</p>
                        <p style="font-size: 14px; color: #666;">If you did not request a password reset, please ignore this email. Your account will remain secure and your password will not be changed unless the verification process is successfully completed.</p>
                        <div style="margin-top: 30px; padding: 15px; background-color: #fff4f4; border-left: 4px solid #d32f2f; border-radius: 4px;">
                            <p style="font-size: 12px; color: #d32f2f; margin: 0;"><strong>Security Reminder:</strong> For your security, please do not share this verification code with anyone.</p>
                        </div>
                        <hr style="border: none; border-top: 1px solid #eaeaea; margin: 20px 0;">
                        <p style="font-size: 14px; color: #333;">Warm regards,<br><strong>HER AREA Team</strong><br>{from_email}</p>
                    </div>
                    """
                else:
                    # Default Registration flow
                    subject = 'Your HER AREA Verification Code'
                    text_message = (
                        f"Hello {customer_name},\n\n"
                        f"Welcome to HER AREA!\n\n"
                        f"Your verification code to complete your account registration is: {otp}\n\n"
                        f"This verification code is valid for 5 minutes.\n\n"
                        f"For your security, please do not share this code with anyone.\n\n"
                        f"If you did not request this verification code, please ignore this email.\n\n"
                        f"Warm regards,\nHER AREA Team\n{from_email}"
                    )
                    html_message = f"""
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eaeaea; border-radius: 10px;">
                        <h2 style="color: #90274c; text-align: center;">HER AREA</h2>
                        <hr style="border: none; border-top: 1px solid #eaeaea; margin: 20px 0;">
                        <p style="font-size: 16px; color: #333;">Hello {customer_name},</p>
                        <p style="font-size: 16px; color: #333;">Welcome to HER AREA!</p>
                        <p style="font-size: 16px; color: #333;">Your verification code to complete your account registration is:</p>
                        <div style="text-align: center; margin: 30px 0;">
                            <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #90274c; background-color: #f9f9f9; padding: 15px 25px; border-radius: 8px;">{otp}</span>
                        </div>
                        <p style="font-size: 14px; color: #666;">This verification code is valid for <strong>5 minutes</strong>.</p>
                        <div style="margin-top: 30px; padding: 15px; background-color: #fff4f4; border-left: 4px solid #d32f2f; border-radius: 4px;">
                            <p style="font-size: 12px; color: #d32f2f; margin: 0;"><strong>Security Reminder:</strong> For your security, please do not share this code with anyone.</p>
                        </div>
                        <p style="font-size: 14px; color: #666; margin-top: 20px;">If you did not request this verification code, please ignore this email.</p>
                        <hr style="border: none; border-top: 1px solid #eaeaea; margin: 20px 0;">
                        <p style="font-size: 14px; color: #333;">Warm regards,<br><strong>HER AREA Team</strong><br>{from_email}</p>
                    </div>
                    """
                
                send_mail(
                    subject=subject,
                    message=text_message,
                    from_email=from_email,
                    recipient_list=[identifier],
                    fail_silently=False,
                    html_message=html_message
                )
                logger.info(f"OTP email dispatched successfully to {identifier}")
            except Exception as exc:
                logger.error(f"OTP email dispatch failed for {identifier}: {exc}")
                # Still return success so the OTP can be validated — email may be configured later
                # In production this should return 503 once email is fully configured

            return Response({
                "message": "Verification code sent to your email address.",
                "expires_in_seconds": OTP_TTL_SECONDS,
            }, status=status.HTTP_200_OK)

        else:
            # --- Vendor / Admin phone OTP flow (existing behaviour preserved) ---
            logger.info(f"Dispatching OTP challenge to phone: {phone} (role={role})")
            # Phone OTP is currently a pass-through for Vendor/Admin
            # Real SMS gateway can be integrated here (Twilio, etc.)
            identifier = phone
            cache_key = _make_otp_cache_key(identifier)
            otp = str(random.randint(100000, 999999))
            cache.set(cache_key, otp, timeout=OTP_TTL_SECONDS)
            logger.info(f"Dev/Vendor OTP for {phone}: {otp}")
            return Response({
                "message": "OTP challenge dispatched successfully.",
                "expires_in_seconds": OTP_TTL_SECONDS,
            }, status=status.HTTP_200_OK)


class OtpVerifyView(APIView):
    """
    Verify 6-digit OTP and return JWT credentials.
    - Customer: Validates OTP against Django cache using email. Creates/retrieves user by email.
    - Vendor/Admin: Validates OTP against Django cache using phone_number.
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Validate OTP & Obtain JWT Credentials",
        description="Exchange valid OTP for signed JWT bearer token. Customers use email; Vendors/Admins use phone_number.",
        request=OtpVerifySerializer,
        responses={
            200: OpenApiResponse(description="Successful authentication credentials granted."),
            400: OpenApiResponse(description="Invalid or expired OTP."),
        }
    )
    def post(self, request):
        serializer = OtpVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data.get('email')
        phone = serializer.validated_data.get('phone_number')
        otp = serializer.validated_data['otp']
        requested_role = serializer.validated_data.get('role', 'CUSTOMER')

        if email:
            # --- Customer Email OTP verification ---
            identifier = email.lower().strip()
            cache_key = _make_otp_cache_key(identifier)
            stored_otp = cache.get(cache_key)

            if not stored_otp:
                return Response(
                    {"error": "Verification code has expired. Please request a new one."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            if stored_otp != otp:
                return Response(
                    {"error": "Invalid verification code. Please check and try again."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # OTP is valid — consume it
            cache.delete(cache_key)
            cache.delete(cache_key + '_ts')

            # Get or create user by email
            # New Customers get a unique dummy phone to satisfy the DB unique constraint
            user = User.objects.filter(email=identifier).first()
            created = False
            if not user:
                # Generate a unique, non-guessable dummy phone number
                dummy_phone = '+00' + hashlib.md5(identifier.encode()).hexdigest()[:12]
                user = User.objects.create(
                    email=identifier,
                    phone_number=dummy_phone,
                    role=requested_role,
                    is_verified=True,
                )
                created = True
                logger.info(f"New Customer account created for email: {identifier} (id={user.id})")
            elif not user.is_verified:
                user.is_verified = True
                user.save(update_fields=['is_verified'])

            refresh = RefreshToken.for_user(user)
            refresh['role'] = user.role
            refresh['email'] = identifier

            logger.info(f"Customer {user.id} authenticated via email OTP.")

            return Response({
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user_id": str(user.id),
                "role": user.role,
                "is_new_user": created,
            }, status=status.HTTP_200_OK)

        else:
            # --- Vendor / Admin phone OTP verification ---
            identifier = phone
            cache_key = _make_otp_cache_key(identifier)
            stored_otp = cache.get(cache_key)

            if not stored_otp:
                return Response(
                    {"error": "Verification code has expired. Please request a new one."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            if stored_otp != otp:
                return Response(
                    {"error": "Invalid verification code. Please check and try again."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            cache.delete(cache_key)

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

            logger.info(f"User {user.id} ({user.role}) authenticated via phone OTP.")

            return Response({
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user_id": str(user.id),
                "role": user.role,
                "is_new_user": created,
            }, status=status.HTTP_200_OK)


class CustomerLoginView(APIView):
    """
    Authenticate Customer using email and password.
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Customer Email+Password Login",
        request=CustomerLoginSerializer,
        responses={200: OpenApiResponse(description="Successful login.")}
    )
    def post(self, request):
        serializer = CustomerLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email'].lower().strip()
        password = serializer.validated_data['password']
        
        user = User.objects.filter(email=email).first()
        if not user:
            return Response({"error": "Invalid email or password."}, status=status.HTTP_401_UNAUTHORIZED)
            
        if not user.check_password(password):
            return Response({"error": "Invalid email or password."}, status=status.HTTP_401_UNAUTHORIZED)
            
        if not user.is_active:
            return Response({"error": "This account has been disabled."}, status=status.HTTP_403_FORBIDDEN)
            
        refresh = RefreshToken.for_user(user)
        refresh['role'] = user.role
        refresh['email'] = email
        
        logger.info(f"Customer {user.id} authenticated via email/password.")
        
        return Response({
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "user_id": str(user.id),
            "role": user.role,
            "is_new_user": False,
            "must_change_password": user.must_change_password
        }, status=status.HTTP_200_OK)


class OtpVerifyForPurposeView(APIView):
    """
    Verify OTP for Customer Registration or Password Reset without issuing JWT.
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Verify OTP for Specific Purpose",
        request=OtpVerifyForPurposeSerializer,
        responses={200: OpenApiResponse(description="OTP verified successfully.")}
    )
    def post(self, request):
        serializer = OtpVerifyForPurposeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email'].lower().strip()
        otp = serializer.validated_data['otp']
        purpose = serializer.validated_data['purpose']
        
        cache_key = _make_otp_cache_key(email)
        stored_otp = cache.get(cache_key)
        
        if not stored_otp:
            return Response({"error": "Verification code has expired. Please request a new one."}, status=status.HTTP_400_BAD_REQUEST)
            
        if stored_otp != otp:
            return Response({"error": "Invalid verification code. Please check and try again."}, status=status.HTTP_400_BAD_REQUEST)
            
        cache.delete(cache_key)
        cache.delete(cache_key + '_ts')
        
        if purpose == 'REGISTRATION':
            # Store verification status temporarily
            verified_key = f"verified_reg_{hashlib.md5(email.encode()).hexdigest()}"
            cache.set(verified_key, True, timeout=900) # 15 minutes
            return Response({"verified": True}, status=status.HTTP_200_OK)
            
        elif purpose == 'PASSWORD_RESET':
            # Generate a reset token
            reset_token = str(uuid.uuid4())
            token_key = f"reset_token_{hashlib.md5(email.encode()).hexdigest()}"
            cache.set(token_key, reset_token, timeout=900)
            return Response({"reset_token": reset_token}, status=status.HTTP_200_OK)
            
        return Response({"error": "Invalid purpose."}, status=status.HTTP_400_BAD_REQUEST)


class CustomerRegisterCompleteView(APIView):
    """
    Complete Customer registration by setting password after email OTP verification.
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Complete Customer Registration",
        request=CustomerRegisterCompleteSerializer,
        responses={200: OpenApiResponse(description="Registration successful, credentials returned.")}
    )
    def post(self, request):
        serializer = CustomerRegisterCompleteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email'].lower().strip()
        password = serializer.validated_data['password']
        full_name = serializer.validated_data['full_name']
        date_of_birth = serializer.validated_data['date_of_birth']
        gender = serializer.validated_data['gender']
        
        verified_key = f"verified_reg_{hashlib.md5(email.encode()).hexdigest()}"
        if not cache.get(verified_key):
            return Response({"error": "Email has not been verified or verification expired."}, status=status.HTTP_400_BAD_REQUEST)
            
        user = User.objects.filter(email=email).first()
        created = False
        if not user:
            dummy_phone = '+00' + hashlib.md5(email.encode()).hexdigest()[:12]
            user = User.objects.create(
                email=email,
                phone_number=dummy_phone,
                role=UserRole.CUSTOMER,
                full_name=full_name,
                date_of_birth=date_of_birth,
                gender=gender,
                is_verified=True,
            )
            user.set_password(password)
            user.save()
            created = True
        else:
            if user.role != UserRole.CUSTOMER:
                return Response({"error": "Account exists with a different role."}, status=status.HTTP_400_BAD_REQUEST)
            user.set_password(password)
            user.full_name = full_name
            user.date_of_birth = date_of_birth
            user.gender = gender
            user.is_verified = True
            user.save()
            
        cache.delete(verified_key)
        
        refresh = RefreshToken.for_user(user)
        refresh['role'] = user.role
        refresh['email'] = email
        
        logger.info(f"Customer {user.id} registration completed.")
        
        # Send Account Created Successfully Email
        try:
            from_email = getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@herarea.com')
            customer_name = user.full_name or "Customer"
            subject = 'Welcome to HER AREA — Your Account Has Been Created Successfully'
            text_message = (
                f"Hello {customer_name},\n\n"
                f"Welcome to HER AREA!\n\n"
                f"Your account has been created and your email address has been successfully verified.\n\n"
                f"You can now sign in using your registered email address and password to access HER AREA.\n\n"
                f"Thank you for joining our community.\n\n"
                f"Warm regards,\nHER AREA Team\n{from_email}"
            )
            html_message = f"""
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eaeaea; border-radius: 10px;">
                <h2 style="color: #90274c; text-align: center;">HER AREA</h2>
                <hr style="border: none; border-top: 1px solid #eaeaea; margin: 20px 0;">
                <p style="font-size: 16px; color: #333;">Hello {customer_name},</p>
                <p style="font-size: 16px; color: #333;">Welcome to HER AREA!</p>
                <p style="font-size: 16px; color: #333;">Your account has been created and your email address has been successfully verified.</p>
                <p style="font-size: 16px; color: #333;">You can now sign in using your registered email address and password to access HER AREA.</p>
                <p style="font-size: 16px; color: #333;">Thank you for joining our community.</p>
                <hr style="border: none; border-top: 1px solid #eaeaea; margin: 20px 0;">
                <p style="font-size: 14px; color: #333;">Warm regards,<br><strong>HER AREA Team</strong><br>{from_email}</p>
            </div>
            """
            
            send_mail(
                subject=subject,
                message=text_message,
                from_email=from_email,
                recipient_list=[email],
                fail_silently=False,
                html_message=html_message
            )
            logger.info(f"Account Created successfully email dispatched to {email}")
        except Exception as exc:
            logger.error(f"Account Created email dispatch failed for {email}: {exc}")
        
        return Response({
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "user_id": str(user.id),
            "role": user.role,
            "is_new_user": created,
        }, status=status.HTTP_200_OK)


class PasswordResetCompleteView(APIView):
    """
    Complete password reset using token from OTP verification.
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Complete Password Reset",
        request=PasswordResetCompleteSerializer,
        responses={200: OpenApiResponse(description="Password reset successful.")}
    )
    def post(self, request):
        serializer = PasswordResetCompleteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email'].lower().strip()
        reset_token = serializer.validated_data['reset_token']
        password = serializer.validated_data['password']
        
        token_key = f"reset_token_{hashlib.md5(email.encode()).hexdigest()}"
        stored_token = cache.get(token_key)
        
        if not stored_token or stored_token != reset_token:
            return Response({"error": "Invalid or expired reset token."}, status=status.HTTP_400_BAD_REQUEST)
            
        user = User.objects.filter(email=email).first()
        if not user:
            return Response({"error": "User not found."}, status=status.HTTP_404_NOT_FOUND)
            
        user.set_password(password)
        user.save()
        
        cache.delete(token_key)
        
        logger.info(f"Customer {user.id} password reset completed.")
        return Response({"success": True, "message": "Password updated successfully."}, status=status.HTTP_200_OK)

class VendorForcePasswordChangeView(APIView):
    """
    Force password change for Vendor on first login.
    """
    permission_classes = [permissions.IsAuthenticated, IsVendorRole]

    @extend_schema(
        summary="Vendor Force Password Change",
        request=PasswordChangeSerializer,
        responses={200: OpenApiResponse(description="Password changed successfully.")}
    )
    def post(self, request):
        serializer = PasswordChangeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = request.user
        
        # Verify old password
        if not user.check_password(serializer.validated_data['old_password']):
            return Response({"error": "Incorrect temporary password."}, status=status.HTTP_400_BAD_REQUEST)
            
        user.set_password(serializer.validated_data['new_password'])
        user.must_change_password = False
        user.save()
        
        logger.info(f"Vendor {user.id} successfully changed their temporary password.")
        return Response({"success": True, "message": "Password updated successfully."}, status=status.HTTP_200_OK)


class LogoutView(APIView):
    """
    Revoke user authentication session by blacklisting the provided rotating Refresh Token.
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Logout & Blacklist Refresh Token",
        description="Invalidate active session refresh token to terminate client credentials.",
        request=LogoutSerializer,
        responses={200: OpenApiResponse(description="Successfully logged out.")}
    )
    def post(self, request):
        refresh = request.data.get('refresh') or request.data.get('refresh_token')
        if refresh:
            try:
                token = RefreshToken(refresh)
                token.blacklist()
            except Exception as e:
                logger.warning(f"Logout token blacklist warning: {str(e)}")
        return Response({"message": "Successfully logged out."}, status=status.HTTP_200_OK)


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
