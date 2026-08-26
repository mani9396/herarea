import logging
from django.core.management.base import BaseCommand
from django.utils.text import slugify
from apps.categories.models import Category

logger = logging.getLogger(__name__)

INITIAL_CATEGORIES = {
    "Fashion & Clothing": {
        "icon": "styler",
        "subs": ["Women's Clothing", "Men's Clothing", "Kids' Clothing", "Ethnic Wear", "Western Wear", "Sarees", "Dress Materials", "Tailoring & Alterations"]
    },
    "Beauty & Personal Care": {
        "icon": "face",
        "subs": ["Cosmetics & Makeup", "Skincare", "Hair Care", "Personal Care", "Salons", "Beauty Parlours", "Spa & Wellness"]
    },
    "Jewellery & Accessories": {
        "icon": "diamond",
        "subs": ["Jewellery", "Artificial Jewellery", "Watches", "Accessories", "Handbags", "Footwear"]
    },
    "Home & Kitchen": {
        "icon": "chair",
        "subs": ["Home Decor", "Kitchen", "Furniture", "Home Essentials", "Cooking Supplies"]
    },
    "Food & Cooking": {
        "icon": "restaurant",
        "subs": ["Home Food", "Bakers", "Cakes", "Catering", "Cooking Services", "Cooking Classes"]
    },
    "Health & Wellness": {
        "icon": "health_and_safety",
        "subs": ["Doctor Consultation", "Fitness", "Yoga", "Nutrition", "Wellness Services"]
    },
    "Professional & Financial Services": {
        "icon": "work",
        "subs": ["Jobs & Careers", "Professional Services", "Banking Services", "Financial Advice", "Insurance Services", "Accounting"]
    },
    "Home & Local Services": {
        "icon": "plumbing",
        "subs": ["Cleaning", "Repairs", "Electricians", "Plumbers", "Home Maintenance", "Other Local Services"]
    },
    "Wedding & Events": {
        "icon": "celebration",
        "subs": ["Bridal Services", "Wedding Services", "Wedding Wear", "Event Planning", "Decoration", "Photography", "Gifting"]
    },
    "Books & Entertainment": {
        "icon": "menu_book",
        "subs": ["Novels", "Books", "Online Games", "Hobbies", "Classes & Activities"]
    },
    "Gifts & Special Occasions": {
        "icon": "redeem",
        "subs": ["Gifts", "Custom Gifts", "Flowers", "Hampers", "Celebration Services"]
    },
    "Other Local Businesses": {
        "icon": "storefront",
        "subs": ["Other"]
    }
}

class Command(BaseCommand):
    help = "Seeds the database with initial Categories and Subcategories."

    def handle(self, *args, **options):
        self.stdout.write("Seeding categories...")

        display_order = 1
        for parent_name, data in INITIAL_CATEGORIES.items():
            parent_slug = slugify(parent_name)
            parent_cat, created = Category.objects.get_or_create(
                slug=parent_slug,
                defaults={
                    "name": parent_name,
                    "icon_url": data["icon"],
                    "display_order": display_order
                }
            )
            
            if created:
                self.stdout.write(self.style.SUCCESS(f"Created category: {parent_name}"))
            else:
                self.stdout.write(f"Category already exists: {parent_name}")

            sub_display_order = 1
            for sub_name in data["subs"]:
                sub_slug = slugify(f"{parent_name}-{sub_name}")
                sub_cat, sub_created = Category.objects.get_or_create(
                    slug=sub_slug,
                    defaults={
                        "name": sub_name,
                        "parent_category": parent_cat,
                        "display_order": sub_display_order
                    }
                )
                if sub_created:
                    self.stdout.write(self.style.SUCCESS(f"  Created subcategory: {sub_name}"))
                sub_display_order += 1
                
            display_order += 1
            
        self.stdout.write(self.style.SUCCESS("Successfully seeded categories."))
