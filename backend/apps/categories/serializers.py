from rest_framework import serializers
from apps.categories.models import Category

class CategorySerializer(serializers.ModelSerializer):
    subcategories = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = [
            'id', 'name', 'slug', 'description', 'icon_url', 
            'parent_category', 'subcategories', 'is_active', 
            'display_order', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'slug', 'created_at', 'updated_at']

    def get_subcategories(self, obj) -> list:
        # Prevent infinite recursion: only embed immediate active children
        children = obj.subcategories.filter(is_active=True).order_by('display_order', 'name')
        if not children.exists():
            return []
        return [
            {
                "id": str(child.id),
                "name": child.name,
                "slug": child.slug,
                "icon_url": child.icon_url,
                "display_order": child.display_order
            }
            for child in children
        ]
