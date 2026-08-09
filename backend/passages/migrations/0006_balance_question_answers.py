import json
from pathlib import Path

from django.db import migrations

# The seeded questions were authored with the correct option written first,
# so 86 of 90 answers sat in slot 1: a child tapping the top choice scored
# 96% without reading anything, and comprehension_percent measured nothing.
# Ten true/false statements were also rewritten, because 24 of 28 were true
# and answering সত্য to all of them scored 86%.
#
# The fixture now spreads the answers (16/15/16/15 across four options, 14/14
# true and false). This brings existing databases in line.
#
# Guarded: recorded quiz answers store the option INDEX a participant chose,
# so reordering options after anyone has answered would silently change what
# their stored answers mean. If any exist, this does nothing and says so —
# fixing the questions is then a decision about the data, not a migration.

FIXTURE = Path(__file__).resolve().parent.parent / "fixtures" / "aesop_passages.json"


def rebalance(apps, schema_editor):
    Passage = apps.get_model("passages", "Passage")
    QuizQuestion = apps.get_model("passages", "QuizQuestion")
    QuizAnswer = apps.get_model("sync", "QuizAnswer")

    if QuizAnswer.objects.exists():
        print(
            "\n  Quiz answers already recorded — leaving questions untouched.\n"
            "  Reordering options now would change what those answers mean.\n"
            "  Run `manage.py replace_passages` deliberately if the recorded\n"
            "  answers are test data and can be discarded."
        )
        return

    for item in json.loads(FIXTURE.read_text(encoding="utf-8")):
        questions = item.get("questions") or []
        if not questions:
            continue

        passage = Passage.objects.filter(slug=item["slug"]).first()
        if passage is None:
            continue

        existing = QuizQuestion.objects.filter(passage=passage)
        # Only replace the seeded set. A researcher who has authored their own
        # questions in the admin keeps them: a different count is the clearest
        # signal that these are no longer the ones we put there.
        if existing.count() != len(questions):
            continue

        existing.delete()
        for order, question in enumerate(questions, start=1):
            options = [str(o) for o in question.get("options", []) if str(o).strip()]
            correct = int(question.get("correct_index", 0))
            if len(options) < 2 or correct >= len(options):
                continue
            QuizQuestion.objects.create(
                passage=passage,
                order=order,
                kind=question.get("kind", "multiple_choice"),
                prompt=str(question.get("prompt", "")).strip(),
                options=options,
                correct_index=correct,
            )


def noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):
    dependencies = [
        ("passages", "0005_seed_aesop_questions"),
        ("sync", "0001_initial"),
    ]
    operations = [migrations.RunPython(rebalance, noop)]
