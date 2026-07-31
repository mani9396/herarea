from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models
from apps.common.models import AbstractTimestampUUIDModel
from apps.accounts.managers import CustomUserManager

class UserRole(models.TextChoices):
    CUSTOMER = 'CUSTOMER', 'Customer (app_user)'
    VENDOR = 'VENDOR', 'Partner Studio Owner (app_vendor)'
    ADMIN = 'ADMIN', 'Staff Moderator & Governance (app_admin)'
    SUPERADMIN = 'SUPERADMIN', 'Platform Founder & Executive (app_admin)'

class User(AbstractBaseUser, PermissionsMixin, AbstractTimestampUUIDModel):
    """
    Master authentication identity model utilizing UUIDv4 primary keys and RBAC role assertions.
    Decoupled from operational profiles per Phase 4 clean design specifications.
    """
    phone_number = models.CharField(max_length=20, unique=True, db_index=True, help_text='Primary OTP login number')
    email = models.EmailField(unique=True, null=True, blank=True, help_text='Official account contact email')
    role = models.CharField(max_length=20, choices=UserRole.choices, default=UserRole.CUSTOMER, db_index=True)
    
    is_active = models.BooleanField(default=True, help_text='Designates whether this account is active')
    is_verified = models.BooleanField(default=False, help_text='Indicates completed KYC or OTP phone verification')
    is_staff = models.BooleanField(default=False, help_text='Designates access to Django management admin site')
    
    two_factor_secret = models.CharField(max_length=100, null=True, blank=True, help_text='Cryptographic 2FA secret token')

    objects = CustomUserManager()

    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['role']

    class Meta:
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['role', 'is_active']),
        ]

    def __str__(self):
        return f"{self.phone_number} ({self.role})"
