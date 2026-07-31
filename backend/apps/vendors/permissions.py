from rest_framework import permissions, exceptions
from apps.accounts.models import UserRole
from apps.vendors.models import VendorStatus

class IsApprovedVendor(permissions.BasePermission):
    """
    Core marketplace approval governance shield:
    Ensures ONLY partner studios whose onboarding KYC and business profiles have been 
    officially APPROVED by a governance Admin can execute catalog management commands.
    Evaluates real-time database state to immediately block suspended or rejected studios.
    """
    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated and request.user.role == UserRole.VENDOR):
            raise exceptions.PermissionDenied("Access denied: Operation restricted strictly to authenticated partner studios.")
        
        try:
            vendor = request.user.vendor_profile
            vendor.refresh_from_db()  # Guarantee evaluation against live relational database state
        except Exception:
            raise exceptions.PermissionDenied(
                "Incomplete Onboarding: No Vendor Profile associated with this account. Please submit business registration and KYC documents."
            )
            
        if vendor.status != VendorStatus.APPROVED:
            reason_msg = f" (Admin Reason: {vendor.rejection_reason})" if vendor.rejection_reason else ""
            raise exceptions.PermissionDenied(
                f"Marketplace Approval Required: Your vendor account is currently {vendor.status}{reason_msg}. "
                "Only APPROVED partner studios can manage showrooms, catalog items, gallery images, and offers."
            )
            
        return True
