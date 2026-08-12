import os
import sys
import datetime
from decimal import Decimal
from django.utils import timezone
from django.contrib.auth.hashers import make_password

# Ensure Django environment is configured if run directly
import django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from apps.accounts.models import User, UserRole
from apps.categories.models import Category
from apps.vendors.models import VendorProfile, VendorStatus, KycDocument, KycDocType, KycDocStatus
from apps.business.models import BusinessProfile
from apps.catalog.models import Product, CatalogItemType, StockStatus, GalleryImage, Offer
from apps.interactions.models import Favorite, Review
from apps.operations.models import VendorSchedule, DayOfWeek, AppointmentBooking, BookingStatus, ProductEnquiry, EnquiryStatus
from apps.notifications.models import Notification, NotificationType

def run():
    print("=== HER AREA: Phase 7 Demo Data Seeding Script ===")
    print("Cleaning existing records from PostgreSQL database...")
    
    # Clean up tables in order to respect foreign key constraints (using all_objects to bypass soft deletion)
    for model in [Notification, AppointmentBooking, ProductEnquiry, Review, Favorite, Offer, GalleryImage, Product, VendorSchedule, BusinessProfile, KycDocument, VendorProfile, Category, User]:
        getattr(model, 'all_objects', model.objects).all().delete()
    
    print("Database cleaned successfully. Beginning seeding...")
    
    # Pre-hash passwords once for dramatic speed optimization
    super_pass = make_password("SuperAdmin@123")
    admin_pass = make_password("Admin@123")
    cust_pass = make_password("Customer@123")
    vendor_pass = make_password("Vendor@123")
    
    # 1. Seed Super Admin
    superadmin = User.objects.create(
        phone_number="+919000000000",
        email="superadmin@herarea.com",
        role=UserRole.SUPERADMIN,
        is_active=True,
        is_verified=True,
        is_staff=True,
        is_superuser=True,
        password=super_pass
    )
    print("[OK] Created 1 Super Admin (+919000000000)")

    # 2. Seed 2 Admin users
    admin1 = User.objects.create(
        phone_number="+919000000001",
        email="admin1@herarea.com",
        role=UserRole.ADMIN,
        is_active=True,
        is_verified=True,
        is_staff=True,
        password=admin_pass
    )
    admin2 = User.objects.create(
        phone_number="+919000000002",
        email="admin2@herarea.com",
        role=UserRole.ADMIN,
        is_active=True,
        is_verified=True,
        is_staff=True,
        password=admin_pass
    )
    print("[OK] Created 2 Admin accounts (+919000000001, +919000000002)")

    # 3. Seed 20 Customer accounts
    customers = []
    for i in range(1, 21):
        c = User.objects.create(
            phone_number=f"+9197000000{i:02d}",
            email=f"customer{i:02d}@gmail.com",
            role=UserRole.CUSTOMER,
            is_active=True,
            is_verified=True,
            password=cust_pass
        )
        customers.append(c)
    print(f"[OK] Created 20 Customer accounts (+919700000001 to +919700000020)")

    # 4. Seed 5 Categories
    cat_data = [
        ("Maggam Work", "maggam-work", "Traditional hand embroidery with antique gold zari and semi-precious stones.", "https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400"),
        ("Designer Sarees", "designer-sarees", "Handwoven Banarasi, Kanjivaram, and organza silk sarees.", "https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=400"),
        ("Bridal Trousseau", "bridal-trousseau", "Bespoke bridal wear, custom lehengas, and evening cocktail gowns.", "https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400"),
        ("Custom Boutique", "custom-boutique", "Tailored precision styling and blouse pattern customization.", "https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=400"),
        ("Jewellery & Accessories", "jewellery-accessories", "Temple jewelry, Polki necklaces, and handcrafted bridal clutches.", "https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=400"),
    ]
    categories = []
    for idx, (name, slug, desc, icon) in enumerate(cat_data):
        cat = Category.objects.create(
            name=name,
            slug=slug,
            description=desc,
            icon_url=icon,
            is_active=True,
            display_order=idx + 1
        )
        categories.append(cat)
    print("[OK] Created 5 Marketplace Categories")

    # 5. Seed 5 Approved Vendors & Business Profiles
    vendor_specs = [
        ("Anya Luxe Bridal & Maggam Studio", "Ananya Reddy", "+919800000001", "anya@studios.com", 0, 17.4156, 78.4201, "Banjara Hills, Road No 12", "Hyderabad", "Telangana", "500034", "https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=1200"),
        ("Varanasi Royal Weaves & Sarees", "Meenakshi Iyer", "+919800000002", "meenakshi@varanasiweaves.com", 1, 17.4289, 78.4111, "Jubilee Hills, Road No 36", "Hyderabad", "Telangana", "500033", "https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=1200"),
        ("Swarajya Custom Couture & Lehengas", "Priyanka Varma", "+919800000003", "priyanka@swarajya.com", 2, 17.4411, 78.3912, "HiTech City Main Road", "Hyderabad", "Telangana", "500081", "https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=1200"),
        ("Kalaa Temple & Polki Jewellery", "Sanya Kapoor", "+919800000004", "sanya@kalaajewels.com", 4, 17.4012, 78.4688, "Somajiguda Circle", "Hyderabad", "Telangana", "500082", "https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=1200"),
        ("Ekam Bespoke Blouses & Styling", "Radhika Sen", "+919800000005", "radhika@ekambespoke.com", 3, 17.4332, 78.4421, "Srinagar Colony Main Road", "Hyderabad", "Telangana", "500073", "https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=1200"),
    ]
    
    vendors = []
    stores = []
    
    for idx, (bname, owner, phone, email, cat_idx, lat, lng, addr, city, state, pin, cover) in enumerate(vendor_specs):
        v_user = User.objects.create(
            phone_number=phone,
            email=email,
            role=UserRole.VENDOR,
            is_active=True,
            is_verified=True,
            password=vendor_pass
        )
        v_profile = VendorProfile.objects.create(
            user=v_user,
            owner_name=owner,
            official_email=email,
            phone_number=phone,
            status=VendorStatus.APPROVED,
            approved_by=superadmin,
            approved_at=timezone.now()
        )
        vendors.append(v_profile)
        
        b_profile = BusinessProfile.objects.create(
            vendor=v_profile,
            category=categories[cat_idx],
            business_name=bname,
            description=f"Premier luxury bridal studio specializing in {categories[cat_idx].name}. Dedicated to exceptional Indian artisanship and bespoke consultations.",
            address_line_1=addr,
            city=city,
            state=state,
            pincode=pin,
            contact_email=email,
            contact_phone=phone,
            latitude=Decimal(str(lat)),
            longitude=Decimal(str(lng)),
            logo_url="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200",
            cover_url=cover,
            business_timings={"Monday": "10:00 - 19:00", "Tuesday": "10:00 - 19:00", "Wednesday": "10:00 - 19:00", "Thursday": "10:00 - 19:00", "Friday": "10:00 - 19:00", "Saturday": "11:00 - 20:00", "Sunday": "Closed"}
        )
        stores.append(b_profile)
        
        # Add KYC docs
        KycDocument.objects.create(
            vendor=v_profile,
            document_type=KycDocType.GSTIN,
            document_url="https://example.com/gstin.pdf",
            document_number=f"36AABCS{idx+1000}C1Z5",
            status=KycDocStatus.VERIFIED,
            verified_by=superadmin,
            verified_at=timezone.now()
        )
        
        # Add 7 Days Schedule
        for d in range(7):
            VendorSchedule.objects.create(
                business_profile=b_profile,
                day_of_week=d,
                open_time=datetime.time(10, 0),
                close_time=datetime.time(19, 0),
                is_closed=(d == 6), # Closed on Sundays
                slot_duration_minutes=60
            )
    print("[OK] Created 5 Approved Vendor Studios (+919800000001 to +919800000005) with KYC & Schedules")

    # 6. Seed 25 Products (5 per vendor)
    prod_names = [
        ("Zardozi Peacock Bridal Blouse", Decimal("24500.00"), Decimal("21000.00"), "Intricate antique gold hand embroidery with real Kasu pearls."),
        ("Banarasi Silk Kanjivaram Saree", Decimal("45000.00"), Decimal("38500.00"), "Pure Mulberry silk handwoven saree with temple gold zari borders."),
        ("Bespoke Crimson Velvet Lehenga", Decimal("85000.00"), Decimal("75000.00"), "Bridal lehenga with handcrafted Kundan and bead floral motifs."),
        ("Heritage Polki Temple Necklace", Decimal("125000.00"), None, "Gold plated pure silver temple jewelry set with matching emerald stud drops."),
        ("Organza Pastel Floral Dupatta", Decimal("14500.00"), Decimal("12000.00"), "Hand-painted floral silk organza dupatta with scalloped zari edges.")
    ]
    img_urls = [
        "https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800",
        "https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800",
        "https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800",
        "https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800",
        "https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=800"
    ]
    
    products = []
    for s_idx, store in enumerate(stores):
        for p_idx, (pname, price, disc, desc) in enumerate(prod_names):
            p = Product.objects.create(
                business_profile=store,
                category=categories[(s_idx + p_idx) % 5],
                item_type=CatalogItemType.PRODUCT,
                name=f"{pname} - Vol {s_idx+1}",
                description=desc,
                price=price,
                discounted_price=disc,
                stock_status=StockStatus.IN_STOCK if p_idx != 4 else StockStatus.MADE_TO_ORDER,
                image_url=img_urls[p_idx % len(img_urls)],
                is_featured=(p_idx == 0 or p_idx == 1),
                is_active=True
            )
            products.append(p)
    print(f"[OK] Created 25 Products ({len(products)} total)")

    # 7. Seed 15 Services (3 per vendor)
    service_defs = [
        ("Bridal Couture Styling Consultation", Decimal("2500.00"), "One-on-one personal session with the master designer to finalize silhouettes and fabric themes."),
        ("Custom Fit Measurement & Trial", Decimal("1000.00"), "Exact 30-point tailoring measurement protocol and toile fitting assessment."),
        ("Trousseau Wardrobe Curation", Decimal("5000.00"), "Complete aesthetic consultation for all wedding ceremonies including jewelry harmonization.")
    ]
    
    services = []
    for s_idx, store in enumerate(stores):
        for srv_idx, (sname, price, desc) in enumerate(service_defs):
            s = Product.objects.create(
                business_profile=store,
                category=store.category,
                item_type=CatalogItemType.SERVICE,
                name=sname,
                description=desc,
                price=price,
                service_duration_minutes=60,
                image_url=img_urls[(srv_idx + 2) % len(img_urls)],
                is_featured=(srv_idx == 0),
                is_active=True
            )
            services.append(s)
    print(f"[OK] Created 15 Studio Services ({len(services)} total)")

    # 8. Seed Gallery Images (4 per studio = 20 total)
    for s_idx, store in enumerate(stores):
        for g_idx in range(4):
            GalleryImage.objects.create(
                business_profile=store,
                image_url=img_urls[(s_idx + g_idx) % len(img_urls)],
                caption=f"Showroom Ambiance & Master Craftsman Suite #{g_idx+1}",
                display_order=g_idx + 1
            )
    print("[OK] Created 20 Studio Gallery Images")

    # 9. Seed Promotions / Offers (2 per studio = 10 total)
    for s_idx, store in enumerate(stores):
        Offer.objects.create(
            business_profile=store,
            title=f"Monsoon Wedding Festival - 25% Off",
            promo_code=f"MONSOON{s_idx+20}",
            description=f"Exclusive 25% discount on custom bridal trousseau and bespoke designer styling at {store.business_name}.",
            discount_percentage=25,
            valid_until=timezone.now() + datetime.timedelta(days=30),
            is_active=True
        )
        Offer.objects.create(
            business_profile=store,
            title=f"Bespoke Blouse Week Deal",
            promo_code=f"BLOUSE15",
            description=f"Enjoy complimentary tassels and 15% off hand embroidery craftsmanship on any order above INR 15,000.",
            discount_percentage=15,
            valid_until=timezone.now() + datetime.timedelta(days=15),
            is_active=True
        )
    print("[OK] Created 10 Promotional Campaign Offers")

    # 10. Seed Customer Reviews
    for s_idx, store in enumerate(stores):
        for r_idx in range(3):
            customer = customers[(s_idx * 3 + r_idx) % len(customers)]
            Review.objects.create(
                user=customer,
                store=store,
                rating=5 if r_idx != 2 else 4,
                title="Impeccable craftsmanship and luxury service!" if r_idx != 2 else "Beautiful fittings and timely delivery.",
                comment=f"Visited {store.business_name} for my sister's wedding ensemble. The attention to detail, Maggam work precision, and personalized hospitality exceeded every expectation!",
                is_verified_visit=True
            )
    print("[OK] Created 15 Verified Customer Reviews")

    # 11. Seed Bookings (Appointments & Product Enquiries)
    for i in range(15):
        cust = customers[i % len(customers)]
        srv = services[i % len(services)]
        AppointmentBooking.objects.create(
            customer=cust,
            business_profile=srv.business_profile,
            service=srv,
            appointment_date=timezone.now().date() + datetime.timedelta(days=(i % 5) + 1),
            start_time=datetime.time(11 + (i % 6), 0),
            status=BookingStatus.CONFIRMED if i % 2 == 0 else BookingStatus.PENDING,
            customer_notes="Looking forward to bridal lehenga fitting and fabric selection."
        )
        
        prod = products[i % len(products)]
        ProductEnquiry.objects.create(
            customer=cust,
            business_profile=prod.business_profile,
            product=prod,
            status=EnquiryStatus.OPEN if i % 2 == 0 else EnquiryStatus.RESPONDED,
            message="Can this piece be made to order in blush pink silk with emerald zari?",
            target_delivery_date=timezone.now().date() + datetime.timedelta(days=20),
            studio_response="We can certainly customize the silhouette and color tone. Quotation attached." if i % 2 != 0 else None,
            quoted_price=prod.price * Decimal("0.9") if i % 2 != 0 else None
        )
    print("[OK] Created 15 Service Appointment Bookings & 15 Bespoke Product Enquiries")

    # 12. Seed Favorites
    for i in range(20):
        cust = customers[i]
        store_to_fav = stores[i % len(stores)]
        prod_to_fav = products[i % len(products)]
        
        Favorite.objects.create(user=cust, store=store_to_fav)
        Favorite.objects.create(user=cust, product=prod_to_fav)
    print("[OK] Created 40 Customer Favorite Bookmarks (20 stores + 20 products)")

    # 13. Seed Notifications
    for v in vendors:
        Notification.objects.create(
            recipient=v.user,
            title="New Appointment Reservation Received!",
            message="A customer has scheduled a bespoke styling consultation at your studio showroom.",
            notification_type=NotificationType.ONBOARDING,
            is_read=False
        )
    for c in customers[:5]:
        Notification.objects.create(
            recipient=c,
            title="Exclusive Monsoon Bridal Promotion!",
            message="Explore newly unveiled discount campaigns and designer offers near Banjara Hills.",
            notification_type=NotificationType.PROMOTION,
            is_read=False
        )
    print("[OK] Created real-time platform Notifications for Vendors and Customers")

    print("\n=======================================================")
    print("[OK] PHASE 7 DEMO DATA SEEDING SUCCESSFULLY COMPLETED!")
    print(f"Total Users: {User.objects.count()} (1 SuperAdmin, 2 Admins, 5 Vendors, 20 Customers)")
    print(f"Total Studios: {BusinessProfile.objects.count()} | Categories: {Category.objects.count()}")
    print(f"Catalog: {Product.objects.filter(item_type='PRODUCT').count()} Products | {Product.objects.filter(item_type='SERVICE').count()} Services")
    print(f"Offers: {Offer.objects.count()} | Reviews: {Review.objects.count()} | Favorites: {Favorite.objects.count()}")
    print("=======================================================")

if __name__ == "__main__":
    run()
