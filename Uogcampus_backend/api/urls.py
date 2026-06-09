from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ItemViewSet, NotificationViewSet, firebase_sync

router = DefaultRouter()
router.register(r'items', ItemViewSet, basename='item')
router.register(r'notifications', NotificationViewSet, basename='notification')

urlpatterns = [
    # This handles /api/items/ and /api/notifications/
    path('', include(router.urls)),

    # ✅ FIX: This makes the URL exactly /api/auth-sync/
    path('auth-sync/', firebase_sync, name='auth_sync'),
]