from datetime import timedelta

from django.db.models import Q, Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from readers.models import ReaderProfile
from readers.permissions import IsTherapist

from .models import StudySession
from .serializers import SessionUploadSerializer, StudySessionSerializer
from .stats import build_progress, build_statistics


def _own_reader(user):
    """The signed-in reader's own profile."""
    return get_object_or_404(ReaderProfile, user=user)


def _reader_on_my_roster(therapist, participant_id):
    """One of this therapist's readers, or 404.

    Scoped to the roster rather than looked up globally: a therapist must not be
    able to read the progress of a child they have not been assigned, simply by
    typing a participant id they guessed.
    """
    return get_object_or_404(
        ReaderProfile, participant_id=participant_id, therapist=therapist
    )


class SessionUploadView(APIView):
    """POST /api/sync/sessions/ — batch upload from the device.

    Idempotent by session_id, so the app can retry freely: a dropped response
    after a successful write is the normal case on a mobile connection, and
    retrying must not duplicate a participant's session.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = SessionUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        sessions = serializer.save()
        return Response(
            {
                "synced": len(sessions),
                "session_ids": [s.session_id for s in sessions],
                "server_time": timezone.now().isoformat(),
            },
            status=status.HTTP_200_OK,
        )


class MySessionsView(generics.ListAPIView):
    """GET /api/sessions/mine/ — the reader's own History screen."""

    serializer_class = StudySessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        reader = _own_reader(self.request.user)
        return StudySession.objects.filter(
            participant_id=reader.participant_id
        ).prefetch_related("page_times", "quiz_answers")


class ReaderSessionsView(generics.ListAPIView):
    """GET /api/readers/<participant_id>/sessions/ — therapist view."""

    serializer_class = StudySessionSerializer
    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    def get_queryset(self):
        reader = _reader_on_my_roster(
            self.request.user, self.kwargs["participant_id"]
        )
        return StudySession.objects.filter(
            participant_id=reader.participant_id
        ).prefetch_related("page_times", "quiz_answers")


class ProgressView(APIView):
    """GET /api/me/progress/ — the reader's own Progress screen."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(build_progress(_own_reader(request.user).participant_id))


class StatisticsView(APIView):
    """GET /api/me/statistics/ — the reader's own Statistics screen."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(build_statistics(_own_reader(request.user).participant_id))


class ReaderProgressView(APIView):
    """GET /api/readers/<participant_id>/progress/ — the same figures the
    reader sees, for their therapist."""

    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    def get(self, request, participant_id):
        reader = _reader_on_my_roster(request.user, participant_id)
        payload = build_progress(reader.participant_id)
        payload["display_name"] = reader.display_name
        return Response(payload)


class ReaderStatisticsView(APIView):
    """GET /api/readers/<participant_id>/statistics/ — therapist view."""

    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    def get(self, request, participant_id):
        reader = _reader_on_my_roster(request.user, participant_id)
        payload = build_statistics(reader.participant_id)
        payload["display_name"] = reader.display_name
        return Response(payload)


class TherapistOverviewView(APIView):
    """GET /api/therapist/overview/ — dashboard tiles, real counts."""

    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    def get(self, request):
        readers = ReaderProfile.objects.filter(therapist=request.user)
        participant_ids = list(readers.values_list("participant_id", flat=True))
        sessions = StudySession.objects.filter(participant_id__in=participant_ids)

        week_start = timezone.localdate() - timedelta(days=6)
        this_week = sessions.filter(started_at__date__gte=week_start)

        return Response(
            {
                "reader_count": readers.count(),
                "session_count": sessions.count(),
                "sessions_this_week": this_week.count(),
                "minutes_this_week": round(
                    (this_week.aggregate(s=Sum("total_reading_seconds"))["s"] or 0) / 60,
                    1,
                ),
                "readers_never_read": readers.filter(
                    ~Q(participant_id__in=sessions.values("participant_id"))
                ).count(),
            }
        )


class TherapistReaderSummaryView(APIView):
    """GET /api/therapist/readers-summary/ — one row per reader for the
    dashboard list, so it does not need N requests to render N readers."""

    permission_classes = [permissions.IsAuthenticated, IsTherapist]

    def get(self, request):
        readers = ReaderProfile.objects.filter(therapist=request.user)
        week_start = timezone.localdate() - timedelta(days=6)

        rows = []
        for reader in readers:
            sessions = StudySession.objects.filter(
                participant_id=reader.participant_id
            )
            latest = sessions.order_by("-started_at").first()
            rows.append(
                {
                    "participant_id": reader.participant_id,
                    "display_name": reader.display_name,
                    "age": reader.age,
                    "sessions_total": sessions.count(),
                    "sessions_this_week": sessions.filter(
                        started_at__date__gte=week_start
                    ).count(),
                    "minutes_total": round(
                        (sessions.aggregate(s=Sum("total_reading_seconds"))["s"] or 0)
                        / 60,
                        1,
                    ),
                    "last_read_at": latest.started_at.isoformat() if latest else None,
                    "last_profile": latest.profile if latest else None,
                }
            )
        return Response({"readers": rows})
