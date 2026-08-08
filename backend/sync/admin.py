from django.contrib import admin

from .models import (
    PageTime,
    QuizAnswer,
    SettingsChange,
    StudySession,
    SusResponse,
    TlxResponse,
)


class SettingsChangeInline(admin.TabularInline):
    model = SettingsChange
    extra = 0
    readonly_fields = ("at", "key", "old_value", "new_value", "profile")
    can_delete = False


class PageTimeInline(admin.TabularInline):
    model = PageTime
    extra = 0
    readonly_fields = ("page_index", "seconds")
    can_delete = False


class QuizAnswerInline(admin.TabularInline):
    model = QuizAnswer
    extra = 0
    readonly_fields = ("question_index", "selected_index", "correct", "time_seconds")
    can_delete = False


class SusResponseInline(admin.TabularInline):
    model = SusResponse
    extra = 0
    readonly_fields = ("item_index", "response")
    can_delete = False


class TlxResponseInline(admin.TabularInline):
    model = TlxResponse
    extra = 0
    readonly_fields = ("subscale", "value")
    can_delete = False


@admin.register(StudySession)
class StudySessionAdmin(admin.ModelAdmin):
    """Read-mostly on purpose: this is collected research data, and an
    accidental edit in the admin would be indistinguishable from a real
    measurement afterwards."""

    list_display = (
        "session_id",
        "participant_id",
        "passage_id",
        "profile",
        "started_at",
        "total_reading_seconds",
        "read_aloud_on",
        "quiz_score",
        "sus_score",
    )
    list_filter = ("profile", "read_aloud_on", "started_at")
    search_fields = ("session_id", "participant_id", "passage_id")
    date_hierarchy = "started_at"
    readonly_fields = ("session_id", "synced_at")
    inlines = [
        PageTimeInline,
        QuizAnswerInline,
        SettingsChangeInline,
        SusResponseInline,
        TlxResponseInline,
    ]
