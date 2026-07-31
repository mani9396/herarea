from django.db import models
from django.conf import settings
from apps.common.models import AbstractBaseModel

class VendorStatus(models.TextChoices):
    PENDING = 'PENDING', 'Pending Admin Review'
    APPROVED = 'APPROVED', 'Verified & Approved'
    REJECTED = 'REJECTED', 'Application Rejected'
    SUSPENDED = 'SUSPENDED', 'Temporarily Suspended'

class VendorProfile(AbstractBaseModel):
    """
    Partner Studio legal account and onboarding state machine. 
    Controls whether a vendor can perform O2O marketplace showroom operations.
    """
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='vendor_profile',
        help_text='Associated authentication user account (Role: VENDOR)'
    )
    owner_name = models.CharField(max_length=150, help_text='Full legal name of primary business owner')
    official_email = models.EmailField(help_text='Business communication email address')
    phone_number = models.CharField(max_length=20, db_index=True, help_text='Primary contact telephone')
    
    status = models.CharField(
        max_length=20, 
        choices=VendorStatus.choices, 
        default=VendorStatus.PENDING, 
        db_index=True
    )
    rejection_reason = models.TextField(
        null=True, 
        blank=True, 
        help_text='Feedback provided by governance admin upon rejection or suspension'
    )
    
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='approved_vendor_studios'
    )
    approved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = 'Vendor Profile'
        verbose_name_plural = 'Vendor Profiles'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.owner_name} ({self.get_status_display()})"


class KycDocType(models.TextChoices):
    GSTIN = 'GSTIN', 'GSTIN Tax Registration Certificate'
    PAN = 'PAN', 'Business / Personal PAN Card'
    TRADE_LICENSE = 'TRADE_LICENSE', 'Shop & Establishment / Trade License'
    ID_PROOF = 'ID_PROOF', 'Owner Government Identity Proof'
    ADDRESS_PROOF = 'ADDRESS_PROOF', 'Studio Physical Address Proof'


class KycDocStatus(models.TextChoices):
    PENDING = 'PENDING', 'Pending Verification'
    VERIFIED = 'VERIFIED', 'Verified & Accepted'
    REJECTED = 'REJECTED', 'Rejected Document'


class KycDocument(AbstractBaseModel):
    """
    Legal KYC compliance document repository submitted by partner studio vendors for administrative verification.
    """
    vendor = models.ForeignKey(
        VendorProfile, 
        on_delete=models.CASCADE, 
        related_name='kyc_documents',
        db_index=True
    )
    document_type = models.CharField(max_length=50, choices=KycDocType.choices)
    document_url = models.URLField(max_length=500, help_text='Secure storage URI of uploaded file')
    document_number = models.CharField(max_length=100, null=True, blank=True, help_text='License or registration identification number')
    status = models.CharField(max_length=20, choices=KycDocStatus.choices, default=KycDocStatus.PENDING)
    
    verified_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='verified_vendor_kyc_files'
    )
    verified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = 'KYC Document'
        verbose_name_plural = 'KYC Documents'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.get_document_type_display()} - {self.vendor.owner_name}"
