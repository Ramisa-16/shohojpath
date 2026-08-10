from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import (
    Notification,
    ReaderNote,
    ReaderProfile,
    ReaderSettings,
    SupervisionRequest,
)
from .permissions import IsTherapist
from .serializers import (
    MyProfileSerializer,
    NotificationSerializer,
    ReaderCreateSerializer,
    ReaderNoteSerializer,
    ReaderProfileSerializer,
    ReaderSettingsSerializer,
    SupervisionRequestSerializer,
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


def _therapist_name(user):
    return user.full_name or user.email


class RequestSupervisionView(APIView):
    """POST /api/readers/<participant_id>/request/ — ask to supervise a reader.

    Replaces the old claim endpoint, which added the reader immediately. A
    therapist who can see every session, quiz score and setting a child
    touches should have been told yes first.
    """

    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    @transaction.atomic
    def post(self, request, participant_id):
        try:
            reader = ReaderProfile.objects.select_for_update().get(
                participant_id=participant_id
            )
        except ReaderProfile.DoesNotExist:
            return Response(
                {"detail": "Reader not found."}, status=status.HTTP_404_NOT_FOUND
            )

        if reader.therapist_id == request.user.id:
            return Response(
                {"detail": "This reader is already yours."},
                status=status.HTTP_409_CONFLICT,
            )

        if reader.therapist_id is not None:
            return Response(
                {"detail": "This reader is already working with a therapist."},
                status=status.HTTP_409_CONFLICT,
            )

        # A reader with no account has nowhere to answer, so there is nobody to
        # ask. Refusing is better than silently adding them, which would be the
        # old behaviour wearing a new name.
        if reader.user_id is None:
            return Response(
                {
                    "detail": (
                        "This reader has no account yet, so they cannot be asked. "
                        "They need to sign up before a therapist can add them."
                    )
                },
                status=status.HTTP_409_CONFLICT,
            )

        existing = SupervisionRequest.objects.filter(
            reader=reader, therapist=request.user, status=SupervisionRequest.Status.PENDING
        ).first()
        if existing:
            return Response(
                SupervisionRequestSerializer(existing).data, status=status.HTTP_200_OK
            )

        supervision = SupervisionRequest.objects.create(
            reader=reader, therapist=request.user
        )

        Notification.objects.create(
            recipient_id=reader.user_id,
            kind=Notification.Kind.SUPERVISION_REQUESTED,
            title="A therapist wants to add you",
            body=(
                f"{_therapist_name(request.user)} would like to add you as their "
                f"reader. They would be able to assign you passages and see your "
                f"reading progress. You can accept or decline."
            ),
            supervision_request=supervision,
        )

        return Response(
            SupervisionRequestSerializer(supervision).data,
            status=status.HTTP_201_CREATED,
        )


class MySupervisionRequestsView(generics.ListAPIView):
    """GET /api/me/supervision-requests/ — requests waiting on me."""

    serializer_class = SupervisionRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return SupervisionRequest.objects.filter(
            reader__user=self.request.user,
            status=SupervisionRequest.Status.PENDING,
        ).select_related("therapist", "reader")


class RespondToSupervisionView(APIView):
    """POST /api/supervision-requests/<pk>/respond/ — {"accept": true|false}."""

    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk):
        try:
            supervision = SupervisionRequest.objects.select_for_update().get(
                pk=pk, reader__user=request.user
            )
        except SupervisionRequest.DoesNotExist:
            return Response(
                {"detail": "Request not found."}, status=status.HTTP_404_NOT_FOUND
            )

        if not supervision.is_pending:
            return Response(
                {"detail": "This request has already been answered."},
                status=status.HTTP_409_CONFLICT,
            )

        accept = bool(request.data.get("accept"))
        reader = supervision.reader
        therapist = supervision.therapist
        now = timezone.now()

        if not accept:
            supervision.status = SupervisionRequest.Status.DECLINED
            supervision.responded_at = now
            supervision.save(update_fields=["status", "responded_at"])

            Notification.objects.create(
                recipient=therapist,
                kind=Notification.Kind.SUPERVISION_DECLINED,
                title="Request declined",
                body=(
                    f"{reader.display_name or reader.participant_id} declined your "
                    f"request to add them as a reader."
                ),
            )
            return Response(
                SupervisionRequestSerializer(supervision).data,
                status=status.HTTP_200_OK,
            )

        # Same conditional UPDATE as before: the reader may have accepted
        # someone else a moment ago, and two therapists must not both end up
        # supervising them.
        claimed = ReaderProfile.objects.filter(
            pk=reader.pk, therapist__isnull=True
        ).update(therapist=therapist, claimed_at=now)

        if not claimed:
            supervision.status = SupervisionRequest.Status.SUPERSEDED
            supervision.responded_at = now
            supervision.save(update_fields=["status", "responded_at"])
            return Response(
                {"detail": "You are already working with a therapist."},
                status=status.HTTP_409_CONFLICT,
            )

        supervision.status = SupervisionRequest.Status.ACCEPTED
        supervision.responded_at = now
        supervision.save(update_fields=["status", "responded_at"])

        Notification.objects.create(
            recipient=therapist,
            kind=Notification.Kind.SUPERVISION_ACCEPTED,
            title="Request accepted",
            body=(
                f"{reader.display_name or reader.participant_id} accepted your "
                f"request. They are now on your reader list."
            ),
        )

        # Anyone else still waiting is now asking for something that cannot
        # happen. Closing those out and saying so beats leaving a therapist
        # watching a request that will never be answered.
        others = SupervisionRequest.objects.filter(
            reader=reader, status=SupervisionRequest.Status.PENDING
        ).exclude(pk=supervision.pk).select_related("therapist")

        for other in others:
            Notification.objects.create(
                recipient=other.therapist,
                kind=Notification.Kind.SUPERVISION_DECLINED,
                title="Request closed",
                body=(
                    f"{reader.display_name or reader.participant_id} is now working "
                    f"with another therapist."
                ),
            )
        others.update(status=SupervisionRequest.Status.SUPERSEDED, responded_at=now)

        return Response(
            SupervisionRequestSerializer(supervision).data, status=status.HTTP_200_OK
        )
