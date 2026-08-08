from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Notification, ReaderNote, ReaderProfile, ReaderSettings
from .permissions import IsTherapist
from .serializers import (
    MyProfileSerializer,
    NotificationSerializer,
    ReaderCreateSerializer,
    ReaderNoteSerializer,
    ReaderProfileSerializer,
    ReaderSettingsSerializer,
)


class AvailableReadersView(generics.ListAPIView):
    """GET /api/readers/available/?search= — readers nobody has added yet.

    This is the Add Reader list. The `therapist__isnull=True` filter is the
    whole rule: once any therapist claims a reader they drop out of every other
    therapist's list, so two therapists can never be working the same
    participant without knowing it.
    """

    serializer_class = ReaderProfileSerializer
    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    def get_queryset(self):
        qs = ReaderProfile.objects.filter(therapist__isnull=True).select_related("user")
        search = self.request.query_params.get("search", "").strip()
        if search:
            qs = qs.filter(
                Q(display_name__icontains=search)
                | Q(participant_id__icontains=search)
                | Q(school__icontains=search)
                | Q(user__email__icontains=search)
            )
        return qs


class MyReadersView(generics.ListCreateAPIView):
    """GET/POST /api/readers/mine/ — the therapist's own roster."""

    serializer_class = ReaderProfileSerializer
    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    def get_queryset(self):
        return ReaderProfile.objects.filter(therapist=self.request.user).select_related(
            "user"
        )

    def create(self, request, *args, **kwargs):
        serializer = ReaderCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        reader = serializer.save(therapist=request.user, claimed_at=timezone.now())
        return Response(
            ReaderProfileSerializer(reader).data, status=status.HTTP_201_CREATED
        )


class ClaimReaderView(APIView):
    """POST /api/readers/<participant_id>/claim/ — add a reader to my roster."""

    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    @transaction.atomic
    def post(self, request, participant_id):
        try:
            reader = ReaderProfile.objects.get(participant_id=participant_id)
        except ReaderProfile.DoesNotExist:
            return Response(
                {"detail": "Reader not found."}, status=status.HTTP_404_NOT_FOUND
            )

        if reader.therapist_id == request.user.id:
            return Response(
                ReaderProfileSerializer(reader).data, status=status.HTTP_200_OK
            )

        # A conditional UPDATE, not a read-then-save: two therapists tapping the
        # same reader at the same moment must not both succeed. Whoever loses
        # the race updates zero rows and gets a 409 instead of silently
        # overwriting the winner.
        claimed = ReaderProfile.objects.filter(
            pk=reader.pk, therapist__isnull=True
        ).update(therapist=request.user, claimed_at=timezone.now())

        if not claimed:
            return Response(
                {"detail": "This reader has already been added by another therapist."},
                status=status.HTTP_409_CONFLICT,
            )

        reader.refresh_from_db()

        # The reader learns they were added. Only possible if they have an
        # account — a therapist-registered child with no login has nowhere to
        # receive it, and that is fine.
        if reader.user_id:
            therapist_name = request.user.full_name or request.user.email
            Notification.objects.create(
                recipient_id=reader.user_id,
                kind=Notification.Kind.THERAPIST_ADDED,
                title="A therapist added you",
                body=(
                    f"{therapist_name} has added you as their reader. They can now "
                    f"assign you passages and see your reading progress."
                ),
            )

        return Response(ReaderProfileSerializer(reader).data, status=status.HTTP_200_OK)


class ReleaseReaderView(APIView):
    """POST /api/readers/<participant_id>/release/ — undo a claim."""

    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    def post(self, request, participant_id):
        updated = ReaderProfile.objects.filter(
            participant_id=participant_id, therapist=request.user
        ).update(therapist=None, claimed_at=None)
        if not updated:
            return Response(
                {"detail": "Not one of your readers."},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response(status=status.HTTP_204_NO_CONTENT)


class ReaderDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = ReaderProfileSerializer
    permission_classes = [permissions.IsAuthenticated, IsTherapist]
    lookup_field = "participant_id"

    def get_queryset(self):
        return ReaderProfile.objects.filter(therapist=self.request.user)


class ReaderNotesView(generics.ListCreateAPIView):
    serializer_class = ReaderNoteSerializer
    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    def _reader(self):
        return generics.get_object_or_404(
            ReaderProfile,
            participant_id=self.kwargs["participant_id"],
            therapist=self.request.user,
        )

    def get_queryset(self):
        return ReaderNote.objects.filter(reader=self._reader())

    def perform_create(self, serializer):
        serializer.save(reader=self._reader(), author=self.request.user)


class NotificationListView(generics.ListAPIView):
    """GET /api/notifications/ — the signed-in user's own messages."""

    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = Notification.objects.filter(recipient=self.request.user)
        if self.request.query_params.get("unread") == "true":
            qs = qs.filter(read_at__isnull=True)
        return qs


class MarkNotificationReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            note = Notification.objects.get(pk=pk, recipient=request.user)
        except Notification.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
        note.mark_read()
        return Response(NotificationSerializer(note).data)


class MarkAllNotificationsReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        Notification.objects.filter(
            recipient=request.user, read_at__isnull=True
        ).update(read_at=timezone.now())
        return Response(status=status.HTTP_204_NO_CONTENT)


class MyProfileView(generics.RetrieveUpdateAPIView):
    """GET/PATCH /api/me/profile/ — the reader's own Profile screen."""

    serializer_class = MyProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return generics.get_object_or_404(ReaderProfile, user=self.request.user)


class MySettingsView(APIView):
    """GET/PUT /api/me/settings/ — the reading configuration, mirrored.

    The device stays authoritative during a session; this copy exists so a
    participant's configuration survives a reinstall, and so a therapist can
    see the condition a reader actually reads under.
    """

    permission_classes = [permissions.IsAuthenticated]

    def _profile(self):
        return generics.get_object_or_404(ReaderProfile, user=self.request.user)

    def get(self, request):
        settings_row = ReaderSettings.objects.filter(reader=self._profile()).first()
        if settings_row is None:
            return Response({"values": {}, "updated_at": None})
        return Response(ReaderSettingsSerializer(settings_row).data)

    def put(self, request):
        values = request.data.get("values")
        if not isinstance(values, dict):
            return Response(
                {"detail": "Expected an object under 'values'."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        row, _ = ReaderSettings.objects.update_or_create(
            reader=self._profile(), defaults={"values": values}
        )
        return Response(ReaderSettingsSerializer(row).data)


class ReaderSettingsView(APIView):
    """GET /api/readers/<participant_id>/settings/ — therapist view of the
    condition one of their own readers is configured with."""

    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    def get(self, request, participant_id):
        reader = generics.get_object_or_404(
            ReaderProfile, participant_id=participant_id, therapist=request.user
        )
        row = ReaderSettings.objects.filter(reader=reader).first()
        if row is None:
            return Response({"values": {}, "updated_at": None})
        return Response(ReaderSettingsSerializer(row).data)
