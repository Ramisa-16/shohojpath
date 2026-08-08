from django.urls import path

from .views import (
    BookmarkDetailView,
    BookmarkListView,
    CategoryListView,
    MyAssignmentsView,
    PassageDetailView,
    PassageListView,
    ReaderAssignmentDeleteView,
    ReaderAssignmentsView,
)

app_name = "passages"

urlpatterns = [
    path("passages/", PassageListView.as_view(), name="list"),
    path("passages/categories/", CategoryListView.as_view(), name="categories"),
    path("passages/<slug:slug>/", PassageDetailView.as_view(), name="detail"),
    path("bookmarks/", BookmarkListView.as_view(), name="bookmarks"),
    path("bookmarks/<int:pk>/", BookmarkDetailView.as_view(), name="bookmark-detail"),
    path("assignments/mine/", MyAssignmentsView.as_view(), name="my-assignments"),
    path(
        "readers/<str:participant_id>/assignments/",
        ReaderAssignmentsView.as_view(),
        name="reader-assignments",
    ),
    path(
        "readers/<str:participant_id>/assignments/<slug:passage_slug>/",
        ReaderAssignmentDeleteView.as_view(),
        name="reader-assignment-delete",
    ),
]
