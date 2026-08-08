from rest_framework import permissions


class IsTherapist(permissions.BasePermission):
    """Only therapists may see the reader directory or claim anyone.

    Enforced server-side, not merely hidden in the app: a reader holding a
    valid token could otherwise call the endpoint directly and read the names
    and schools of every other child in the study.
    """

    message = "Only a therapist account can do this."

    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.is_therapist)


class IsReader(permissions.BasePermission):
    message = "Only a reader account can do this."

    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.is_reader)
