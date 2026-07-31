import os
from rest_framework import exceptions

DEFAULT_ALLOWED_EXTENSIONS = ('.jpg', '.jpeg', '.png', '.webp', '.pdf')
DEFAULT_MAX_SIZE_MB = 5

def validate_file_security_and_size(file_obj, max_size_mb=DEFAULT_MAX_SIZE_MB, allowed_extensions=DEFAULT_ALLOWED_EXTENSIONS):
    """
    Production-grade security validator for handling uploaded media and document files.
    Verifies maximum file size thresholds and strictly whitelists valid operational extensions
    to mitigate malicious arbitrary file execution and storage exhaustion attacks.
    """
    if not file_obj:
        return

    # 1. Validate File Size
    file_size = getattr(file_obj, 'size', 0)
    max_bytes = max_size_mb * 1024 * 1024
    if file_size > max_bytes:
        raise exceptions.ValidationError({
            "file": f"File size exceeds maximum permitted threshold of {max_size_mb} MB (Uploaded: {round(file_size / (1024 * 1024), 2)} MB)."
        })

    # 2. Validate Whitelisted File Extension & Name Safety
    filename = getattr(file_obj, 'name', '')
    if not filename:
        raise exceptions.ValidationError({"file": "Uploaded file is missing a reliable file name."})

    ext = os.path.splitext(filename)[1].lower()
    if ext not in allowed_extensions:
        raise exceptions.ValidationError({
            "file": f"Unsupported or prohibited file type '{ext}'. Allowed operational formats: {', '.join(allowed_extensions)}."
        })

    # 3. Prevent directory traversal tampering
    if '..' in filename or filename.startswith('/'):
        raise exceptions.ValidationError({"file": "File name contains illegal path traversal characters."})

    return True
