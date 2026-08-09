import json
from pathlib import Path

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from passages.models import Passage, PassagePage, QuizQuestion
from sync.models import StudySession


class Command(BaseCommand):
    """Replace the passage library from a JSON file.

    Used to swap study material between rounds. Kept as a command rather than a
    migration because it is something a researcher does repeatedly and on
    purpose, not a one-off schema step.
    """

    help = "Replace the passage library from a JSON file."

    def add_arguments(self, parser):
        parser.add_argument("file", type=str, help="Path to the passages JSON.")
        parser.add_argument(
            "--replace-all",
            action="store_true",
            help="Delete existing passages first, instead of adding to them.",
        )
        parser.add_argument(
            "--force",
            action="store_true",
            help="Delete passages even if sessions already reference them.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        path = Path(options["file"])
        if not path.exists():
            raise CommandError(f"No such file: {path}")

        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, list):
            data = [data]

        if options["replace_all"]:
            self._delete_existing(force=options["force"])

        created = updated = 0
        for item in data:
            slug = str(item["slug"]).strip()
            if not slug:
                raise CommandError("Every passage needs a slug.")

            pages = item.get("pages") or []
            if not pages:
                raise CommandError(f"'{slug}' has no pages.")

            passage, was_created = Passage.objects.update_or_create(
                slug=slug,
                defaults={
                    "title": item.get("title", slug),
                    "category": item.get("category", ""),
                    "difficulty": item.get("difficulty", Passage.Difficulty.EASY),
                    "estimated_minutes": int(item.get("estimated_minutes", 3)),
                    "is_published": bool(item.get("is_published", True)),
                },
            )

            passage.pages.all().delete()
            for order, paragraphs in enumerate(pages, start=1):
                body = "\n\n".join(
                    str(p).strip() for p in paragraphs if str(p).strip()
                )
                PassagePage.objects.create(passage=passage, order=order, body=body)

            questions = item.get("questions")
            if questions is not None:
                passage.questions.all().delete()
                for order, q in enumerate(questions, start=1):
                    options_list = list(q.get("options") or [])
                    if len(options_list) < 2:
                        raise CommandError(
                            f"Question {order} of '{slug}' needs two options."
                        )
                    QuizQuestion.objects.create(
                        passage=passage,
                        order=order,
                        kind=q.get("kind", QuizQuestion.Kind.MULTIPLE_CHOICE),
                        prompt=str(q.get("prompt", "")).strip(),
                        options=options_list,
                        correct_index=int(q.get("correct_index", 0)),
                    )

            created += int(was_created)
            updated += int(not was_created)

        total = Passage.objects.count()
        without_questions = Passage.objects.filter(questions__isnull=True).count()

        self.stdout.write(
            self.style.SUCCESS(
                f"Imported {created} new, updated {updated}. "
                f"Library now holds {total} passages."
            )
        )
        if without_questions:
            # Said plainly: comprehension is a dependent variable in the study,
            # and a passage with no questions cannot measure it.
            self.stdout.write(
                self.style.WARNING(
                    f"{without_questions} passage(s) have no comprehension "
                    f"questions. The quiz will be skipped for those."
                )
            )

    def _delete_existing(self, *, force):
        existing = Passage.objects.all()
        slugs = list(existing.values_list("slug", flat=True))
        if not slugs:
            return

        # Sessions store passage_id as a slug, not a foreign key, so deleting a
        # passage does not cascade — it orphans recorded research data, and the
        # History screen would show a session pointing at nothing.
        referenced = set(
            StudySession.objects.filter(passage_id__in=slugs)
            .values_list("passage_id", flat=True)
            .distinct()
        )
        if referenced and not force:
            raise CommandError(
                "These passages already have recorded sessions: "
                + ", ".join(sorted(referenced))
                + ".\nDeleting them would orphan collected data. Re-run with "
                "--force if that is genuinely what you want, or unpublish them "
                "in the admin instead."
            )

        count = existing.count()
        existing.delete()
        self.stdout.write(f"Deleted {count} existing passage(s).")
