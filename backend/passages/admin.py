import json

from django import forms
from django.contrib import admin, messages
from django.db import transaction
from django.shortcuts import redirect, render
from django.urls import path, reverse
from django.utils.html import format_html

from .models import Assignment, Bookmark, Passage, PassagePage, QuizQuestion


class PassagePageInline(admin.StackedInline):
    model = PassagePage
    extra = 1
    fields = ("order", "body")


class QuizQuestionInline(admin.StackedInline):
    model = QuizQuestion
    extra = 0
    fields = ("order", "kind", "prompt", "options", "correct_index")


class PassageUploadForm(forms.Form):
    """Bulk import so a researcher can load a whole passage set at once.

    Typing six pages of Bangla into the admin one box at a time is exactly the
    kind of friction that ends with study material living in a Word document
    instead of the app.
    """

    file = forms.FileField(
        label="Passage file (.json)",
        help_text=(
            "One passage object or a list of them. Each needs: slug, title, "
            "and pages (a list of pages, each a list of paragraph strings). "
            "Optional: category, difficulty, estimated_minutes, is_published."
        ),
    )
    overwrite = forms.BooleanField(
        required=False,
        initial=True,
        label="Replace passages that already exist",
        help_text="Unchecked, an existing slug is skipped instead of updated.",
    )


@admin.register(Passage)
class PassageAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "slug",
        "category",
        "difficulty",
        "page_count",
        "word_count",
        "is_published",
        "updated_at",
    )
    list_filter = ("difficulty", "category", "is_published")
    search_fields = ("title", "slug", "pages__body")
    prepopulated_fields = {"slug": ("title",)}
    inlines = [PassagePageInline, QuizQuestionInline]
    change_list_template = "admin/passages/passage_changelist.html"

    def get_urls(self):
        return [
            path(
                "upload/",
                self.admin_site.admin_view(self.upload_view),
                name="passages_passage_upload",
            ),
            *super().get_urls(),
        ]

    def upload_view(self, request):
        if request.method == "POST":
            form = PassageUploadForm(request.POST, request.FILES)
            if form.is_valid():
                try:
                    created, updated, skipped = self._import(
                        form.cleaned_data["file"],
                        overwrite=form.cleaned_data["overwrite"],
                    )
                except (ValueError, KeyError, json.JSONDecodeError) as exc:
                    self.message_user(request, f"Import failed: {exc}", messages.ERROR)
                else:
                    self.message_user(
                        request,
                        f"Imported {created} new, updated {updated}, skipped {skipped}.",
                        messages.SUCCESS,
                    )
                    return redirect(reverse("admin:passages_passage_changelist"))
        else:
            form = PassageUploadForm()

        return render(
            request,
            "admin/passages/upload.html",
            {
                **self.admin_site.each_context(request),
                "form": form,
                "title": "Upload passages",
                "opts": self.model._meta,
            },
        )

    @transaction.atomic
    def _import(self, uploaded, *, overwrite):
        payload = json.loads(uploaded.read().decode("utf-8"))
        items = payload if isinstance(payload, list) else [payload]

        created = updated = skipped = 0
        for item in items:
            slug = str(item["slug"]).strip()
            if not slug:
                raise ValueError("Every passage needs a non-empty slug.")

            pages = item.get("pages") or []
            if not pages:
                raise ValueError(f"Passage '{slug}' has no pages.")

            existing = Passage.objects.filter(slug=slug).first()
            if existing and not overwrite:
                skipped += 1
                continue

            defaults = {
                "title": item.get("title", slug),
                "category": item.get("category", "Children Stories"),
                "difficulty": item.get("difficulty", Passage.Difficulty.EASY),
                "estimated_minutes": int(item.get("estimated_minutes", 3)),
                "is_published": bool(item.get("is_published", True)),
            }
            passage, was_created = Passage.objects.update_or_create(
                slug=slug, defaults=defaults
            )

            # Replaced wholesale, not merged: a re-upload is the researcher
            # saying "this is the passage now", and merging would silently
            # leave deleted pages behind.
            passage.pages.all().delete()
            for index, page in enumerate(pages, start=1):
                paragraphs = page if isinstance(page, list) else [str(page)]
                PassagePage.objects.create(
                    passage=passage,
                    order=index,
                    body="\n\n".join(str(p).strip() for p in paragraphs if str(p).strip()),
                )

            # Questions are optional, but when present they replace the set
            # wholesale for the same reason the pages do.
            questions = item.get("questions")
            if questions is not None:
                passage.questions.all().delete()
                for index, q in enumerate(questions, start=1):
                    options = list(q.get("options") or [])
                    if len(options) < 2:
                        raise ValueError(
                            f"Question {index} of '{slug}' needs at least two options."
                        )
                    correct = int(q.get("correct_index", 0))
                    if correct >= len(options):
                        raise ValueError(
                            f"Question {index} of '{slug}' has correct_index out of range."
                        )
                    QuizQuestion.objects.create(
                        passage=passage,
                        order=index,
                        kind=q.get("kind", QuizQuestion.Kind.MULTIPLE_CHOICE),
                        prompt=str(q.get("prompt", "")).strip(),
                        options=options,
                        correct_index=correct,
                    )

            created += int(was_created)
            updated += int(not was_created)

        return created, updated, skipped

    @admin.display(description="Pages")
    def page_count(self, obj):
        return obj.page_count

    @admin.display(description="Words")
    def word_count(self, obj):
        return obj.word_count

    @admin.display(description="Upload")
    def upload_link(self, obj=None):
        return format_html(
            '<a class="button" href="{}">Upload passages</a>',
            reverse("admin:passages_passage_upload"),
        )


@admin.register(Assignment)
class AssignmentAdmin(admin.ModelAdmin):
    list_display = ("passage", "reader", "profile", "assigned_by", "assigned_at")
    list_filter = ("profile", "assigned_at")
    search_fields = ("reader__display_name", "reader__participant_id", "passage__title")
    autocomplete_fields = ("reader", "passage")


@admin.register(Bookmark)
class BookmarkAdmin(admin.ModelAdmin):
    list_display = ("reader", "passage", "page_index", "created_at")
    search_fields = ("reader__participant_id", "passage__title")
    autocomplete_fields = ("reader", "passage")
