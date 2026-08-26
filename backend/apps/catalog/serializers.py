from rest_framework import serializers
from apps.catalog.models import Product, GalleryImage, Offer

class ProductSerializer(serializers.ModelSerializer):
    store_id = serializers.UUIDField(source='business_profile.id', read_only=True)
    store_name = serializers.CharField(source='business_profile.business_name', read_only=True)
    store_city = serializers.CharField(source='business_profile.city', read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)

    class Meta:
        model = Product
        fields = [
            'id', 'item_type', 'category', 'subcategory', 'category_name', 'store_id', 'store_name', 'store_city', 
            'name', 'description', 'price', 'discounted_price', 
            'stock_status', 'service_duration_minutes', 'image_url', 'additional_images', 'is_featured', 'is_active', 
            'status', 'admin_remarks', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'store_id', 'store_name', 'store_city', 'category_name', 'status', 'admin_remarks', 'created_at', 'updated_at']


class GalleryImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = GalleryImage
        fields = ['id', 'image_url', 'caption', 'display_order', 'created_at']
        read_only_fields = ['id', 'created_at']


class OfferSerializer(serializers.ModelSerializer):
    class Meta:
        model = Offer
        fields = ['id', 'title', 'promo_code', 'description', 'offer_type', 'discount_value', 'start_date', 'end_date', 'status', 'admin_remarks', 'created_at']
        read_only_fields = ['id', 'admin_remarks', 'created_at']


class PublicPromotionSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    store_id = serializers.UUIDField(source='business_profile.id', read_only=True)
    store_name = serializers.CharField(source='business_profile.business_name', read_only=True)

    class Meta:
        model = Offer
        fields = ['id', 'title', 'promo_code', 'description', 'offer_type', 'discount_value', 'start_date', 'end_date', 'status', 'image_url', 'store_id', 'store_name', 'created_at']
        read_only_fields = ['id', 'created_at', 'image_url', 'store_id', 'store_name']

    def get_image_url(self, obj) -> str:
        if obj.business_profile and obj.business_profile.cover_url:
            return obj.business_profile.cover_url
        gallery = obj.business_profile.gallery_images.first()
        if gallery and gallery.image_url:
            return gallery.image_url
        return 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=1200'


class StoreCompleteCatalogSerializer(serializers.Serializer):
    """
    Comprehensive O2O dossier combining showroom products/services, gallery images, 
    and promotional deals for Customer App Store Details screen.
    """
    products = ProductSerializer(many=True, read_only=True)
    gallery = GalleryImageSerializer(many=True, read_only=True)
    offers = OfferSerializer(many=True, read_only=True)
