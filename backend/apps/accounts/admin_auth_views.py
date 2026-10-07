import logging
import random
import hashlib
import requests
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status
from django.core.cache import cache
from django.conf import settings
from rest_framework_simplejwt.tokens import RefreshToken
from drf_spectacular.utils import extend_schema, OpenApiResponse
from apps.accounts.models import User, UserRole, AdminLoginHistory
from datetime import timedelta

ALLOWED_ADMIN_NAMES = ['mittu', 'jyothsna', 'mani', 'admin1', 'admin2']

logger = logging.getLogger('her_area')

OTP_TTL_SECONDS = 300  # 5 minutes
OTP_CACHE_PREFIX = 'admin_otp_'
ATTEMPTS_PREFIX = 'admin_otp_attempts_'

def _make_otp_cache_key(identifier: str) -> str:
    return OTP_CACHE_PREFIX + hashlib.sha256(identifier.encode()).hexdigest()

def _make_attempts_key(identifier: str) -> str:
    return ATTEMPTS_PREFIX + hashlib.sha256(identifier.encode()).hexdigest()

class AdminOtpRequestView(APIView):
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Admin OTP Request",
        description="Sends OTP to an authorized Admin email via ZeptoMail.",
    )
    def post(self, request):
        email = request.data.get('email')
        admin_name = request.data.get('admin_name', '').strip().lower()
        if not email:
            return Response({"error": "Email is required"}, status=status.HTTP_400_BAD_REQUEST)
        if admin_name not in ALLOWED_ADMIN_NAMES:
            return Response({"error": "Invalid Admin Name entered."}, status=status.HTTP_400_BAD_REQUEST)
        
        identifier = email.lower().strip()
        
        # Security: Do not reveal if the email is an admin or not to arbitrary users
        user = User.objects.filter(email=identifier, role__in=[UserRole.ADMIN, UserRole.SUPERADMIN], is_active=True).first()
        
        logger.info("ADMIN OTP DEBUG: authorized_admin_found=%s role=%s is_active=%s", 
                    bool(user), getattr(user, 'role', None), getattr(user, 'is_active', None))
        
        cache_key = _make_otp_cache_key(identifier)
        
        # Cooldown check
        if cache.get(cache_key + '_ts'):
            return Response({"error": "Too many requests. Please wait before requesting another OTP."}, status=status.HTTP_429_TOO_MANY_REQUESTS)

        logger.info("ADMIN OTP DEBUG: email_send_branch_entered=%s", bool(user))

        # We must return a generic success message even if the user is not found to prevent enumeration
        # However, we only send the email if the user is a valid admin.
        if user:
            zeptomail_token = getattr(settings, 'ZEPTOMAIL_SEND_MAIL_TOKEN', None)
            if not zeptomail_token:
                logger.error("ZEPTOMAIL_SEND_MAIL_TOKEN is not configured")
                return Response({"error": "Email service configuration error."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

            otp = str(random.randint(100000, 999999))
            cache.set(cache_key, otp, timeout=OTP_TTL_SECONDS)
            cache.set(cache_key + '_ts', '1', timeout=60)
            cache.delete(_make_attempts_key(identifier)) # Reset attempts
            
            logger.info("Admin OTP generated and dispatched for authorized admin.")
            
            # Send Email via ZeptoMail
            subject = "HER AREA - Admin Portal Access Code"
            html_message = f"""
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto;">
                <h2 style="color: #90274c;">HER AREA ADMIN PORTAL</h2>
                <p>Hello {user.full_name or 'Admin'},</p>
                <p>Your one-time passcode for admin portal access is:</p>
                <div style="text-align: center; margin: 30px 0;">
                    <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #90274c; background-color: #f9f9f9; padding: 15px 25px; border-radius: 8px;">{otp}</span>
                </div>
                <p>This code is valid for 5 minutes.</p>
                <p>Warm regards,<br>HER AREA Team</p>
            </div>
            """
            
            try:
                zeptomail_api_url = getattr(settings, 'ZEPTOMAIL_API_URL', 'https://api.zeptomail.in/v1.1/email')
                
                logger.info("ADMIN OTP: token configured=%s", bool(zeptomail_token))
                logger.info("ADMIN OTP: ZeptoMail URL=%s", zeptomail_api_url)
                
                response = requests.post(
                    zeptomail_api_url,
                    headers={
                        "Accept": "application/json",
                        "Content-Type": "application/json",
                        "Authorization": f"Zoho-enczapikey {zeptomail_token}",
                    },
                    json={
                        "from": {"address": "noreply@herarea.com", "name": "HER AREA Admin"},
                        "to": [{"email_address": {"address": identifier}}],
                        "subject": subject,
                        "htmlbody": html_message,
                    },
                    timeout=30,
                )
                
                logger.info(
                    "ADMIN OTP: ZeptoMail status=%s response=%s",
                    response.status_code,
                    response.text[:300]
                )
                
                if not response.ok:
                    safe_response = response.text[:200]
                    logger.error(f"ZeptoMail API error: status {response.status_code}, response: {safe_response}")
                
                response.raise_for_status()
                
            except Exception as e:
                logger.error("Failed to send Admin OTP via ZeptoMail.")
                return Response({"error": "Failed to send email. Check API configuration."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({"message": "OTP has been sent to the registered admin email."})

class AdminOtpVerifyView(APIView):
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Admin OTP Verify",
        description="Verifies the OTP and issues a JWT if valid.",
    )
    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')
        admin_name = request.data.get('admin_name', '').strip().lower()
        
        if not email or not otp:
            return Response({"error": "Email and OTP are required"}, status=status.HTTP_400_BAD_REQUEST)
        if admin_name not in ALLOWED_ADMIN_NAMES:
            return Response({"error": "Invalid Admin Name entered."}, status=status.HTTP_400_BAD_REQUEST)
        
        identifier = email.lower().strip()
        attempts_key = _make_attempts_key(identifier)
        attempts = cache.get(attempts_key, 0)
        
        if attempts >= 5:
            return Response({"error": "Too many attempts. Please try again later."}, status=status.HTTP_429_TOO_MANY_REQUESTS)
            
        cache_key = _make_otp_cache_key(identifier)
        stored_otp = cache.get(cache_key)
        
        if not stored_otp or stored_otp != otp:
            cache.set(attempts_key, attempts + 1, timeout=OTP_TTL_SECONDS)
            return Response({"error": "Invalid or expired OTP."}, status=status.HTTP_400_BAD_REQUEST)
        
        user = User.objects.filter(email=identifier, role__in=[UserRole.ADMIN, UserRole.SUPERADMIN], is_active=True).first()
        
        if not user:
            return Response({"error": "Invalid or expired OTP."}, status=status.HTTP_400_BAD_REQUEST)
            
        # Success! Invalidate OTP.
        cache.delete(cache_key)
        cache.delete(attempts_key)
        
        AdminLoginHistory.objects.create(user=user, admin_name=admin_name)
        
        refresh = RefreshToken.for_user(user)
        refresh.set_exp(lifetime=timedelta(hours=72))
        refresh.access_token.set_exp(lifetime=timedelta(hours=72))
        
        return Response({
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "user": {
                "id": str(user.id),
                "email": user.email,
                "role": user.role,
                "full_name": user.full_name,
            }
        })
