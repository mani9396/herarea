from rest_framework import serializers
from apps.vendors.models import VendorProfile, KycDocument, KycDocType
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
            'status', 'rejection_reason', 'approved_at', 
            'business_profile', 'kyc_documents', 'created_at'
        ]
        read_only_fields = ['id', 'status', 'rejection_reason', 'approved_at', 'created_at']


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
    logo_url = serializers.URLField(required=False, allow_blank=True, default="")
    cover_url = serializers.URLField(required=False, allow_blank=True, default="")


class AdminVendorActionSerializer(serializers.Serializer):
    rejection_reason = serializers.CharField(
        max_length=500, 
        required=True, 
        help_text="Mandatory governance feedback detailing reasons for studio application rejection or account suspension."
    )
