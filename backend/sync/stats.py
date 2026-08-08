"""Derived reading metrics.

Kept out of the views because the same numbers are shown twice: a reader sees
their own progress, and their therapist sees the same reader's progress. If the
two were computed separately they would drift, and a therapist and a
participant would be reading different figures for the same sessions.

Everything here is derived from synced rows rather than stored counters, so any
number on screen can be traced back to the exported data.
"""

from datetime import timedelta

from django.db.models import Avg, Count, Sum
from django.db.models.functions import TruncDate
from django.utils import timezone

from passages.models import Passage

from .models import SettingsChange, StudySession


def sessions_for(participant_id):
    return StudySession.objects.filter(participant_id=participant_id)


def build_progress(participant_id):
    """The Progress screen: today's reading, the week, and where they are."""
    sessions = sessions_for(participant_id)

    today = timezone.localdate()
    today_sessions = sessions.filter(started_at__date=today)

    seconds_today = today_sessions.aggregate(total=Sum("total_reading_seconds"))[
        "total"
    ] or 0
    pages_today = today_sessions.aggregate(pages=Count("page_times"))["pages"] or 0

    # Seven days ending today, zero-filled: the chart needs a bar for every
    # weekday, including the ones with no reading.
    start = today - timedelta(days=6)
    per_day = {
        row["day"]: row["seconds"] or 0
        for row in sessions.filter(started_at__date__gte=start)
        .annotate(day=TruncDate("started_at"))
        .values("day")
        .annotate(seconds=Sum("total_reading_seconds"))
    }
    week = [
        {
            "date": (start + timedelta(days=offset)).isoformat(),
            "minutes": round(per_day.get(start + timedelta(days=offset), 0) / 60, 1),
        }
        for offset in range(7)
    ]

    latest = sessions.order_by("-started_at").first()
    current = None
    if latest:
        passage = Passage.objects.filter(slug=latest.passage_id).first()
        pages_done = latest.page_times.count()
        total_pages = passage.page_count if passage else 0
        current = {
            "passage_id": latest.passage_id,
            "title": passage.title if passage else latest.passage_id,
            "pages_read": pages_done,
            "page_count": total_pages,
            "percent": round(100 * pages_done / total_pages, 1) if total_pages else 0,
            "last_read_at": latest.started_at.isoformat(),
        }

    return {
        "participant_id": participant_id,
        "minutes_today": round(seconds_today / 60, 1),
        "pages_today": pages_today,
        "sessions_total": sessions.count(),
        "current_passage": current,
        "week": week,
    }


def build_statistics(participant_id):
    """The Statistics screen: speed, comprehension, and what they reach for."""
    sessions = sessions_for(participant_id)
    finished = sessions.filter(total_reading_seconds__isnull=False)

    week_start = timezone.localdate() - timedelta(days=6)
    this_week = finished.filter(started_at__date__gte=week_start)
    last_week = finished.filter(
        started_at__date__gte=week_start - timedelta(days=7),
        started_at__date__lt=week_start,
    )

    words_this_week = this_week.aggregate(n=Sum("words_read"))["n"] or 0
    words_last_week = last_week.aggregate(n=Sum("words_read"))["n"] or 0

    totals = finished.aggregate(
        words=Sum("words_read"),
        seconds=Sum("total_reading_seconds"),
        avg_seconds=Avg("total_reading_seconds"),
    )
    wpm = None
    if totals["words"] and totals["seconds"]:
        wpm = round(totals["words"] / (totals["seconds"] / 60), 1)

    quiz_totals = sessions.filter(quiz_total__gt=0).aggregate(
        score=Sum("quiz_score"), total=Sum("quiz_total")
    )
    comprehension = None
    if quiz_totals["total"]:
        comprehension = round(100 * (quiz_totals["score"] or 0) / quiz_totals["total"], 1)

    total_sessions = sessions.count()
    read_aloud_sessions = sessions.filter(read_aloud_on=True).count()

    # Which controls this reader actually reaches for, straight from the
    # settings-change log rather than a guess.
    most_changed = list(
        SettingsChange.objects.filter(session__participant_id=participant_id)
        .values("key")
        .annotate(changes=Count("id"))
        .order_by("-changes")[:5]
    )

    return {
        "participant_id": participant_id,
        "words_this_week": words_this_week,
        "words_delta_vs_last_week": words_this_week - words_last_week,
        "words_per_minute": wpm,
        "comprehension_percent": comprehension,
        "sessions_logged": total_sessions,
        "passages_finished": finished.values("passage_id").distinct().count(),
        "average_session_seconds": round(totals["avg_seconds"] or 0, 1),
        "read_aloud_percent": (
            round(100 * read_aloud_sessions / total_sessions, 1)
            if total_sessions
            else 0
        ),
        "most_changed_settings": most_changed,
    }
