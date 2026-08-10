from django.db import transaction
from rest_framework import serializers

from readers.models import ReaderProfile

from .models import (
    PageTime,
    QuizAnswer,
    SettingsChange,
    StudySession,
    SusResponse,
    TlxResponse,
)


class SettingsChangeSerializer(serializers.ModelSerializer):
    class Meta:
        model = SettingsChange
        fields = ("at", "key", "old_value", "new_value", "profile")


class PageTimeSerializer(serializers.ModelSerializer):
    class Meta:
        model = PageTime
        fields = ("page_index", "seconds")


class QuizAnswerSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizAnswer
        fields = ("question_index", "selected_index", "correct", "time_seconds")


class SusResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = SusResponse
        fields = ("item_index", "response")


class TlxResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = TlxResponse
        fields = ("subscale", "value")


class StudySessionSerializer(serializers.ModelSerializer):
    # Declared explicitly to drop the UniqueValidator ModelSerializer would
    # infer from `unique=True`. Re-uploading a session is the normal case here,
    # not a conflict — the validator would reject every retry with a 400 and
    # the device would keep the session queued forever.
    session_id = serializers.CharField(max_length=64)

    settings_changes = SettingsChangeSerializer(many=True, required=False)
    page_times = PageTimeSerializer(many=True, required=False)
    quiz_answers = QuizAnswerSerializer(many=True, required=False)
    sus_responses = SusResponseSerializer(many=True, required=False)
    tlx_responses = TlxResponseSerializer(many=True, required=False)

    words_per_minute = serializers.FloatField(read_only=True)
    comprehension_percent = serializers.FloatField(read_only=True)

    # Sessions reference a passage by slug rather than a foreign key, so that
    # a recorded session outlives the study material it names. The slug is not
    # something to show anyone though — the History screen was listing
    # "aesop_21104" where the story's name belongs.
    passage_title = serializers.SerializerMethodField()

    class Meta:
        model = StudySession
        fields = (
            "session_id",
            "participant_id",
            "passage_id",
            "passage_title",
            "started_at",
            "ended_at",
            "profile",
            "total_reading_seconds",
            "words_read",
            "read_aloud_on",
            "audio_duration_seconds",
            "quiz_score",
            "quiz_total",
            "ease_stars",
            "audio_help_stars",
            "helpful_settings",
            "suggestion",
            "sus_score",
            "words_per_minute",
            "comprehension_percent",
            "settings_changes",
            "page_times",
            "quiz_answers",
            "sus_responses",
            "tlx_responses",
        )

    def get_passage_title(self, obj):
        # One query per request for all 30 titles, rather than one per row:
        # a therapist opening a reader with fifty sessions would otherwise
        # make fifty lookups to render one list.
        if not hasattr(self, "_titles"):
            from passages.models import Passage

            self._titles = dict(Passage.objects.values_list("slug", "title"))
        # Falls back to the slug for a passage that has since been deleted —
        # ugly, but truthful, and better than an empty row.
        return self._titles.get(obj.passage_id) or obj.passage_id

    CHILD_FIELDS = {
        "settings_changes": SettingsChange,
        "page_times": PageTime,
        "quiz_answers": QuizAnswer,
        "sus_responses": SusResponse,
        "tlx_responses": TlxResponse,
    }

    @transaction.atomic
    def create(self, validated):
        """Upsert on session_id.

        Sync has to be safe to repeat: a device that uploads, loses the
        response and retries must not create a duplicate session or double the
        page times. Children are replaced wholesale rather than appended for
        the same reason.
        """
        children = {
            name: validated.pop(name, []) for name in self.CHILD_FIELDS
        }
        session_id = validated.pop("session_id")

        reader = ReaderProfile.objects.filter(
            participant_id=validated.get("participant_id", "")
        ).first()

        session, _ = StudySession.objects.update_or_create(
            session_id=session_id,
            defaults={**validated, "reader": reader},
        )

        for name, model in self.CHILD_FIELDS.items():
            rows = children.get(name) or []
            model.objects.filter(session=session).delete()
            model.objects.bulk_create(
                [model(session=session, **row) for row in rows]
            )

        return session


class SessionUploadSerializer(serializers.Serializer):
    """The batch envelope the app posts when it comes back online."""

    sessions = StudySessionSerializer(many=True)

    @transaction.atomic
    def save(self, **kwargs):
        child = StudySessionSerializer()
        return [child.create(dict(row)) for row in self.validated_data["sessions"]]
