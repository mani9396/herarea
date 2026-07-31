from django.urls import path
from apps.interactions.views import GlobalO2OSearchView

urlpatterns = [
    path('', GlobalO2OSearchView.as_view(), name='global-o2o-search'),
]
