from rest_framework import serializers
from apps.business.models import BusinessProfile

class BusinessProfileSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_slug = serializers.CharField(source='category.slug', read_only=True)

    class Meta:
        model = BusinessProfile
        fields = [
            'id', 'category', 'category_name', 'category_slug', 
            'business_name', 'description', 
            'address_line_1', 'address_line_2', 'city', 'state', 'pincode', 
            'contact_email', 'contact_phone', 
            'latitude', 'longitude', 'business_timings', 
            'logo_url', 'cover_url', 
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'category_name', 'category_slug', 'created_at', 'updated_at']


class PublicStoreShowroomSerializer(serializers.ModelSerializer):
    """
    Public customer discovery serializer for APPROVED partner studio showrooms.
    Excludes sensitive audit trails and focuses entirely on O2O discovery branding.
    """
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_slug = serializers.CharField(source='category.slug', read_only=True)
    vendor_status = serializers.CharField(source='vendor.status', read_only=True)

    class Meta:
        model = BusinessProfile
        fields = [
            'id', 'business_name', 'description', 'category_name', 'category_slug', 'vendor_status',
            'address_line_1', 'address_line_2', 'city', 'state', 'pincode', 
            'contact_email', 'contact_phone', 
            'latitude', 'longitude', 'business_timings', 
            'logo_url', 'cover_url', 'created_at'
        ]
        read_only_fields = ['id', 'category_name', 'category_slug', 'vendor_status', 'created_at']
