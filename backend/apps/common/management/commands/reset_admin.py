from django.core.management.base import BaseCommand
from apps.accounts.models import User, UserRole

class Command(BaseCommand):
    help = 'Resets or creates the admin credentials'

    def handle(self, *args, **options):
        email = "admin@herarea.com"
        phone = "+919999999999"
        password = "AdminPassword123!"

        # Find existing admin by email, or create new
        try:
            admin_user = User.objects.get(email=email)
            created = False
        except User.DoesNotExist:
            admin_user = User(email=email, phone_number=phone)
            created = True

        # Force reset all credentials and permissions
        admin_user.set_password(password)
        admin_user.role = UserRole.ADMIN
        admin_user.full_name = 'System Admin'
        admin_user.is_staff = True
        admin_user.is_superuser = True
        admin_user.is_verified = True
        admin_user.save()

        self.stdout.write(self.style.SUCCESS("="*50))
        if created:
            self.stdout.write(self.style.SUCCESS("NEW ADMIN ACCOUNT CREATED SUCCESSFULLY"))
        else:
            self.stdout.write(self.style.SUCCESS("ADMIN CREDENTIALS RESET SUCCESSFULLY"))
        self.stdout.write(self.style.SUCCESS("="*50))
        self.stdout.write(f"Email:    {email}")
        self.stdout.write(f"Phone:    {admin_user.phone_number}")
        self.stdout.write(f"Password: {password}")
        self.stdout.write(self.style.SUCCESS("="*50))
