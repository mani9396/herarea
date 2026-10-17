import os
import uuid
from django.core.files.storage import default_storage
from rest_framework import serializers
from django.utils import timezone
from apps.catalog.models import Product, GalleryImage, Offer, Promotion, PromotionType, InternalDestinationType, Story, StoryType, StoryStatus

class ProductSerializer(serializers.ModelSerializer):
    store_id = serializers.UUIDField(source='business_profile.id', read_only=True)
    store_name = serializers.CharField(source='business_profile.business_name', read_only=True)
    store_city = serializers.CharField(source='business_profile.city', read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    image_url = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    image_file = serializers.FileField(required=False, write_only=True, allow_null=True)
    image = serializers.FileField(required=False, write_only=True, allow_null=True)

    class Meta:
        model = Product
        fields = [
            'id', 'item_type', 'category', 'subcategory', 'category_name', 'store_id', 'store_name', 'store_city', 
            'name', 'description', 'price', 'discounted_price', 
            'stock_status', 'service_duration_minutes', 'image_url', 'image_file', 'image', 'additional_images', 'is_featured', 'is_active', 
            'status', 'admin_remarks', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'store_id', 'store_name', 'store_city', 'category_name', 'status', 'admin_remarks', 'created_at', 'updated_at']

    def to_internal_value(self, data):
        if hasattr(data, 'copy'):
            data = data.copy()
        elif isinstance(data, dict):
            data = dict(data)

        # Check for uploaded file
        file_obj = None
        if 'image_file' in data and data['image_file'] and not isinstance(data['image_file'], str):
            file_obj = data.pop('image_file')
        elif 'image' in data and data['image'] and not isinstance(data['image'], str):
            file_obj = data.pop('image')

        # Fallback inspection of request.FILES
        request = self.context.get('request')
        if not file_obj and request and hasattr(request, 'FILES'):
            if 'image_file' in request.FILES:
                file_obj = request.FILES['image_file']
            elif 'image' in request.FILES:
                file_obj = request.FILES['image']

        if file_obj:
            ext = os.path.splitext(getattr(file_obj, 'name', ''))[1] or '.jpg'
            filename = f"products/{uuid.uuid4().hex}{ext}"
            saved_path = default_storage.save(filename, file_obj)
            media_path = f"/media/{saved_path}"
            if request:
                full_url = request.build_absolute_uri(media_path)
            else:
                full_url = f"http://127.0.0.1:8000{media_path}"
            data['image_url'] = full_url

        ret = super().to_internal_value(data)
        return ret

    def validate(self, attrs):
        if self.instance is None:
            image_url = attrs.get('image_url')
            if not image_url:
                raise serializers.ValidationError({'image_file': 'Please upload an original product photo from your gallery.'})
        return attrs

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        url = ret.get('image_url')
        if url and not url.startswith('http'):
            request = self.context.get('request')
            if request:
                ret['image_url'] = request.build_absolute_uri(url)
            else:
                ret['image_url'] = f"http://127.0.0.1:8000{url}"
        return ret



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


class StorySerializer(serializers.ModelSerializer):
    """
    Serializer delivering Story data to Customer and Vendor clients.
    Exposes reliable story_type and, only for product-linked Stories, the linked product details.
    """
    store = serializers.SerializerMethodField()
    media_url = serializers.SerializerMethodField()
    product_id = serializers.SerializerMethodField()
    product = serializers.SerializerMethodField()
    is_product_available = serializers.SerializerMethodField()
    time_remaining_seconds = serializers.SerializerMethodField()

    class Meta:
        model = Story
        fields = [
            'id',
            'store',
            'story_type',
            'media_url',
            'media_type',
            'title',
            'caption',
            'price',
            'promotional_price',
            'product_id',
            'product',
            'is_product_available',
            'published_at',
            'expires_at',
            'time_remaining_seconds',
            'status',
            'is_active',
        ]
        read_only_fields = fields

    def get_store(self, obj):
        bp = obj.business_profile
        if not bp:
            return None
        logo_url = None
        if bp.logo:
            try:
                logo_url = bp.logo.url
            except Exception:
                pass
        request = self.context.get('request')
        if logo_url and request and not logo_url.startswith('http'):
            logo_url = request.build_absolute_uri(logo_url)
        elif logo_url and not logo_url.startswith('http'):
            logo_url = f"http://127.0.0.1:8000{logo_url}"
        return {
            'id': str(bp.id),
            'name': bp.business_name,
            'logo': logo_url,
            'city': bp.city,
            'area': bp.area,
        }

    def get_media_url(self, obj) -> str:
        request = self.context.get('request')
        url = obj.effective_media_url
        if url and request and not url.startswith('http'):
            return request.build_absolute_uri(url)
        if url and not url.startswith('http'):
            return f"http://127.0.0.1:8000{url}"
        return url

    def get_product_id(self, obj):
        # Strict requirement: ONLY for product_linked stories with non-deleted product return product_id
        if obj.story_type == StoryType.PRODUCT_LINKED and obj.product and not getattr(obj.product, 'is_deleted', False):
            return str(obj.product_id)
        return None

    def get_product(self, obj):
        # Strict requirement: ONLY for product_linked stories with non-deleted product return linked product summary
        if obj.story_type == StoryType.PRODUCT_LINKED and obj.product and not getattr(obj.product, 'is_deleted', False):
            p = obj.product
            return {
                'id': str(p.id),
                'name': p.name,
                'price': float(p.price) if p.price is not None else 0.0,
                'discounted_price': float(p.discounted_price) if p.discounted_price is not None else None,
                'image_url': p.image_url,
                'stock_status': p.stock_status,
                'is_available': p.is_active and not p.is_deleted and p.status == 'APPROVED' and p.stock_status != 'OUT_OF_STOCK',
            }
        return None

    def get_is_product_available(self, obj) -> bool:
        if obj.story_type == StoryType.PRODUCT_LINKED and obj.product:
            p = obj.product
            return bool(p.is_active and not p.is_deleted and p.status == 'APPROVED' and p.stock_status != 'OUT_OF_STOCK')
        return False

    def get_time_remaining_seconds(self, obj) -> int:
        now = timezone.now()
        if obj.expires_at > now:
            return int((obj.expires_at - now).total_seconds())
        return 0


class VendorStoryCreateSerializer(serializers.ModelSerializer):
    """
    Handles validation and publishing of new Stories by authenticated vendors.
    Enforces Option A (Select from My Store Products) and Option B (Upload from Gallery).
    """
    product_id = serializers.UUIDField(required=False, allow_null=True)
    media_file = serializers.FileField(required=False, allow_null=True)

    class Meta:
        model = Story
        fields = [
            'id',
            'story_type',
            'product_id',
            'media_file',
            'media_url',
            'media_type',
            'title',
            'caption',
            'price',
            'promotional_price',
            'published_at',
            'expires_at',
            'status',
            'is_active',
        ]
        read_only_fields = ['id', 'published_at', 'expires_at', 'status', 'is_active']

    def to_internal_value(self, data):
        # Support both 'media' and 'media_file' key seamlessly from multipart uploads
        if hasattr(data, 'copy'):
            data = data.copy()
        elif isinstance(data, dict):
            data = dict(data)
        if hasattr(data, '__getitem__') and 'media' in data and 'media_file' not in data:
            data['media_file'] = data['media']
        return super().to_internal_value(data)

    def validate_story_type(self, value):
        val = value.lower()
        if val in ['external', 'gallery_uploaded']:
            return StoryType.GALLERY_UPLOADED
        if val == 'product_linked':
            return StoryType.PRODUCT_LINKED
        raise serializers.ValidationError(f"Invalid story_type '{value}'. Must be 'product_linked' or 'gallery_uploaded'.")

    def validate(self, attrs):
        business = self.context.get('business_profile')
        story_type = attrs.get('story_type', StoryType.GALLERY_UPLOADED)
        product_id = attrs.get('product_id')

        # Fallback inspection of request.FILES if not populated in attrs
        request = self.context.get('request')
        if not attrs.get('media_file') and request and hasattr(request, 'FILES'):
            if 'media_file' in request.FILES:
                attrs['media_file'] = request.FILES['media_file']
            elif 'media' in request.FILES:
                attrs['media_file'] = request.FILES['media']

        # 1. Price validations (must be non-negative, promotional <= regular price)
        price = attrs.get('price')
        promotional_price = attrs.get('promotional_price')
        if price is not None and price < 0:
            raise serializers.ValidationError({'price': 'Price cannot be negative.'})
        if promotional_price is not None and promotional_price < 0:
            raise serializers.ValidationError({'promotional_price': 'Promotional price cannot be negative.'})
        if price is not None and promotional_price is not None and promotional_price > price:
            raise serializers.ValidationError({'promotional_price': 'Promotional price cannot exceed regular price.'})

        # 2. Option A: Product Linked
        if story_type == StoryType.PRODUCT_LINKED:
            if not product_id:
                raise serializers.ValidationError({'product_id': 'Product selection is required for product-linked stories.'})
            try:
                product = Product.objects.get(pk=product_id, business_profile=business, is_deleted=False)
            except Product.DoesNotExist:
                raise serializers.ValidationError({'product_id': 'Selected product does not belong to your store showroom or does not exist.'})

            attrs['product'] = product
            # Auto-populate details from the existing product record
            if not attrs.get('title'):
                attrs['title'] = product.name
            if not attrs.get('media_url') and not attrs.get('media_file'):
                attrs['media_url'] = product.image_url
            if attrs.get('price') is None:
                attrs['price'] = product.price
            if attrs.get('promotional_price') is None:
                attrs['promotional_price'] = product.discounted_price

        # 3. Option B: Gallery Uploaded / External
        elif story_type == StoryType.GALLERY_UPLOADED:
            # Must NOT link product or invent a product ID
            attrs['product'] = None
            attrs.pop('product_id', None)
            if not attrs.get('media_file') and not attrs.get('media_url'):
                raise serializers.ValidationError({'media_file': 'Please select an image or video from your device gallery.'})

        return attrs

    def create(self, validated_data):
        business = self.context.get('business_profile')
        user = self.context.get('request').user if self.context.get('request') else None
        validated_data['business_profile'] = business
        validated_data['created_by'] = user
        validated_data['updated_by'] = user
        return super().create(validated_data)

