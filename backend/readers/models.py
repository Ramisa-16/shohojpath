import secrets

from django.conf import settings
from django.db import models
from django.utils import timezone


def generate_participant_id():
    """A short, human-readable study id: P-4F2A.

    Random rather than sequential: participant ids appear on exported data and
    in the therapist UI, and a sequential counter would leak how many people
    have enrolled, which is not something a participant should learn from their
    own id.
    """
    return f"P-{secrets.token_hex(2).upper()}"


class ReaderProfile(models.Model):
    """The study-participant record behind a reader account.

    Kept separate from [User] because a therapist can register a child who has
    no email address of their own — [user] is nullable for exactly that case,
    and gets filled in later if that child ever signs up.
    """

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="reader_profile",
    )
    participant_id = models.CharField(
        max_length=32,
        unique=True,
        default=generate_participant_id,
        help_text="Matches the participant_id on every synced session row.",
    )
    display_name = models.CharField(max_length=120)
    age = models.PositiveSmallIntegerField(null=True, blank=True)
    class_grade = models.CharField(max_length=40, blank=True)
    school = models.CharField(max_length=160, blank=True)
    starting_profile = models.CharField(
        max_length=16,
        default="recommended",
        help_text="Reading condition this reader starts a session in.",
    )

    # The ownership rule: null means "not yet added by anyone", which is
    # exactly the filter the Add Reader list uses.
    therapist = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="readers",
        limit_choices_to={"role": "therapist"},
    )
    claimed_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("display_name",)
        indexes = [models.Index(fields=["therapist"])]

    def __str__(self):
        return f"{self.display_name} ({self.participant_id})"

    @property
    def is_claimed(self):
        return self.therapist_id is not None


class Notification(models.Model):
    """A message to a reader — currently only "a therapist added you".

    Stored rather than pushed: the app is offline-first, so a reader who was
    added while their device was off must still see it the next time they open
    the app. A push-only notification would simply be lost.
    """

    class Kind(models.TextChoices):
        THERAPIST_ADDED = "therapist_added", "Therapist added you"
        PASSAGE_ASSIGNED = "passage_assigned", "Passage assigned"
        GENERAL = "general", "General"

    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    kind = models.CharField(max_length=32, choices=Kind.choices, default=Kind.GENERAL)
    title = models.CharField(max_length=160)
    body = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ("-created_at",)
        indexes = [models.Index(fields=["recipient", "read_at"])]

    def __str__(self):
        return f"{self.title} -> {self.recipient_id}"

    def mark_read(self):
        if self.read_at is None:
            self.read_at = timezone.now()
            self.save(update_fields=["read_at"])


class ReaderNote(models.Model):
    """A therapist's free-text observation about one reader."""

    reader = models.ForeignKey(
        ReaderProfile, on_delete=models.CASCADE, related_name="notes"
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-created_at",)

    def __str__(self):
        return f"Note on {self.reader_id}"


class ReaderSettings(models.Model):
    """A reader's saved reading configuration, mirrored from the device.

    The device remains the source of truth during a session — this copy exists
    so a participant's configuration survives a reinstall or a change of
    handset, and so a therapist can see the condition a reader actually reads
    under rather than the one they were assigned.
    """

    reader = models.OneToOneField(
        ReaderProfile, on_delete=models.CASCADE, related_name="settings"
    )
    values = models.JSONField(
        default=dict,
        help_text="The ReadingSettings.toMap() payload from the app.",
    )
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "reader settings"

    def __str__(self):
        return f"Settings for {self.reader.participant_id}"
