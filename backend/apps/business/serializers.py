from rest_framework import serializers
from apps.business.models import BusinessProfile, StoreMedia

class StoreMediaSerializer(serializers.ModelSerializer):
    class Meta:
        model = StoreMedia
        fields = ['id', 'image', 'display_order', 'is_active', 'created_at']
        read_only_fields = ['id', 'created_at']

class BusinessProfileSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_slug = serializers.CharField(source='category.slug', read_only=True)
    subcategory_name = serializers.CharField(source='subcategory.name', read_only=True)
    subcategory_slug = serializers.CharField(source='subcategory.slug', read_only=True)
    gallery = StoreMediaSerializer(many=True, read_only=True)
    is_listing_eligible = serializers.BooleanField(read_only=True)
    rating = serializers.SerializerMethodField()
    review_count = serializers.SerializerMethodField()
    
    # Relax DRF validation bounds so Flutter can send high-precision floats
    latitude = serializers.DecimalField(max_digits=22, decimal_places=16, required=False, allow_null=True)
    longitude = serializers.DecimalField(max_digits=22, decimal_places=16, required=False, allow_null=True)

    class Meta:
        model = BusinessProfile
        fields = [
            'id', 'category', 'category_name', 'category_slug', 
            'subcategory', 'subcategory_name', 'subcategory_slug',
            'business_name', 'description', 
            'address_line_1', 'address_line_2', 'area', 'city', 'state', 'country', 'postal_code', 
            'contact_email', 'contact_phone', 
            'latitude', 'longitude', 'business_timings', 
            'logo', 'cover_image', 'gallery', 'is_listing_eligible',
            'status', 'admin_remarks',
            'created_at', 'updated_at', 'rating', 'review_count'
        ]
        read_only_fields = ['id', 'category_name', 'category_slug', 'subcategory_name', 'subcategory_slug', 'status', 'admin_remarks', 'created_at', 'updated_at']

    def get_rating(self, obj):
        reviews = obj.reviews.filter(status='APPROVED')
        if reviews.exists():
            return round(sum(r.rating for r in reviews) / reviews.count(), 1)
        return 0.0

    def get_review_count(self, obj):
        return obj.reviews.filter(status='APPROVED').count()

    def validate(self, data):
        category = data.get('category')
        subcategory = data.get('subcategory')

        if subcategory and category:
            if subcategory.parent_category != category:
                raise serializers.ValidationError({
                    "subcategory": "This subcategory does not belong to the selected category."
                })
        return data

    def validate_latitude(self, value):
        if value is not None:
            return round(value, 7)
        return value

    def validate_longitude(self, value):
        if value is not None:
            return round(value, 7)
        return value


class PublicStoreShowroomSerializer(serializers.ModelSerializer):
    """
    Public customer discovery serializer for APPROVED partner studio showrooms.
    Excludes sensitive audit trails and focuses entirely on O2O discovery branding.
    """
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_slug = serializers.CharField(source='category.slug', read_only=True)
    subcategory_name = serializers.CharField(source='subcategory.name', read_only=True)
    subcategory_slug = serializers.CharField(source='subcategory.slug', read_only=True)
    vendor_status = serializers.CharField(source='vendor.status', read_only=True)
    distance_km = serializers.FloatField(read_only=True, required=False)
    gallery = StoreMediaSerializer(many=True, read_only=True)
    rating = serializers.SerializerMethodField()
    review_count = serializers.SerializerMethodField()

    class Meta:
        model = BusinessProfile
        fields = [
            'id', 'business_name', 'description', 'category_name', 'category_slug', 
            'subcategory_name', 'subcategory_slug', 'vendor_status', 'distance_km',
            'address_line_1', 'address_line_2', 'area', 'city', 'state', 'country', 'postal_code', 
            'contact_email', 'contact_phone', 
            'latitude', 'longitude', 'business_timings', 
            'logo', 'cover_image', 'gallery', 'created_at',
            'rating', 'review_count'
        ]
        read_only_fields = ['id', 'category_name', 'category_slug', 'subcategory_name', 'subcategory_slug', 'vendor_status', 'created_at']

    def get_rating(self, obj):
        reviews = obj.reviews.filter(status='APPROVED')
        if reviews.exists():
            return round(sum(r.rating for r in reviews) / reviews.count(), 1)
        return 0.0

    def get_review_count(self, obj):
        return obj.reviews.filter(status='APPROVED').count()
