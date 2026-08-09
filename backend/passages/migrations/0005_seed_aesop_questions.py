import json
from pathlib import Path

from django.db import migrations

# Migration 0004 seeded the ঈশপের গল্প passages and their pages, but not the
# comprehension questions — the fixture carried them all along and the import
# simply never read them. Locally that went unnoticed because the questions had
# been loaded separately with `replace_passages`; a fresh database (the first
# deploy to a real host) would have come up with thirty stories and an empty
# quiz on every one of them.
#
# Separate migration rather than an edit to 0004, which has already run.

FIXTURE = Path(__file__).resolve().parent.parent / "fixtures" / "aesop_passages.json"


def seed(apps, schema_editor):
    Passage = apps.get_model("passages", "Passage")
    QuizQuestion = apps.get_model("passages", "QuizQuestion")

    for item in json.loads(FIXTURE.read_text(encoding="utf-8")):
        questions = item.get("questions") or []
        if not questions:
            continue

        passage = Passage.objects.filter(slug=item["slug"]).first()
        if passage is None:
            continue

        # Never touch a passage whose questions someone has already authored or
        # edited in the admin: this fills gaps, it does not impose a set.
        if QuizQuestion.objects.filter(passage=passage).exists():
            continue

        for order, question in enumerate(questions, start=1):
            options = [str(o) for o in question.get("options", []) if str(o).strip()]
            if len(options) < 2:
                continue
            correct = int(question.get("correct_index", 0))
            if correct >= len(options):
                continue

            QuizQuestion.objects.create(
                passage=passage,
                order=order,
                kind=question.get("kind", "multiple_choice"),
                prompt=str(question.get("prompt", "")).strip(),
                options=options,
                correct_index=correct,
            )


def unseed(apps, schema_editor):
    # No-op: reversing must not delete study material, and quiz answers already
    # recorded against these questions would go with them.
    pass


class Migration(migrations.Migration):
    dependencies = [("passages", "0004_replace_bundled_with_aesop")]
    operations = [migrations.RunPython(seed, unseed)]
