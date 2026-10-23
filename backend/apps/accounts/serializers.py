import re
from rest_framework import serializers
from apps.accounts.models import User, UserRole, GenderChoices


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'phone_number', 'email', 'full_name', 'gender', 'avatar', 'date_of_birth', 'role', 'is_active', 'is_verified', 'created_at']
        read_only_fields = ['id', 'phone_number', 'email', 'role', 'is_verified', 'created_at']

    def validate_phone_number(self, value):
        if value:
            cleaned = re.sub(r'\D', '', str(value).strip())
            if len(cleaned) == 12 and cleaned.startswith('91'):
                cleaned = cleaned[2:]
            elif len(cleaned) == 11 and cleaned.startswith('0'):
                cleaned = cleaned[1:]

            if len(cleaned) != 10:
                raise serializers.ValidationError("Mobile number must be exactly 10 digits.")
            if not re.match(r'^[6-9]\d{9}$', cleaned):
                raise serializers.ValidationError("Mobile number must be a valid 10-digit Indian number starting with 6, 7, 8, or 9.")
            if re.match(r'^(\d)\1{9}$', cleaned):
                raise serializers.ValidationError("Please enter a valid original mobile number (cannot be repeating digits).")

            formatted = f"+91{cleaned}"
            user = self.instance
            qs = User.all_objects.filter(phone_number=formatted)
            if user:
                qs = qs.exclude(id=user.id)
            if qs.exists():
                raise serializers.ValidationError("An account with this mobile number already exists.")
            return formatted
        return value

    def to_representation(self, instance):
        data = super().to_representation(instance)
        phone = data.get('phone_number')
        if phone and str(phone).startswith('+00'):
            data['phone_number'] = ''
        return data


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

    def validate_email(self, value):
        if value:
            if any(c.isupper() for c in value):
                raise serializers.ValidationError("Email must contain small letters only.")
        return value

    def validate_phone_number(self, value):
        if value:
            cleaned = re.sub(r'\D', '', value)
            if len(cleaned) == 12 and cleaned.startswith('91'):
                cleaned = cleaned[2:]
            elif len(cleaned) == 11 and cleaned.startswith('0'):
                cleaned = cleaned[1:]

            if len(cleaned) != 10:
                raise serializers.ValidationError("Mobile number must be exactly 10 digits.")
            if not re.match(r'^[6-9]\d{9}$', cleaned):
                raise serializers.ValidationError("Mobile number must be a valid 10-digit Indian number starting with 6, 7, 8, or 9.")
            if re.match(r'^(\d)\1{9}$', cleaned):
                raise serializers.ValidationError("Please enter a valid original mobile number (cannot be repeating digits).")
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


class LoginSerializer(serializers.Serializer):
    """
    Unified identifier (email or mobile number) + password login schema.
    Supports email, identifier, or phone_number parameter names.
    """
    identifier = serializers.CharField(required=False, allow_blank=True, help_text="Registered email address or mobile number")
    email = serializers.CharField(required=False, allow_blank=True, help_text="Registered email address or mobile number")
    phone_number = serializers.CharField(required=False, allow_blank=True, help_text="Registered mobile number")
    password = serializers.CharField(write_only=True, help_text="Account password")
    role = serializers.ChoiceField(choices=UserRole.choices, default=UserRole.CUSTOMER, required=False)

    def validate(self, data):
        raw_id = data.get('identifier') or data.get('email') or data.get('phone_number')
        if not raw_id or not str(raw_id).strip():
            raise serializers.ValidationError({"identifier": "Email or Mobile Number is required."})
        data['raw_identifier'] = str(raw_id).strip()
        return data


CustomerLoginSerializer = LoginSerializer


class CustomerRegisterCompleteSerializer(serializers.Serializer):
    """Complete registration after email OTP verification."""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, validators=[_validate_password_strength])
    confirm_password = serializers.CharField(write_only=True)
    full_name = serializers.CharField(max_length=200, help_text="Customer's full display name")
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True, allow_null=True, help_text="Customer's mobile phone number")
    date_of_birth = serializers.DateField(required=True, help_text="Customer's date of birth")
    gender = serializers.ChoiceField(choices=GenderChoices.choices, required=True, help_text="Customer's gender")

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        return data

    def validate_email(self, value):
        if value:
            if any(c.isupper() for c in value):
                raise serializers.ValidationError("Email must contain small letters only.")
        return value

    def validate_phone_number(self, value):
        if value:
            cleaned = re.sub(r'\D', '', value)
            if len(cleaned) == 12 and cleaned.startswith('91'):
                cleaned = cleaned[2:]
            elif len(cleaned) == 11 and cleaned.startswith('0'):
                cleaned = cleaned[1:]

            if len(cleaned) != 10:
                raise serializers.ValidationError("Mobile number must be exactly 10 digits.")
            if not re.match(r'^[6-9]\d{9}$', cleaned):
                raise serializers.ValidationError("Mobile number must be a valid 10-digit Indian number starting with 6, 7, 8, or 9.")
            if re.match(r'^(\d)\1{9}$', cleaned):
                raise serializers.ValidationError("Please enter a valid original mobile number (cannot be repeating digits).")
        return value


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

class PasswordChangeSerializer(serializers.Serializer):
    """Change temporary password to a new one."""
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True, validators=[_validate_password_strength])
    confirm_password = serializers.CharField(write_only=True)

    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        return data


class CustomerAccountDeleteSerializer(serializers.Serializer):
    """Payload for authenticated customer permanent account deletion."""
    confirmation = serializers.BooleanField(
        required=True,
        help_text="Explicit confirmation flag (must be True) to confirm permanent account deletion."
    )
    password = serializers.CharField(
        required=False,
        allow_blank=True,
        write_only=True,
        help_text="Customer password for secure re-authentication (required if password is set)."
    )

    def validate_confirmation(self, value):
        if value is not True:
            raise serializers.ValidationError("Explicit confirmation is required to permanently delete your account.")
        return value


