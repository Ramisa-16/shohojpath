from django.urls import path

from .views import (
    AvailableReadersView,
    MyProfileView,
    MySettingsView,
    ReaderSettingsView,
    MySupervisionRequestsView,
    RequestSupervisionView,
    RespondToSupervisionView,
    MarkAllNotificationsReadView,
    MarkNotificationReadView,
    MyReadersView,
    NotificationListView,
    ReaderDetailView,
    ReaderNotesView,
    ReleaseReaderView,
)

app_name = "readers"

urlpatterns = [
    path("me/profile/", MyProfileView.as_view(), name="my-profile"),
    path("me/settings/", MySettingsView.as_view(), name="my-settings"),
    path("readers/available/", AvailableReadersView.as_view(), name="available"),
    path("readers/mine/", MyReadersView.as_view(), name="mine"),
    path("readers/<str:participant_id>/", ReaderDetailView.as_view(), name="detail"),
    path(
        "readers/<str:participant_id>/request/",
        RequestSupervisionView.as_view(),
        name="request-supervision",
    ),
    path(
        "me/supervision-requests/",
        MySupervisionRequestsView.as_view(),
        name="my-supervision-requests",
    ),
    path(
        "supervision-requests/<int:pk>/respond/",
        RespondToSupervisionView.as_view(),
        name="respond-supervision",
    ),
    path(
        "readers/<str:participant_id>/release/",
        ReleaseReaderView.as_view(),
        name="release",
    ),
    path(
        "readers/<str:participant_id>/settings/",
        ReaderSettingsView.as_view(),
        name="reader-settings",
    ),
    path(
        "readers/<str:participant_id>/notes/",
        ReaderNotesView.as_view(),
        name="notes",
    ),
    path("notifications/", NotificationListView.as_view(), name="notifications"),
    path(
        "notifications/read-all/",
        MarkAllNotificationsReadView.as_view(),
        name="notifications-read-all",
    ),
    path(
        "notifications/<int:pk>/read/",
        MarkNotificationReadView.as_view(),
        name="notification-read",
    ),
]
