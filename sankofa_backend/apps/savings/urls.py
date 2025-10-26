from rest_framework.routers import DefaultRouter

from .views import SavingsGoalViewSet

app_name = "savings"

router = DefaultRouter()
router.register(r"goals", SavingsGoalViewSet, basename="goal")

urlpatterns = router.urls
