from rest_framework import permissions
from apps.accounts.models import UserRole

class IsCustomerRole(permissions.BasePermission):
    """Allows access only to authenticated customers (app_user)."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == UserRole.CUSTOMER)

class IsVendorRole(permissions.BasePermission):
    """Allows access only to verified partner studio owners (app_vendor)."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == UserRole.VENDOR)

class IsAdminRole(permissions.BasePermission):
    """Allows access to governance moderators and executive superadmins (app_admin)."""
    def has_permission(self, request, view):
        return bool(
            request.user and request.user.is_authenticated and (
                request.user.role in [UserRole.ADMIN, UserRole.SUPERADMIN] or request.user.is_superuser
            )
        )

class IsSuperAdminRole(permissions.BasePermission):
    """Restrict operations strictly to Platform Founders & Superadmins."""
    def has_permission(self, request, view):
        return bool(
            request.user and request.user.is_authenticated and (
                request.user.role == UserRole.SUPERADMIN or request.user.is_superuser
            )
        )
