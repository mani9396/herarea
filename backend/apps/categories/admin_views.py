import logging
from rest_framework import status, exceptions
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema
from apps.accounts.permissions import IsAdminRole
from apps.categories.models import Category
from apps.categories.serializers import CategorySerializer

logger = logging.getLogger('her_area')

class AdminCategoryListView(APIView):
    """Executive control center: Enumerate all categories (active & inactive) or commission new taxonomy nodes."""
    permission_classes = [IsAdminRole]
    serializer_class = CategorySerializer

    @extend_schema(summary="List All Categories (Admin View)", responses={200: CategorySerializer(many=True)})
    def get(self, request):
        categories = Category.objects.all().order_by('display_order', 'name')
        serializer = CategorySerializer(categories, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(summary="Create Taxonomy Category", request=CategorySerializer, responses={201: CategorySerializer})
    def post(self, request):
        serializer = CategorySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        category = serializer.save(created_by=request.user, updated_by=request.user)
        logger.info(f"Category '{category.name}' created by Admin {request.user.phone_number}")
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class AdminCategoryDetailView(APIView):
    """Modify taxonomy metadata, toggle active public visibility, or soft delete category classifications."""
    permission_classes = [IsAdminRole]
    serializer_class = CategorySerializer

    def _get_category(self, pk):
        try:
            return Category.objects.get(pk=pk)
        except Category.DoesNotExist:
            raise exceptions.NotFound("Target taxonomy category does not exist.")

    @extend_schema(summary="Inspect Category Metadata (Admin View)", responses={200: CategorySerializer})
    def get(self, request, pk):
        category = self._get_category(pk)
        return Response(CategorySerializer(category).data, status=status.HTTP_200_OK)

    @extend_schema(summary="Update Category Metadata & Visibility", request=CategorySerializer, responses={200: CategorySerializer})
    def put(self, request, pk):
        category = self._get_category(pk)
        serializer = CategorySerializer(category, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save(updated_by=request.user)
        logger.info(f"Category '{category.name}' ({category.id}) updated by Admin {request.user.phone_number}")
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(summary="Soft Delete Category Classification", responses={204: None})
    def delete(self, request, pk):
        category = self._get_category(pk)
        category_name = category.name
        category.delete()  # Inherits soft-delete behavior setting is_deleted=True
        logger.warning(f"Category '{category_name}' ({pk}) soft-deleted by Admin {request.user.phone_number}")
        return Response(status=status.HTTP_204_NO_CONTENT)
