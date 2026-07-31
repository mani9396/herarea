import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status
from django.db import connection
from drf_spectacular.utils import extend_schema, OpenApiResponse

logger = logging.getLogger('her_area')

class HealthCheckView(APIView):
    """
    System telemetry and infrastructure readiness probe endpoint.
    Verifies API worker responsiveness and relational database connectivity.
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="API Health Readiness Probe",
        description="Check real-time operational status of HER AREA Django REST API & Database engine.",
        responses={
            200: OpenApiResponse(description="All infrastructure operational and database verified."),
            503: OpenApiResponse(description="Database engine unreachable or service degraded.")
        }
    )
    def get(self, request):
        db_status = "connected"
        http_status = status.HTTP_200_OK
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
        except Exception as exc:
            logger.error(f"Health check database ping failed: {str(exc)}")
            db_status = f"unreachable ({str(exc)})"
            http_status = status.HTTP_503_SERVICE_UNAVAILABLE

        return Response({
            "status": "ok" if http_status == status.HTTP_200_OK else "degraded",
            "service": "HER AREA Unified Backend Engine",
            "version": "1.0.0-sprint1",
            "database": db_status,
        }, status=http_status)
