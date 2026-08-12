from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularRedocView, SpectacularSwaggerView

urlpatterns = [
    # Admin portal access
    path('admin/django/', admin.site.urls),

    # OpenAPI Schema and interactive UI (Swagger & Redoc)
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('swagger/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),

    # Domain application endpoints
    path('api/v1/', include('apps.common.urls')),
    path('api/v1/auth/', include('apps.accounts.urls')),
    path('api/v1/vendor/', include('apps.vendors.urls')),
    path('api/v1/vendor/catalog/', include('apps.catalog.vendor_urls')),
    path('api/v1/business/', include('apps.business.urls')),
    path('api/v1/admin/vendors/', include('apps.vendors.admin_urls')),
    path('api/v1/admin/categories/', include('apps.categories.admin_urls')),
    path('api/v1/admin/', include('apps.catalog.admin_urls')),
    path('api/v1/admin/', include('apps.accounts.admin_urls')),
    path('api/v1/admin/', include('apps.interactions.admin_urls')),
    path('api/v1/admin/', include('apps.notifications.admin_urls')),
    path('api/v1/categories/', include('apps.categories.urls')),
    path('api/v1/stores/', include('apps.business.public_urls')),
    path('api/v1/stores/', include('apps.interactions.review_urls')),
    path('api/v1/stores/', include('apps.operations.store_urls')),
    path('api/v1/products/', include('apps.catalog.public_urls')),
    path('api/v1/promotions/', include('apps.catalog.promotion_urls')),
    path('api/v1/search/', include('apps.interactions.search_urls')),
    path('api/v1/favorites/', include('apps.interactions.urls')),
    path('api/v1/notifications/', include('apps.notifications.urls')),
    path('api/v1/', include('apps.operations.customer_urls')),
    path('api/v1/vendor/', include('apps.operations.vendor_urls')),
    path('api/v1/admin/', include('apps.operations.admin_urls')),
]
