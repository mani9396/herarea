import os
import hashlib
from django.core.management.base import BaseCommand
from django.db import transaction
from apps.accounts.models import User, UserRole

class Command(BaseCommand):
    help = 'Creates or updates the 3 demo users for client demonstrations.'

    def handle(self, *args, **options):
        if os.environ.get('ENABLE_DEMO_USERS', '').lower() != 'true':
            self.stdout.write(self.style.WARNING("ENABLE_DEMO_USERS is not set to 'true'. Skipping demo user creation."))
            return
            
        demo_password = os.environ.get('DEMO_PASSWORD')
        if not demo_password:
            self.stdout.write(self.style.ERROR("DEMO_PASSWORD environment variable is required."))
            return

        demo_accounts = [
            {
                'email': 'customer.demo@herarea.com',
                'password': demo_password,
                'role': UserRole.CUSTOMER,
                'full_name': 'Customer Demo',
            },
            {
                'email': 'vendor.demo@herarea.com',
                'password': demo_password,
                'role': UserRole.VENDOR,
                'full_name': 'Vendor Demo',
            },
            {
                'email': 'admin.demo@herarea.com',
                'password': demo_password,
                'role': UserRole.ADMIN,
                'full_name': 'Admin Demo',
            }
        ]

        with transaction.atomic():
            for account in demo_accounts:
                email = account['email']
                role = account['role']
                
                # We need a dummy phone number since it is the USERNAME_FIELD
                # We use MD5 of the email to keep it unique but deterministic
                dummy_phone = '+00' + hashlib.md5(email.encode()).hexdigest()[:12]
                
                user = User.objects.filter(email=email).first()
                if not user:
                    user = User(
                        email=email,
                        phone_number=dummy_phone,
                    )
                    
                user.role = role
                user.full_name = account['full_name']
                user.is_active = True
                user.is_verified = True
                user.is_staff = (role == UserRole.ADMIN or role == UserRole.SUPERADMIN)
                # Ensure they don't get forced to change password
                user.must_change_password = False 
                
                user.set_password(account['password'])
                user.save()
                
                self.stdout.write(
                    self.style.SUCCESS(f'Successfully created/updated {role} demo account: {email}')
                )
