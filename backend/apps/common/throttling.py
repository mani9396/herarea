from rest_framework.throttling import ScopedRateThrottle

class OTPAuthenticationThrottle(ScopedRateThrottle):
    """
    Rate limiter scoped to 'otp' to defend against brute-force attacks on OTP generator 
    and verification authentication endpoints in apps.accounts.
    """
    scope = 'otp'


class FileUploadThrottle(ScopedRateThrottle):
    """
    Rate limiter scoped to 'upload' to prevent storage exhaustion and denial-of-service
    via repeated high-frequency file upload streams (KYC documents, showroom gallery images).
    """
    scope = 'upload'
