from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import DisputeViewSet, SupportArticleViewSet

router = DefaultRouter()
router.register(r"disputes", DisputeViewSet, basename="disputes")
router.register(r"articles", SupportArticleViewSet, basename="support-articles")

urlpatterns = [
    path("", include(router.urls)),
]
