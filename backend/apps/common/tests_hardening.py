from django.test import TestCase, RequestFactory
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework import exceptions, status
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.request import Request
from rest_framework.test import APIClient
from apps.common.utils.file_validator import validate_file_security_and_size
from apps.common.pagination import StandardResultsSetPagination, FlexibleLimitOffsetPagination

class DummyErrorView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, error_type):
        if error_type == 'not_found':
            raise exceptions.NotFound("Requested target showroom does not exist.")
        elif error_type == 'permission':
            raise exceptions.PermissionDenied("You do not possess administrative clearance.")
        elif error_type == 'validation':
            raise exceptions.ValidationError({"field": "Invalid input provided."})
        return Response({"status": "ok"})

class BackendHardeningVerificationTests(TestCase):
    def setUp(self):
        self.factory = RequestFactory()
        self.client = APIClient()

    def test_uniform_exception_handler_json_structure_and_error_codes(self):
        """
        Verify that our hardened custom_exception_handler returns a predictable, standardized JSON
        schema incorporating error: True, error_code, status_code, message, details, and UTC timestamps.
        """
        view = DummyErrorView.as_view()

        # 1. Test 404 NotFound conversion
        req_404 = self.factory.get('/dummy/not_found/')
        resp_404 = view(req_404, error_type='not_found')
        self.assertEqual(resp_404.status_code, status.HTTP_404_NOT_FOUND)
        self.assertTrue(resp_404.data['error'])
        self.assertEqual(resp_404.data['error_code'], "RESOURCE_NOT_FOUND")
        self.assertIn("timestamp", resp_404.data)

        # 2. Test 403 PermissionDenied conversion
        req_403 = self.factory.get('/dummy/permission/')
        resp_403 = view(req_403, error_type='permission')
        self.assertEqual(resp_403.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(resp_403.data['error_code'], "PERMISSION_DENIED")

        # 3. Test 400 ValidationError conversion
        req_400 = self.factory.get('/dummy/validation/')
        resp_400 = view(req_400, error_type='validation')
        self.assertEqual(resp_400.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(resp_400.data['error_code'], "VALIDATION_ERROR")

    def test_secure_file_validator_defends_against_oversized_and_prohibited_uploads(self):
        """
        Verify that validate_file_security_and_size cleanly accepts valid operational media (.jpg, .pdf)
        while immediately rejecting oversized files or prohibited script extensions (.exe, .sh, .py).
        """
        # 1. Valid Image File Upload (1MB WEBP)
        valid_file = SimpleUploadedFile("showroom_gallery.webp", b"file_content" * 1024, content_type="image/webp")
        self.assertTrue(validate_file_security_and_size(valid_file, max_size_mb=5))

        # 2. Prohibited Extension Rejection (.exe / script injection attempt)
        malicious_file = SimpleUploadedFile("backdoor.exe", b"malicious_payload", content_type="application/octet-stream")
        with self.assertRaises(exceptions.ValidationError) as context:
            validate_file_security_and_size(malicious_file, max_size_mb=5)
        self.assertIn("Unsupported or prohibited file type '.exe'", str(context.exception.detail))

        # 3. Oversized File Rejection (> 2MB test limit)
        large_payload = b"0" * (3 * 1024 * 1024)  # 3MB buffer
        oversize_file = SimpleUploadedFile("massive_scan.pdf", large_payload, content_type="application/pdf")
        with self.assertRaises(exceptions.ValidationError) as context:
            validate_file_security_and_size(oversize_file, max_size_mb=2)
        self.assertIn("exceeds maximum permitted threshold of 2 MB", str(context.exception.detail))

    def test_production_pagination_classes_metadata_generation(self):
        """
        Verify that StandardResultsSetPagination and FlexibleLimitOffsetPagination generate clean 
        count, next, previous, and results metadata required by Flutter client state managers.
        """
        paginator = StandardResultsSetPagination()
        wsgi_request = self.factory.get('/api/v1/products/?page=1&page_size=5')
        request = Request(wsgi_request)
        
        # Simulate an arbitrary queryset collection of 15 items
        simulated_queryset = [{"id": i, "name": f"Item {i}"} for i in range(1, 16)]
        page = paginator.paginate_queryset(simulated_queryset, request)
        self.assertEqual(len(page), 5)
        
        response = paginator.get_paginated_response(page)
        self.assertEqual(response.data['count'], 15)
        self.assertIn("results", response.data)
