import os, sys, django
sys.path.append(r"C:\Users\DHANISHA IT S\Desktop\Her Area\backend")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from apps.accounts.models import User
admins = User.objects.filter(role__in=['ADMIN', 'SUPERADMIN'])
for a in admins:
    print(f'Admin: {a.email}')
