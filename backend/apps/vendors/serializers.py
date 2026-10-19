from rest_framework import serializers
from apps.vendors.models import VendorProfile, KycDocument, ChatStatus
from apps.business.serializers import BusinessProfileSerializer

class KycDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = KycDocument
        fields = ['id', 'document_type', 'document_url', 'document_number', 'status', 'verified_at', 'created_at']
        read_only_fields = ['id', 'status', 'verified_at', 'created_at']


class VendorProfileSerializer(serializers.ModelSerializer):
    business_profile = BusinessProfileSerializer(read_only=True)
    kyc_documents = KycDocumentSerializer(many=True, read_only=True)

    class Meta:
        model = VendorProfile
        fields = [
            'id', 'owner_name', 'official_email', 'phone_number', 
            'status', 'chat_status', 'rejection_reason', 'approved_at', 
            'business_profile', 'kyc_documents', 'created_at'
        ]
        read_only_fields = ['id', 'status', 'chat_status', 'rejection_reason', 'approved_at', 'created_at']


class AdminVendorChatStatusSerializer(serializers.Serializer):
    chat_status = serializers.ChoiceField(choices=ChatStatus.choices, help_text="Set chat availability for the vendor")

class VendorOnboardingRegistrationSerializer(serializers.Serializer):
    """
    Unified onboarding submission schema combining legal studio owner details
    with initial public showroom business profile specifics.
    """
    owner_name = serializers.CharField(max_length=150, help_text="Full legal studio owner name")
    official_email = serializers.EmailField(help_text="Official business correspondence email")
    phone_number = serializers.CharField(max_length=20, help_text="Primary business mobile handset")
    
    # Business Profile Initial Configuration
    business_name = serializers.CharField(max_length=200, help_text="Official studio showroom brand title")
    description = serializers.CharField(required=False, allow_blank=True, default="", help_text="Studio specialty description")
    address_line_1 = serializers.CharField(max_length=255, help_text="Street address, building name")
    address_line_2 = serializers.CharField(required=False, allow_blank=True, default="", help_text="Floor, landmark, locality")
    city = serializers.CharField(max_length=100)
    state = serializers.CharField(max_length=100)
    pincode = serializers.CharField(max_length=20)
    contact_email = serializers.EmailField(help_text="Public showroom booking support email")
    contact_phone = serializers.CharField(max_length=20, help_text="Public booking phone number")
    
    business_timings = serializers.JSONField(
        default={"Monday - Friday": "10:00 AM - 08:00 PM", "Saturday": "10:00 AM - 06:00 PM", "Sunday": "Closed"},
        required=False,
        help_text="Daily operational schedule specification"
    )



class AdminVendorActionSerializer(serializers.Serializer):
    rejection_reason = serializers.CharField(
        max_length=500, 
        required=True, 
        help_text="Mandatory governance feedback detailing reasons for studio application rejection or account suspension."
    )

class AdminVendorCreateSerializer(serializers.Serializer):
    """
    Schema for Admin to securely provision a new partner studio vendor account.
    """
    owner_name = serializers.CharField(max_length=150, help_text="Full legal studio owner name")
    official_email = serializers.EmailField(help_text="Official business correspondence email")
    phone_number = serializers.CharField(max_length=20, help_text="Primary business mobile handset")
    business_name = serializers.CharField(max_length=200, help_text="Official studio showroom brand title")

from apps.accounts.serializers import _validate_password_strength
import re

class VendorSelfRegistrationSerializer(serializers.Serializer):
    """
    Schema for Vendor to self-register their account.
    """
    owner_name = serializers.CharField(max_length=150, help_text="Full legal studio owner name")
    email = serializers.EmailField(help_text="Official business correspondence email")
    phone_number = serializers.CharField(max_length=20, help_text="Primary business mobile handset")
    password = serializers.CharField(write_only=True, validators=[_validate_password_strength])
    confirm_password = serializers.CharField(write_only=True)
    otp = serializers.CharField(max_length=6, min_length=6, required=True, help_text="6-digit verification code sent to email")

    def validate_otp(self, value):
        if not value.isdigit() or len(value) != 6:
            raise serializers.ValidationError("Verification code must be a 6-digit number.")
        return value

    def validate_owner_name(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError("Owner name cannot be blank.")
        return value.strip()

    def validate_phone_number(self, value):
        cleaned = re.sub(r'\D', '', value)
        if len(cleaned) < 10:
            raise serializers.ValidationError("Please provide a valid mobile number with at least 10 digits.")
        return value.strip()

    def validate(self, data):
        if data.get('password') != data.get('confirm_password'):
            raise serializers.ValidationError({"confirm_password": "Passwords must match."})
        return data