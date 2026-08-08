import json
from pathlib import Path

from django.db import migrations

# The passages the app used to carry compiled in, moved into the database so
# the Library is not empty on a fresh install and so a researcher can edit or
# replace them from the admin without a new APK.
#
# Loaded from a fixture rather than inlined: this is 60 paragraphs of Bangla,
# and a hand-copy is exactly where a silent character-level error (a dropped
# hasant, a swapped vowel sign) would creep into study material.
FIXTURE = (
    Path(__file__).resolve().parent.parent / "fixtures" / "bundled_passages.json"
)


def seed(apps, schema_editor):
    Passage = apps.get_model("passages", "Passage")
    PassagePage = apps.get_model("passages", "PassagePage")
    QuizQuestion = apps.get_model("passages", "QuizQuestion")

    if not FIXTURE.exists():
        return

    data = json.loads(FIXTURE.read_text(encoding="utf-8"))

    for item in data:
        slug = item["slug"]

        # get_or_create, not update_or_create: re-running this must never
        # overwrite edits a researcher has made in the admin.
        passage, created = Passage.objects.get_or_create(
            slug=slug,
            defaults={
                "title": item["title"],
                "category": item["category"],
                "difficulty": item["difficulty"],
                "estimated_minutes": item["estimated_minutes"],
                "is_published": item.get("is_published", True),
            },
        )
        if not created:
            continue

        for order, paragraphs in enumerate(item["pages"], start=1):
            PassagePage.objects.create(
                passage=passage,
                order=order,
                body="\n\n".join(paragraphs),
            )

        for order, question in enumerate(item.get("questions", []), start=1):
            QuizQuestion.objects.create(
                passage=passage,
                order=order,
                kind=question["kind"],
                prompt=question["prompt"],
                options=question["options"],
                correct_index=question["correct_index"],
            )


def unseed(apps, schema_editor):
    # A no-op on purpose. Reversing this migration must not delete passages a
    # researcher may have edited, or the sessions that reference their slugs.
    pass


class Migration(migrations.Migration):
    dependencies = [("passages", "0002_quizquestion")]
    operations = [migrations.RunPython(seed, unseed)]
