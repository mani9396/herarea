from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from apps.accounts.views import (
    CustomerLoginView,
    OtpSendView,
    OtpVerifyView,
    OtpVerifyForPurposeView,
    CustomerRegisterCompleteView,
    PasswordResetCompleteView,
    LogoutView,
    UserProfileView,
    CustomerRoleVerificationView,
    VendorRoleVerificationView,
    AdminRoleVerificationView,
    SuperAdminRoleVerificationView,
    VendorForcePasswordChangeView,
)

urlpatterns = [
    # Primary OTP Passwordless JWT Issuance
    path('otp/send/', OtpSendView.as_view(), name='auth-otp-send'),
    path('otp/verify/', OtpVerifyView.as_view(), name='auth-otp-verify'),
    
    # New Email + Password Flows
    path('login/', CustomerLoginView.as_view(), name='auth-customer-login'),
    path('otp/verify-purpose/', OtpVerifyForPurposeView.as_view(), name='auth-otp-verify-purpose'),
    path('register/', CustomerRegisterCompleteView.as_view(), name='auth-customer-register'),
    path('password-reset/', PasswordResetCompleteView.as_view(), name='auth-password-reset'),
    
    path('vendor/force-password-change/', VendorForcePasswordChangeView.as_view(), name='auth-vendor-force-password-change'),
    
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('logout/', LogoutView.as_view(), name='auth-logout'),
    path('me/', UserProfileView.as_view(), name='auth-me'),

    # RBAC Role Isolation Verification Endpoints
    path('rbac/customer/', CustomerRoleVerificationView.as_view(), name='rbac-test-customer'),
    path('rbac/vendor/', VendorRoleVerificationView.as_view(), name='rbac-test-vendor'),
    path('rbac/admin/', AdminRoleVerificationView.as_view(), name='rbac-test-admin'),
    path('rbac/superadmin/', SuperAdminRoleVerificationView.as_view(), name='rbac-test-superadmin'),
]
