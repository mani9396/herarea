from rest_framework import serializers
from apps.interactions.models import Favorite, Review
from apps.catalog.serializers import ProductSerializer
from apps.business.serializers import PublicStoreShowroomSerializer

class FavoriteSerializer(serializers.ModelSerializer):
    store_details = PublicStoreShowroomSerializer(source='store', read_only=True)
    product_details = ProductSerializer(source='product', read_only=True)

    class Meta:
        model = Favorite
        fields = ['id', 'store', 'store_details', 'product', 'product_details', 'created_at']
        read_only_fields = ['id', 'store_details', 'product_details', 'created_at']


class ReviewSerializer(serializers.ModelSerializer):
    customer_phone = serializers.SerializerMethodField()
    store_name = serializers.CharField(source='store.business_name', read_only=True)

    class Meta:
        model = Review
        fields = ['id', 'store', 'store_name', 'rating', 'title', 'comment', 'is_verified_visit', 'customer_phone', 'created_at']
        read_only_fields = ['id', 'store', 'store_name', 'is_verified_visit', 'customer_phone', 'created_at']

    def get_customer_phone(self, obj):
        phone = obj.user.phone_number
        if len(phone) >= 10:
            return phone[:5] + "XXXXX"
        return "Customer"

    def validate_rating(self, value):
        if not (1 <= value <= 5):
            raise serializers.ValidationError("Rating score must be between 1 and 5 stars.")
        return value


class GlobalO2OSearchPayloadSerializer(serializers.Serializer):
    """
    Aggregated O2O search response structure organizing matching showrooms, 
    retail couture products, and bespoke studio appointment services.
    """
    query = serializers.CharField(read_only=True)
    matching_stores = PublicStoreShowroomSerializer(many=True, read_only=True)
    matching_products = ProductSerializer(many=True, read_only=True)
    matching_services = ProductSerializer(many=True, read_only=True)
