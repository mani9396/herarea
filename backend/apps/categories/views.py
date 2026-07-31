import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions, exceptions
from drf_spectacular.utils import extend_schema
from apps.categories.models import Category
from apps.categories.serializers import CategorySerializer

logger = logging.getLogger('her_area')

class PublicCategoryListView(APIView):
    """
    Public discovery endpoint: Enumerate all active marketplace taxonomy categories and subcategories 
    to populate Customer App Home Dashboard and Vendor Studio category selectors.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = CategorySerializer

    @extend_schema(summary="List Active Marketplace Categories", responses={200: CategorySerializer(many=True)})
    def get(self, request):
        categories = Category.objects.filter(is_active=True, parent_category__isnull=True).order_by('display_order', 'name')
        serializer = CategorySerializer(categories, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class PublicCategoryDetailView(APIView):
    """Retrieve detailed information and nested subcategories for a specific taxonomy classification."""
    permission_classes = [permissions.AllowAny]
    serializer_class = CategorySerializer

    @extend_schema(summary="Get Active Category Details", responses={200: CategorySerializer})
    def get(self, request, pk):
        try:
            category = Category.objects.get(pk=pk, is_active=True)
        except Category.DoesNotExist:
            raise exceptions.NotFound("Requested category classification does not exist or is currently inactive.")
        serializer = CategorySerializer(category)
        return Response(serializer.data, status=status.HTTP_200_OK)
