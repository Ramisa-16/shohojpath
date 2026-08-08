from django.db import models


class StudySession(models.Model):
    """One reading session, mirroring the sqflite `sessions` table.

    The device is the source of truth: a session is written to sqflite as it
    happens and uploaded later, so the study runs unaffected by whether the
    server is awake. `session_id` is the device-generated id, and it is unique
    here too — that is what makes re-uploading the same session harmless.
    """

    session_id = models.CharField(max_length=64, unique=True, db_index=True)
    reader = models.ForeignKey(
        "readers.ReaderProfile",
        on_delete=models.CASCADE,
        related_name="sessions",
        null=True,
        blank=True,
    )
    participant_id = models.CharField(max_length=32, db_index=True)
    passage_id = models.CharField(max_length=64, db_index=True)

    started_at = models.DateTimeField()
    ended_at = models.DateTimeField(null=True, blank=True)
    profile = models.CharField(max_length=16, blank=True)

    total_reading_seconds = models.FloatField(null=True, blank=True)
    words_read = models.PositiveIntegerField(null=True, blank=True)
    read_aloud_on = models.BooleanField(default=False)
    audio_duration_seconds = models.FloatField(null=True, blank=True)

    quiz_score = models.PositiveSmallIntegerField(null=True, blank=True)
    quiz_total = models.PositiveSmallIntegerField(null=True, blank=True)
    ease_stars = models.PositiveSmallIntegerField(null=True, blank=True)
    audio_help_stars = models.PositiveSmallIntegerField(null=True, blank=True)
    helpful_settings = models.TextField(blank=True)
    suggestion = models.TextField(blank=True)
    sus_score = models.FloatField(null=True, blank=True)

    synced_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-started_at",)
        indexes = [models.Index(fields=["participant_id", "-started_at"])]

    def __str__(self):
        return f"{self.participant_id} · {self.passage_id} · {self.started_at:%Y-%m-%d}"

    @property
    def words_per_minute(self):
        if not self.words_read or not self.total_reading_seconds:
            return None
        minutes = self.total_reading_seconds / 60
        return round(self.words_read / minutes, 1) if minutes else None

    @property
    def comprehension_percent(self):
        if not self.quiz_total:
            return None
        return round(100 * (self.quiz_score or 0) / self.quiz_total, 1)


class SettingsChange(models.Model):
    """Every settings mutation, timestamped — the independent-variable trail."""

    session = models.ForeignKey(
        StudySession, on_delete=models.CASCADE, related_name="settings_changes"
    )
    at = models.DateTimeField()
    key = models.CharField(max_length=64)
    old_value = models.CharField(max_length=120, blank=True)
    new_value = models.CharField(max_length=120, blank=True)
    profile = models.CharField(max_length=16)

    class Meta:
        ordering = ("at",)

    def __str__(self):
        return f"{self.key}: {self.old_value} -> {self.new_value}"


class PageTime(models.Model):
    session = models.ForeignKey(
        StudySession, on_delete=models.CASCADE, related_name="page_times"
    )
    page_index = models.PositiveSmallIntegerField()
    seconds = models.FloatField()

    class Meta:
        ordering = ("page_index",)
        unique_together = ("session", "page_index")


class QuizAnswer(models.Model):
    session = models.ForeignKey(
        StudySession, on_delete=models.CASCADE, related_name="quiz_answers"
    )
    question_index = models.PositiveSmallIntegerField()
    selected_index = models.SmallIntegerField()
    correct = models.BooleanField()
    time_seconds = models.FloatField()

    class Meta:
        ordering = ("question_index",)
        unique_together = ("session", "question_index")


class SusResponse(models.Model):
    session = models.ForeignKey(
        StudySession, on_delete=models.CASCADE, related_name="sus_responses"
    )
    item_index = models.PositiveSmallIntegerField()
    response = models.PositiveSmallIntegerField()

    class Meta:
        ordering = ("item_index",)
        unique_together = ("session", "item_index")


class TlxResponse(models.Model):
    session = models.ForeignKey(
        StudySession, on_delete=models.CASCADE, related_name="tlx_responses"
    )
    subscale = models.CharField(max_length=32)
    value = models.PositiveSmallIntegerField()

    class Meta:
        ordering = ("subscale",)
        unique_together = ("session", "subscale")
