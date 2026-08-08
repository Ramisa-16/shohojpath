from django.urls import path

from .views import (
    MySessionsView,
    ProgressView,
    ReaderProgressView,
    ReaderSessionsView,
    ReaderStatisticsView,
    SessionUploadView,
    StatisticsView,
    TherapistOverviewView,
    TherapistReaderSummaryView,
)

app_name = "sync"

urlpatterns = [
    path("sync/sessions/", SessionUploadView.as_view(), name="upload"),
    path("sessions/mine/", MySessionsView.as_view(), name="my-sessions"),
    path("me/progress/", ProgressView.as_view(), name="progress"),
    path("me/statistics/", StatisticsView.as_view(), name="statistics"),
    path(
        "readers/<str:participant_id>/sessions/",
        ReaderSessionsView.as_view(),
        name="reader-sessions",
    ),
    path(
        "readers/<str:participant_id>/progress/",
        ReaderProgressView.as_view(),
        name="reader-progress",
    ),
    path(
        "readers/<str:participant_id>/statistics/",
        ReaderStatisticsView.as_view(),
        name="reader-statistics",
    ),
    path("therapist/overview/", TherapistOverviewView.as_view(), name="overview"),
    path(
        "therapist/readers-summary/",
        TherapistReaderSummaryView.as_view(),
        name="readers-summary",
    ),
]
