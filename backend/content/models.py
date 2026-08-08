from django.db import models


class OrderedContent(models.Model):
    """Shared shape for the small editable lists on Help and About."""

    order = models.PositiveSmallIntegerField(default=1)
    is_published = models.BooleanField(default=True)

    class Meta:
        abstract = True
        ordering = ("order",)


class HelpFeature(OrderedContent):
    """One row of the "Accessibility features" list on the Help screen."""

    icon = models.CharField(
        max_length=48,
        default="check_circle",
        help_text="Material icon name, e.g. volume_up, spellcheck, format_size.",
    )
    name = models.CharField(max_length=120)
    description = models.TextField()

    def __str__(self):
        return self.name


class Faq(OrderedContent):
    question = models.CharField(max_length=240)
    answer = models.TextField(blank=True)

    def __str__(self):
        return self.question


class AboutEntry(OrderedContent):
    """A key/value row in the About screen's research-details card."""

    key = models.CharField(max_length=80)
    value = models.CharField(max_length=200)

    class Meta(OrderedContent.Meta):
        verbose_name_plural = "about entries"

    def __str__(self):
        return f"{self.key}: {self.value}"


class AccessibilityPoint(OrderedContent):
    """One bullet in the About screen's accessibility summary."""

    text = models.CharField(max_length=200)

    def __str__(self):
        return self.text


class AppNotice(models.Model):
    """A single editable block of prose, addressed by key.

    Used for the Help intro and the About disclaimer — copy the researcher may
    need to reword for an ethics board without waiting for a new build.
    """

    key = models.SlugField(max_length=48, unique=True)
    title = models.CharField(max_length=160, blank=True)
    body = models.TextField()
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.key
