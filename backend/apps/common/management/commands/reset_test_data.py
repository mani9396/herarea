import os
from django.core.management.base import BaseCommand, CommandError
from django.conf import settings
from django.db import transaction
from django.db import models

from apps.accounts.models import User
from apps.vendors.models import VendorProfile, KycDocument
from apps.business.models import BusinessProfile, StoreMedia
from apps.catalog.models import Product, GalleryImage, Offer
from apps.operations.models import VendorSchedule, AppointmentBooking, ProductEnquiry
from apps.subscriptions.models import VendorSubscription, PaymentRecord
from apps.interactions.models import Favorite, RecentlyViewedStore, StoreVisit, Review
from apps.notifications.models import Notification

class Command(BaseCommand):
    help = 'Safely clears application/test data while preserving user accounts and master data.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--confirm',
            action='store_true',
            help='Must be provided to execute the destructive data reset.',
        )

    def delete_instance_files(self, instance):
        """Safely delete associated files for a model instance."""
        for field in instance._meta.fields:
            if isinstance(field, (models.FileField, models.ImageField)):
                file_attr = getattr(instance, field.name)
                if file_attr and hasattr(file_attr, 'path'):
                    try:
                        if os.path.exists(file_attr.path):
                            os.remove(file_attr.path)
                    except Exception as e:
                        self.stderr.write(self.style.WARNING(f"Failed to delete file {file_attr.path}: {e}"))

    def handle(self, *args, **options):
        if not options['confirm']:
            raise CommandError("You must provide the --confirm flag to execute this command.")

        if not settings.DEBUG:
            raise CommandError("ABORTED: This command cannot be run in production (DEBUG=False).")

        self.stdout.write(self.style.WARNING("Starting controlled test data reset..."))

        models_to_clear = [
            # Interactions & Notifications (Leaf nodes)
            Review, StoreVisit, RecentlyViewedStore, Favorite, Notification,
            
            # Operations
            AppointmentBooking, ProductEnquiry, VendorSchedule,
            
            # Subscriptions
            PaymentRecord, VendorSubscription,
            
            # Catalog
            GalleryImage, Offer, Product,
            
            # Business
            StoreMedia, BusinessProfile,
            
            # Vendors
            KycDocument, VendorProfile,
        ]

        with transaction.atomic():
            # 1. Sweep and delete Demo Users completely
            demo_users = User.objects.filter(
                models.Q(email__in=['customer.demo@herarea.com', 'vendor.demo@herarea.com', 'admin.demo@herarea.com']) |
                models.Q(email__icontains='demo')
            )
            demo_count = demo_users.count()
            if demo_count > 0:
                self.stdout.write(f"Found {demo_count} demo user accounts. Deleting them and their associated data...")
                for u in demo_users:
                    self.delete_instance_files(u)
                demo_users.delete()

            # 2. Iterate application models, clear files, and delete records
            for model in models_to_clear:
                queryset = model.objects.all()
                count = queryset.count()
                if count > 0:
                    self.stdout.write(f"Clearing {count} records from {model.__name__}...")
                    for obj in queryset:
                        self.delete_instance_files(obj)
                    queryset.delete()

        self.stdout.write(self.style.SUCCESS("✅ Test data reset successfully completed!"))
        
        # Summary
        self.stdout.write("\nRemaining Accounts:")
        remaining_users = User.objects.all()
        for u in remaining_users:
            self.stdout.write(f" - {u.email} (Role: {u.role})")
        
        self.stdout.write("\nMaster Data Retained:")
        from apps.categories.models import Category
        from apps.subscriptions.models import ListingPlan
        self.stdout.write(f" - Categories: {Category.objects.count()}")
        self.stdout.write(f" - Listing Plans: {ListingPlan.objects.count()}")