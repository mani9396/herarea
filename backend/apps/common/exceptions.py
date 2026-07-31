import logging
from datetime import datetime, timezone
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status, exceptions

logger = logging.getLogger('her_area')

ERROR_CODE_MAPPINGS = {
    exceptions.AuthenticationFailed: "AUTHENTICATION_FAILED",
    exceptions.NotAuthenticated: "NOT_AUTHENTICATED",
    exceptions.PermissionDenied: "PERMISSION_DENIED",
    exceptions.NotFound: "RESOURCE_NOT_FOUND",
    exceptions.ValidationError: "VALIDATION_ERROR",
    exceptions.Throttled: "THROttLING_LIMIT_EXCEEDED",
    exceptions.MethodNotAllowed: "METHOD_NOT_ALLOWED",
}

def custom_exception_handler(exc, context):
    """
    Standardized API JSON exception handler across all HER AREA domain applications.
    Transforms standard DRF errors and runtime exceptions into a uniform, machine-readable JSON format
    optimized for client ingestion and error parsing in Flutter Dio / Retrofit integrations:
    {
        "error": true,
        "error_code": "VALIDATION_ERROR",
        "status_code": 400,
        "message": "Human readable error detail",
        "details": { "field": ["detail"] },
        "timestamp": "2026-07-31T12:00:00Z"
    }
    """
    response = exception_handler(exc, context)
    view_name = context.get('view').__class__.__name__ if context.get('view') else 'UnknownView'
    logger.error(f"API Exception in {view_name}: {str(exc)}")

    timestamp = datetime.now(timezone.utc).isoformat()
    error_code = ERROR_CODE_MAPPINGS.get(type(exc), "API_ERROR")

    if response is not None:
        custom_response_data = {
            "error": True,
            "error_code": error_code,
            "status_code": response.status_code,
            "message": str(exc),
            "details": response.data,
            "timestamp": timestamp
        }
        if isinstance(response.data, dict) and 'detail' in response.data:
            custom_response_data['message'] = str(response.data['detail'])
        response.data = custom_response_data
    else:
        custom_response_data = {
            "error": True,
            "error_code": "INTERNAL_SERVER_ERROR",
            "status_code": status.HTTP_500_INTERNAL_SERVER_ERROR,
            "message": "Internal Server Error. An unexpected fault occurred during API execution.",
            "details": str(exc) if context.get('request') and context.get('request').META.get('HTTP_HOST', '').startswith('127') else "Contact system administration.",
            "timestamp": timestamp
        }
        return Response(custom_response_data, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return response
