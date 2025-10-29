from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AdminAuthView,
    AuditLogViewSet,
    CashflowQueuesView,
    DashboardMetricsView,
    DisputeViewSet,
    GroupViewSet,
    SavingsGoalViewSet,
    SupportArticleViewSet,
    TransactionViewSet,
    UserViewSet,
)

router = DefaultRouter()
router.register(r"users", UserViewSet, basename="admin-users")
router.register(r"groups", GroupViewSet, basename="admin-groups")
router.register(r"disputes", DisputeViewSet, basename="admin-disputes")
router.register(r"savings-goals", SavingsGoalViewSet, basename="admin-savings-goals")
router.register(r"transactions", TransactionViewSet, basename="admin-transactions")
router.register(r"audit-logs", AuditLogViewSet, basename="admin-audit-logs")
router.register(r"support-articles", SupportArticleViewSet, basename="admin-support-articles")

urlpatterns = [
    path("auth/token/", AdminAuthView.as_view(), name="admin-auth-token"),
    path("dashboard/", DashboardMetricsView.as_view(), name="admin-dashboard"),
    path("cashflow/queues/", CashflowQueuesView.as_view(), name="admin-cashflow-queues"),
    path("", include(router.urls)),
]
