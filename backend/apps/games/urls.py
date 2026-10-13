from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import GameCatalogueView, GameSessionViewSet, SavedProgressViewSet, PlayerStatisticViewSet, GameHistoryViewSet

router = DefaultRouter()
router.register(r'catalogue', GameCatalogueView, basename='game-catalogue')
router.register(r'sessions', GameSessionViewSet, basename='game-sessions')
router.register(r'progress', SavedProgressViewSet, basename='game-progress')
router.register(r'statistics', PlayerStatisticViewSet, basename='game-statistics')
router.register(r'history', GameHistoryViewSet, basename='game-history')

urlpatterns = [
    path('', include(router.urls)),
]
