import json
from pathlib import Path

from django.db import migrations

# Migration 0003 seeded the five sample passages the app used to carry. Those
# have been replaced by the ঈশপের গল্প set, so a fresh database — a new laptop,
# or the first deploy to a real host — must converge on the same library rather
# than quietly resurrecting the old sample material.
#
# Written as a separate migration instead of editing 0003, because 0003 has
# already run on existing databases and rewriting applied history would leave
# the two out of step.

FIXTURE = Path(__file__).resolve().parent.parent / "fixtures" / "aesop_passages.json"

RETIRED = [
    "bristir_dine_mitu",
    "amader_gram",
    "nodir_golpo",
    "ajker_khobor",
    "biggan_o_amra",
]


def seed(apps, schema_editor):
    Passage = apps.get_model("passages", "Passage")
    PassagePage = apps.get_model("passages", "PassagePage")
    StudySession = apps.get_model("sync", "StudySession")

    # Sessions reference a passage by slug, not by foreign key, so deleting one
    # orphans recorded data rather than cascading. Anything already read is kept
    # and merely unpublished — it disappears from the Library while the History
    # screen can still name what was read.
    referenced = set(
        StudySession.objects.filter(passage_id__in=RETIRED)
        .values_list("passage_id", flat=True)
        .distinct()
    )
    Passage.objects.filter(slug__in=referenced).update(is_published=False)
    Passage.objects.filter(slug__in=RETIRED).exclude(slug__in=referenced).delete()

    if not FIXTURE.exists():
        return

    for item in json.loads(FIXTURE.read_text(encoding="utf-8")):
        passage, created = Passage.objects.get_or_create(
            slug=item["slug"],
            defaults={
                "title": item["title"],
                "category": item.get("category", "ঈশপের গল্প"),
                "difficulty": item.get("difficulty", "easy"),
                "estimated_minutes": item.get("estimated_minutes", 3),
                "is_published": item.get("is_published", True),
            },
        )
        # get_or_create: never overwrite a passage a researcher has since
        # edited in the admin.
        if not created:
            continue

        for order, paragraphs in enumerate(item["pages"], start=1):
            PassagePage.objects.create(
                passage=passage,
                order=order,
                body="\n\n".join(paragraphs),
            )


def unseed(apps, schema_editor):
    # No-op: reversing must not delete study material or the sessions that
    # point at it.
    pass


class Migration(migrations.Migration):
    dependencies = [
        ("passages", "0003_seed_bundled_passages"),
        ("sync", "0001_initial"),
    ]
    operations = [migrations.RunPython(seed, unseed)]
