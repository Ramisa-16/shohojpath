import re

from django.conf import settings
from django.db import models

PARAGRAPH_SPLIT = re.compile(r"\n\s*\n")


class Passage(models.Model):
    """A reading text plus the metadata the study needs about it.

    Lives in the database rather than in the app so study material can be
    changed without shipping a new APK — the researcher adds or edits passages
    in the Django admin and the app picks them up on its next sync.
    """

    class Difficulty(models.TextChoices):
        EASY = "easy", "Easy"
        MEDIUM = "medium", "Medium"
        HARD = "hard", "Hard"

    slug = models.SlugField(
        max_length=64,
        unique=True,
        help_text="Stable id used by the app and by every exported data row.",
    )
    title = models.CharField(max_length=200)
    category = models.CharField(max_length=80, default="Children Stories")
    difficulty = models.CharField(
        max_length=10, choices=Difficulty.choices, default=Difficulty.EASY
    )
    estimated_minutes = models.PositiveSmallIntegerField(default=3)
    is_published = models.BooleanField(
        default=True,
        help_text="Unpublished passages stay hidden from the reader's Library.",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("title",)

    def __str__(self):
        return self.title

    @property
    def page_count(self):
        return self.pages.count()

    @property
    def word_count(self):
        return sum(page.word_count for page in self.pages.all())


class PassagePage(models.Model):
    """One screenful of a passage.

    Paragraphs are stored as a single text field split on blank lines rather
    than as their own table: a researcher pasting study material into the admin
    should be typing prose, not managing row order for every paragraph.
    """

    passage = models.ForeignKey(Passage, on_delete=models.CASCADE, related_name="pages")
    order = models.PositiveSmallIntegerField(default=1)
    body = models.TextField(help_text="Separate paragraphs with a blank line.")

    class Meta:
        ordering = ("order",)
        unique_together = ("passage", "order")

    def __str__(self):
        return f"{self.passage.slug} p{self.order}"

    @property
    def paragraphs(self):
        return [p.strip() for p in PARAGRAPH_SPLIT.split(self.body) if p.strip()]

    @property
    def word_count(self):
        return sum(len(p.split()) for p in self.paragraphs)


class Assignment(models.Model):
    """A passage a therapist has set for one reader."""

    reader = models.ForeignKey(
        "readers.ReaderProfile", on_delete=models.CASCADE, related_name="assignments"
    )
    passage = models.ForeignKey(
        Passage, on_delete=models.CASCADE, related_name="assignments"
    )
    assigned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )
    profile = models.CharField(
        max_length=16,
        blank=True,
        help_text="Reading condition to run this passage under, if fixed.",
    )
    assigned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-assigned_at",)
        unique_together = ("reader", "passage")

    def __str__(self):
        return f"{self.passage.slug} -> {self.reader.participant_id}"


class Bookmark(models.Model):
    """Where a reader saved their place, and the line they saved it on."""

    reader = models.ForeignKey(
        "readers.ReaderProfile", on_delete=models.CASCADE, related_name="bookmarks"
    )
    passage = models.ForeignKey(
        Passage, on_delete=models.CASCADE, related_name="bookmarks"
    )
    page_index = models.PositiveSmallIntegerField(default=0)
    excerpt = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-created_at",)
        unique_together = ("reader", "passage", "page_index")

    def __str__(self):
        return f"{self.reader.participant_id} @ {self.passage.slug} p{self.page_index}"


class QuizQuestion(models.Model):
    """A comprehension question for one passage.

    Authored in the admin rather than compiled into the app, for the same
    reason the passages are: the researcher must be able to change study
    material — and the questions that measure comprehension against it —
    without shipping a new APK.
    """

    class Kind(models.TextChoices):
        MULTIPLE_CHOICE = "multiple_choice", "Multiple choice"
        TRUE_FALSE = "true_false", "True / False"

    passage = models.ForeignKey(
        Passage, on_delete=models.CASCADE, related_name="questions"
    )
    order = models.PositiveSmallIntegerField(default=1)
    kind = models.CharField(
        max_length=20, choices=Kind.choices, default=Kind.MULTIPLE_CHOICE
    )
    prompt = models.TextField()
    options = models.JSONField(
        default=list,
        help_text='Answer options, e.g. ["একটা ভেজা পাখি", "একটা রঙিন ছাতা"].',
    )
    correct_index = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ("order",)
        unique_together = ("passage", "order")

    def __str__(self):
        return f"{self.passage.slug} q{self.order}"

    def clean(self):
        from django.core.exceptions import ValidationError

        if not isinstance(self.options, list) or len(self.options) < 2:
            raise ValidationError({"options": "At least two options are required."})
        if self.correct_index >= len(self.options):
            raise ValidationError(
                {"correct_index": "Must point at one of the options."}
            )
