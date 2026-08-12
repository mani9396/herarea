from rest_framework import serializers
from apps.accounts.models import User, UserRole

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'phone_number', 'email', 'role', 'is_active', 'is_verified', 'created_at']
        read_only_fields = ['id', 'is_verified', 'created_at']

class OtpSendSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20, help_text="Mobile handset number (e.g., +919876543210)")
    role = serializers.ChoiceField(choices=UserRole.choices, default=UserRole.CUSTOMER, required=False)

    def validate_phone_number(self, value):
        if len(value) < 10:
            raise serializers.ValidationError("Phone number must contain at least 10 digits.")
        return value

class OtpVerifySerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20, help_text="Mobile handset number used in OTP challenge")
    otp = serializers.CharField(max_length=6, min_length=6, help_text="6-digit authentication verification code")
    role = serializers.ChoiceField(choices=UserRole.choices, default=UserRole.CUSTOMER, required=False)

    def validate_otp(self, value):
        if not value.isdigit():
            raise serializers.ValidationError("OTP code must consist entirely of digits.")
        return value

class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField(required=False, allow_null=True, help_text="SimpleJWT refresh token to blacklist")
