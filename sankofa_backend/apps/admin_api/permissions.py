from rest_framework.permissions import BasePermission


class IsStaffUser(BasePermission):
    """Ensures the request is authenticated with a staff account."""

    def has_permission(self, request, view) -> bool:
        user = getattr(request, "user", None)
        return bool(user and user.is_authenticated and user.is_staff)
