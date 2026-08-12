from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from apps.accounts.views import (
    OtpSendView,
    OtpVerifyView,
    LogoutView,
    UserProfileView,
    CustomerRoleVerificationView,
    VendorRoleVerificationView,
    AdminRoleVerificationView,
    SuperAdminRoleVerificationView,
)

urlpatterns = [
    # Primary OTP Passwordless JWT Issuance
    path('otp/send/', OtpSendView.as_view(), name='auth-otp-send'),
    path('otp/verify/', OtpVerifyView.as_view(), name='auth-otp-verify'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('logout/', LogoutView.as_view(), name='auth-logout'),
    path('me/', UserProfileView.as_view(), name='auth-me'),

    # RBAC Role Isolation Verification Endpoints
    path('rbac/customer/', CustomerRoleVerificationView.as_view(), name='rbac-test-customer'),
    path('rbac/vendor/', VendorRoleVerificationView.as_view(), name='rbac-test-vendor'),
    path('rbac/admin/', AdminRoleVerificationView.as_view(), name='rbac-test-admin'),
    path('rbac/superadmin/', SuperAdminRoleVerificationView.as_view(), name='rbac-test-superadmin'),
]
