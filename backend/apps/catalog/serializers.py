from rest_framework import serializers
from apps.catalog.models import Product, GalleryImage, Offer, Promotion, PromotionType, InternalDestinationType

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


class PromotionAdminSerializer(serializers.ModelSerializer):
    effective_status = serializers.CharField(read_only=True)

    class Meta:
        model = Promotion
        fields = [
            'id', 'title', 'subtitle', 'image_url', 'promotion_type', 
            'internal_destination_type', 'internal_destination_id', 
            'external_url', 'start_at', 'end_at', 'status', 'effective_status', 
            'priority', 'created_by', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_by', 'created_at', 'updated_at', 'effective_status']

    def validate(self, data):
        start_at = data.get('start_at', getattr(self.instance, 'start_at', None))
        end_at = data.get('end_at', getattr(self.instance, 'end_at', None))

        if start_at and end_at and end_at <= start_at:
            raise serializers.ValidationError({"end_at": "end_at must be after start_at"})

        promotion_type = data.get('promotion_type', getattr(self.instance, 'promotion_type', None))

        if promotion_type == PromotionType.APP:
            int_type = data.get('internal_destination_type', getattr(self.instance, 'internal_destination_type', None))
            int_id = data.get('internal_destination_id', getattr(self.instance, 'internal_destination_id', None))
            
            if not int_type or not int_id:
                raise serializers.ValidationError("internal_destination_type and internal_destination_id are required for APP promotions")
            
            # Reset external url
            data['external_url'] = None

            # Verify destination exists
            try:
                if int_type == InternalDestinationType.STORE:
                    from apps.business.models import BusinessProfile
                    if not BusinessProfile.objects.filter(id=int_id).exists():
                        raise serializers.ValidationError({"internal_destination_id": "Invalid STORE destination"})
                elif int_type == InternalDestinationType.CATEGORY:
                    from apps.categories.models import Category
                    if not Category.objects.filter(id=int_id).exists():
                        raise serializers.ValidationError({"internal_destination_id": "Invalid CATEGORY destination"})
                elif int_type == InternalDestinationType.OFFER:
                    from apps.catalog.models import Offer
                    if not Offer.objects.filter(id=int_id).exists():
                        raise serializers.ValidationError({"internal_destination_id": "Invalid OFFER destination"})
            except Exception as e:
                raise serializers.ValidationError({"internal_destination_id": f"Invalid format for {int_type} ID: {str(e)}"})

        elif promotion_type == PromotionType.EXTERNAL:
            ext_url = data.get('external_url', getattr(self.instance, 'external_url', None))
            if not ext_url:
                raise serializers.ValidationError({"external_url": "external_url is required for EXTERNAL promotions"})
            
            # Reset internal values
            data['internal_destination_type'] = None
            data['internal_destination_id'] = None

        return data


class PromotionPublicSerializer(serializers.ModelSerializer):
    destination = serializers.SerializerMethodField()

    class Meta:
        model = Promotion
        fields = [
            'id', 'title', 'subtitle', 'image_url', 'promotion_type', 
            'destination', 'priority'
        ]

    def get_destination(self, obj):
        if obj.promotion_type == PromotionType.APP:
            return {
                "type": obj.internal_destination_type,
                "id": str(obj.internal_destination_id) if obj.internal_destination_id else None
            }
        elif obj.promotion_type == PromotionType.EXTERNAL:
            return {
                "type": "EXTERNAL",
                "url": obj.external_url
            }
        return None
