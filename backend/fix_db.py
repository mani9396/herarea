import os, sys, django
sys.path.append(r"C:\Users\DHANISHA IT S\Desktop\Her Area\backend")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from apps.vendors.models import VendorProfile, VendorStatus, ChatStatus
from apps.subscriptions.models import VendorSubscription, ListingPlan

plan, _ = ListingPlan.objects.get_or_create(
    name="Test Chat Plan",
    defaults={
        "price": 0,
        "duration_days": 365,
        "customer_chat": True
    }
)
plan.customer_chat = True
plan.save()

for vp in VendorProfile.objects.all():
    vp.status = VendorStatus.APPROVED
    vp.chat_status = ChatStatus.ACTIVE
    vp.save()
    
    if hasattr(vp, 'business_profile'):
        VendorSubscription.objects.update_or_create(
            vendor=vp.user,
            store=vp.business_profile,
            defaults={
                "plan": plan,
                "status": "ACTIVE"
            }
        )
print("Updated all vendors to have chat access.")
