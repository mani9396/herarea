import os
from django.core.management.base import BaseCommand
from django.utils.text import slugify
from apps.categories.models import Category

class Command(BaseCommand):
    help = 'Seeds initial real categories and subcategories for HER AREA.'

    def handle(self, *args, **options):
        self.stdout.write("Seeding categories...")

        categories_data = [
            {
                "name": "Bridal Wear",
                "icon_url": "checkroom",
                "subcategories": ["Designer Lehengas", "Bridal Gowns", "Half Sarees", "Anarkalis"]
            },
            {
                "name": "Sarees",
                "icon_url": "dry_cleaning",
                "subcategories": ["Kanjeevaram", "Banarasi", "Chanderi", "Cotton Silk", "Pattu Sarees"]
            },
            {
                "name": "Jewelry",
                "icon_url": "diamond",
                "subcategories": ["Gold Jewelry", "Diamond Sets", "Temple Jewelry", "Imitation Jewelry"]
            },
            {
                "name": "Beauty & Salons",
                "icon_url": "face_retouching_natural",
                "subcategories": ["Bridal Makeup", "Hair Styling", "Spa & Wellness", "Mehendi Artists"]
            },
            {
                "name": "Custom Tailoring",
                "icon_url": "content_cut",
                "subcategories": ["Maggam Work", "Aari Work", "Blouse Stitching", "Custom Dresses"]
            }
        ]

        for idx, cat_data in enumerate(categories_data):
            parent, created = Category.objects.get_or_create(
                slug=slugify(cat_data["name"]),
                defaults={
                    "name": cat_data["name"],
                    "icon_url": cat_data["icon_url"],
                    "display_order": idx
                }
            )
            if created:
                self.stdout.write(f"Created parent category: {parent.name}")

            for sub_idx, sub_name in enumerate(cat_data["subcategories"]):
                sub, sub_created = Category.objects.get_or_create(
                    slug=slugify(sub_name),
                    defaults={
                        "name": sub_name,
                        "parent_category": parent,
                        "display_order": sub_idx
                    }
                )
                if sub_created:
                    self.stdout.write(f" - Created subcategory: {sub.name}")

        self.stdout.write(self.style.SUCCESS("✅ Categories successfully seeded!"))