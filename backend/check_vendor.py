import os
import sys
import django

sys.path.append(r"C:\Users\DHANISHA IT S\Desktop\Her Area\backend")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from apps.vendors.models import VendorProfile
vp = VendorProfile.objects.get(business_profile__business_name="sree aaradhya clicks")
print(f'Status: {vp.status}, ChatStatus: {vp.chat_status}, Subs: {vp.subscriptions.count()}')
print(f'Effective Chat Access: {vp.effective_chat_access}')
