import re
from rest_framework import serializers
from apps.accounts.models import User, UserRole


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'phone_number', 'email', 'full_name', 'role', 'is_active', 'is_verified', 'created_at']
        read_only_fields = ['id', 'is_verified', 'created_at']


class OtpSendSerializer(serializers.Serializer):
    # Email is used by Customers; phone_number is used by Vendors/Admins.
    email = serializers.EmailField(required=False, allow_null=True, help_text="Customer email address for email OTP")
    phone_number = serializers.CharField(max_length=20, required=False, allow_null=True, allow_blank=True,
                                         help_text="Mobile handset number for Vendor/Admin OTP (e.g., +919876543210)")
    role = serializers.ChoiceField(choices=UserRole.choices, default=UserRole.CUSTOMER, required=False)
    purpose = serializers.ChoiceField(
        choices=['REGISTRATION', 'PASSWORD_RESET', 'LOGIN'],
        default='LOGIN',
        required=False,
        help_text="Purpose of OTP: REGISTRATION, PASSWORD_RESET, or LOGIN"
    )
    full_name = serializers.CharField(
        max_length=200, 
        required=False, 
        allow_null=True, 
        allow_blank=True,
        help_text="Customer's full name (provided during registration OTP request)"
    )

    def validate(self, data):
        email = data.get('email')
        phone = data.get('phone_number')
        if not email and not phone:
            raise serializers.ValidationError("Either 'email' or 'phone_number' must be provided.")
        return data

    def validate_phone_number(self, value):
        if value and len(value) < 10:
            raise serializers.ValidationError("Phone number must contain at least 10 digits.")
        return value


class OtpVerifySerializer(serializers.Serializer):
    """Legacy OTP verify for Vendor/Admin phone flow (preserved)."""
    email = serializers.EmailField(required=False, allow_null=True)
    phone_number = serializers.CharField(max_length=20, required=False, allow_null=True, allow_blank=True)
    otp = serializers.CharField(max_length=6, min_length=6)
    role = serializers.ChoiceField(choices=UserRole.choices, default=UserRole.CUSTOMER, required=False)

    def validate(self, data):
        if not data.get('email') and not data.get('phone_number'):
            raise serializers.ValidationError("Either 'email' or 'phone_number' must be provided.")
        return data

    def validate_otp(self, value):
        if not value.isdigit():
            raise serializers.ValidationError("OTP code must consist entirely of digits.")
        return value


class OtpVerifyForPurposeSerializer(serializers.Serializer):
    """New Customer email OTP verify with explicit purpose."""
    email = serializers.EmailField(help_text="Customer email address")
    otp = serializers.CharField(max_length=6, min_length=6, help_text="6-digit verification code")
    purpose = serializers.ChoiceField(
        choices=['REGISTRATION', 'PASSWORD_RESET'],
        help_text="Purpose: REGISTRATION marks email verified; PASSWORD_RESET issues a reset token"
    )

    def validate_otp(self, value):
        if not value.isdigit():
            raise serializers.ValidationError("OTP code must consist entirely of digits.")
        return value


def _validate_password_strength(value):
    """Enforce minimum password strength rules."""
    if len(value) < 8:
        raise serializers.ValidationError("Password must be at least 8 characters long.")
    if not re.search(r'[A-Z]', value):
        raise serializers.ValidationError("Password must contain at least one uppercase letter.")
    if not re.search(r'[a-z]', value):
        raise serializers.ValidationError("Password must contain at least one lowercase letter.")
    if not re.search(r'[0-9]', value):
        raise serializers.ValidationError("Password must contain at least one number.")
    return value


class CustomerLoginSerializer(serializers.Serializer):
    """Email + password login for Customer accounts."""
    email = serializers.EmailField(help_text="Registered customer email address")
    password = serializers.CharField(write_only=True, help_text="Account password")


class CustomerRegisterCompleteSerializer(serializers.Serializer):
    """Complete registration after email OTP verification."""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, validators=[_validate_password_strength])
    confirm_password = serializers.CharField(write_only=True)
    full_name = serializers.CharField(max_length=200, help_text="Customer's full display name")
    locality = serializers.CharField(max_length=300, required=False, allow_blank=True,
                                     help_text="Customer's primary discovery locality")

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        return data


class PasswordResetCompleteSerializer(serializers.Serializer):
    """Complete password reset after OTP verification."""
    email = serializers.EmailField()
    reset_token = serializers.CharField(help_text="Secure token issued after successful OTP verification")
    password = serializers.CharField(write_only=True, validators=[_validate_password_strength])
    confirm_password = serializers.CharField(write_only=True)

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        return data


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField(required=False, allow_null=True, help_text="SimpleJWT refresh token to blacklist")

