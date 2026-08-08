from django.db.models import Q, Prefetch
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from readers.models import Notification, ReaderProfile
from readers.permissions import IsTherapist

from .models import Assignment, Bookmark, Passage, PassagePage
from .serializers import (
    AssignmentSerializer,
    BookmarkSerializer,
    PassageSerializer,
    PassageSummarySerializer,
)


def reader_profile_for(user):
    """The signed-in reader's profile, or 404.

    Therapists have no profile of their own, so any reader-scoped endpoint
    reached with a therapist token is a bug in the caller, not an empty list.
    """
    return get_object_or_404(ReaderProfile, user=user)


class PassageListView(generics.ListAPIView):
    """GET /api/passages/ — the Library.

    Open to any signed-in user: the passages are study material, not personal
    data, and the therapist screens need the same list to assign from.
    """

    serializer_class = PassageSummarySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = Passage.objects.filter(is_published=True).prefetch_related("pages")
        params = self.request.query_params

        search = params.get("search", "").strip()
        if search:
            qs = qs.filter(Q(title__icontains=search) | Q(category__icontains=search))

        category = params.get("category", "").strip()
        if category and category.lower() != "all":
            qs = qs.filter(category__iexact=category)

        difficulty = params.get("difficulty", "").strip()
        if difficulty:
            qs = qs.filter(difficulty__iexact=difficulty)

        return qs


class PassageDetailView(generics.RetrieveAPIView):
    """GET /api/passages/<slug>/ — full text, for caching on the device."""

    serializer_class = PassageSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = "slug"

    def get_queryset(self):
        return Passage.objects.filter(is_published=True).prefetch_related(
            Prefetch("pages", queryset=PassagePage.objects.order_by("order"))
        )


class CategoryListView(APIView):
    """GET /api/passages/categories/ — the Library filter chips, built from
    what actually exists rather than a hard-coded list that drifts."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        categories = (
            Passage.objects.filter(is_published=True)
            .order_by("category")
            .values_list("category", flat=True)
            .distinct()
        )
        return Response({"categories": ["All", *categories]})


class BookmarkListView(generics.ListCreateAPIView):
    serializer_class = BookmarkSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Bookmark.objects.filter(
            reader=reader_profile_for(self.request.user)
        ).select_related("passage")

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        reader = reader_profile_for(request.user)

        # Re-bookmarking the same page updates the excerpt instead of failing
        # on the unique constraint — the reader's intent is "save here", and a
        # 400 would be a confusing answer to it.
        bookmark, created = Bookmark.objects.update_or_create(
            reader=reader,
            passage=serializer.validated_data["passage"],
            page_index=serializer.validated_data.get("page_index", 0),
            defaults={"excerpt": serializer.validated_data.get("excerpt", "")},
        )
        return Response(
            BookmarkSerializer(bookmark).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class BookmarkDetailView(generics.DestroyAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Bookmark.objects.filter(reader=reader_profile_for(self.request.user))


class MyAssignmentsView(generics.ListAPIView):
    """GET /api/assignments/mine/ — what my therapist has set for me."""

    serializer_class = AssignmentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Assignment.objects.filter(
            reader=reader_profile_for(self.request.user)
        ).select_related("passage")


class ReaderAssignmentsView(generics.ListCreateAPIView):
    """GET/POST /api/readers/<participant_id>/assignments/ — therapist side."""

    serializer_class = AssignmentSerializer
    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    def _reader(self):
        return get_object_or_404(
            ReaderProfile,
            participant_id=self.kwargs["participant_id"],
            therapist=self.request.user,
        )

    def get_queryset(self):
        return Assignment.objects.filter(reader=self._reader()).select_related("passage")

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        reader = self._reader()

        assignment, created = Assignment.objects.update_or_create(
            reader=reader,
            passage=serializer.validated_data["passage"],
            defaults={
                "assigned_by": request.user,
                "profile": serializer.validated_data.get("profile", ""),
            },
        )

        if created and reader.user_id:
            Notification.objects.create(
                recipient_id=reader.user_id,
                kind=Notification.Kind.PASSAGE_ASSIGNED,
                title="New passage assigned",
                body=f"Your therapist assigned “{assignment.passage.title}” to read.",
            )

        return Response(
            AssignmentSerializer(assignment).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class ReaderAssignmentDeleteView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    def delete(self, request, participant_id, passage_slug):
        deleted, _ = Assignment.objects.filter(
            reader__participant_id=participant_id,
            reader__therapist=request.user,
            passage__slug=passage_slug,
        ).delete()
        if not deleted:
            return Response(status=status.HTTP_404_NOT_FOUND)
        return Response(status=status.HTTP_204_NO_CONTENT)
