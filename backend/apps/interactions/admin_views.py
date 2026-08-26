import logging
from rest_framework import status, exceptions, serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema
from apps.accounts.permissions import IsAdminRole
from apps.interactions.models import Review
from apps.interactions.serializers import ReviewSerializer

logger = logging.getLogger('her_area')

class AdminReviewEnrichedSerializer(ReviewSerializer):
    vendor_name = serializers.CharField(source='store.business_name', read_only=True)
    customer_name = serializers.SerializerMethodField()
    is_reported = serializers.SerializerMethodField()
    report_reason = serializers.SerializerMethodField()
    date = serializers.SerializerMethodField()

    class Meta(ReviewSerializer.Meta):
        fields = ReviewSerializer.Meta.fields + ['vendor_name', 'customer_name', 'is_reported', 'report_reason', 'date']

    def get_customer_name(self, obj) -> str:
        phone = obj.user.phone_number if obj.user else "User"
        return f"Customer ({phone})"

    def get_is_reported(self, obj) -> bool:
        return obj.rating <= 2.0

    def get_report_reason(self, obj) -> str:
        return "Automated quality moderation flag (Low rating score)" if obj.rating <= 2.0 else ""

    def get_date(self, obj) -> str:
        return obj.created_at.strftime('%Y-%m-%d') if obj.created_at else "2026-08-01"


class AdminReviewListView(APIView):
    """
    Executive marketplace community reviews queue allowing Administrators to inspect all customer feedback.
    """
    permission_classes = [IsAdminRole]
    serializer_class = AdminReviewEnrichedSerializer

    @extend_schema(summary="List All Customer Reviews for Moderation & Governance")
    def get(self, request):
        reviews = Review.objects.select_related('store', 'user').order_by('-created_at')
        return Response(AdminReviewEnrichedSerializer(reviews, many=True).data, status=status.HTTP_200_OK)


class AdminReviewDetailView(APIView):
    """
    Executive moderation operations for community reviews (removal of spam or defamatory commentary).
    """
    permission_classes = [IsAdminRole]

    @extend_schema(summary="Update Customer Review Status")
    def patch(self, request, pk):
        try:
            review = Review.objects.get(pk=pk)
            status_val = request.data.get('status')
            admin_remarks = request.data.get('admin_remarks')
            
            if status_val:
                review.status = status_val
            if admin_remarks is not None:
                review.admin_remarks = admin_remarks
                
            review.updated_by = request.user
            review.save()
            
            logger.info(f"Admin {request.user.email} updated review {pk} status to {review.status}.")
            return Response(AdminReviewEnrichedSerializer(review).data, status=status.HTTP_200_OK)
        except Review.DoesNotExist:
            raise exceptions.NotFound("Review item not found.")

    @extend_schema(summary="Delete a Customer Review")
    def delete(self, request, pk):
        try:
            review = Review.objects.get(pk=pk)
            review.delete()
            logger.info(f"Admin {request.user.email} removed community review {pk}.")
            return Response({"detail": "Review deleted successfully."}, status=status.HTTP_204_NO_CONTENT)
        except Review.DoesNotExist:
            raise exceptions.NotFound("Review item not found.")
