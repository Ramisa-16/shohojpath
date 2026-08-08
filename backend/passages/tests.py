import json

from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import User
from readers.models import Notification, ReaderProfile

from .admin import PassageAdmin
from .models import Assignment, Bookmark, Passage, PassagePage, QuizQuestion


def make_passage(slug="story", pages=(("এক", "দুই"), ("তিন",)), published=True):
    passage = Passage.objects.create(
        slug=slug, title=slug.title(), is_published=published
    )
    for index, page in enumerate(pages, start=1):
        PassagePage.objects.create(
            passage=passage, order=index, body="\n\n".join(page)
        )
    return passage


class PassageModelTests(APITestCase):
    def test_paragraphs_split_on_blank_lines(self):
        page = PassagePage(body="প্রথম অনুচ্ছেদ\n\n  \n\nদ্বিতীয় অনুচ্ছেদ\n")
        self.assertEqual(page.paragraphs, ["প্রথম অনুচ্ছেদ", "দ্বিতীয় অনুচ্ছেদ"])

    def test_a_single_paragraph_page_still_works(self):
        self.assertEqual(PassagePage(body="একটি মাত্র").paragraphs, ["একটি মাত্র"])


class PassageApiTests(APITestCase):
    def setUp(self):
        self.reader_user = User.objects.create_user(
            email="r@example.com", password="studypass123", role=User.Role.READER
        )
        ReaderProfile.objects.create(user=self.reader_user, display_name="R")
        self.client.force_authenticate(self.reader_user)

    def test_library_hides_unpublished_passages(self):
        make_passage("published")
        make_passage("draft", published=False)
        response = self.client.get(reverse("passages:list"))
        slugs = [p["id"] for p in response.data["results"]]
        # Membership, not equality: the seed migration means this
        # database is never empty.
        self.assertIn("published", slugs)
        self.assertNotIn("draft", slugs)

    def test_detail_returns_pages_as_paragraph_lists(self):
        make_passage("story", pages=(("এক", "দুই"), ("তিন",)))
        response = self.client.get(reverse("passages:detail", args=["story"]))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["pages"]), 2)
        self.assertEqual(response.data["pages"][0]["paragraphs"], ["এক", "দুই"])
        self.assertEqual(response.data["page_count"], 2)

    def test_search_and_difficulty_filters(self):
        make_passage("rain")
        Passage.objects.filter(slug="rain").update(
            title="বৃষ্টির দিন", difficulty="hard"
        )

        def slugs(**params):
            return [
                p["id"]
                for p in self.client.get(
                    reverse("passages:list"), params
                ).data["results"]
            ]

        self.assertIn("rain", slugs(difficulty="hard"))
        self.assertNotIn("rain", slugs(difficulty="easy"))
        # Search matches on substring, so a seeded passage sharing the
        # phrase legitimately appears too — assert membership, and that
        # something unrelated is excluded.
        matches = slugs(search="বৃষ্টির দিন")
        self.assertIn("rain", matches)
        self.assertNotIn("amader_gram", matches)

    def test_anonymous_cannot_read_the_library(self):
        self.client.force_authenticate(None)
        self.assertEqual(
            self.client.get(reverse("passages:list")).status_code,
            status.HTTP_401_UNAUTHORIZED,
        )


class BookmarkTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="r@example.com", password="studypass123", role=User.Role.READER
        )
        self.reader = ReaderProfile.objects.create(user=self.user, display_name="R")
        self.passage = make_passage("story")
        self.client.force_authenticate(self.user)

    def test_creating_and_listing(self):
        response = self.client.post(
            reverse("passages:bookmarks"),
            {"passage_id": "story", "page_index": 2, "excerpt": "মিতু দেখল"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        listed = self.client.get(reverse("passages:bookmarks"))
        self.assertEqual(listed.data["results"][0]["passage_title"], "Story")

    def test_bookmarking_the_same_page_updates_instead_of_failing(self):
        payload = {"passage_id": "story", "page_index": 2, "excerpt": "first"}
        self.client.post(reverse("passages:bookmarks"), payload, format="json")
        again = self.client.post(
            reverse("passages:bookmarks"),
            {**payload, "excerpt": "second"},
            format="json",
        )
        self.assertEqual(again.status_code, status.HTTP_200_OK)
        self.assertEqual(Bookmark.objects.count(), 1)
        self.assertEqual(Bookmark.objects.get().excerpt, "second")

    def test_a_reader_only_sees_their_own_bookmarks(self):
        Bookmark.objects.create(reader=self.reader, passage=self.passage, page_index=1)
        other_user = User.objects.create_user(
            email="o@example.com", password="studypass123", role=User.Role.READER
        )
        ReaderProfile.objects.create(user=other_user, display_name="O")
        self.client.force_authenticate(other_user)
        self.assertEqual(len(self.client.get(reverse("passages:bookmarks")).data["results"]), 0)


class AssignmentTests(APITestCase):
    def setUp(self):
        self.therapist = User.objects.create_user(
            email="doc@example.com",
            password="studypass123",
            full_name="Dr Karim",
            role=User.Role.THERAPIST,
        )
        self.reader_user = User.objects.create_user(
            email="r@example.com", password="studypass123", role=User.Role.READER
        )
        self.reader = ReaderProfile.objects.create(
            user=self.reader_user, display_name="Rafi", therapist=self.therapist
        )
        make_passage("story")
        self.client.force_authenticate(self.therapist)

    def test_assigning_notifies_the_reader(self):
        response = self.client.post(
            reverse("passages:reader-assignments", args=[self.reader.participant_id]),
            {"passage_id": "story"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        note = Notification.objects.get(recipient=self.reader_user)
        self.assertEqual(note.kind, Notification.Kind.PASSAGE_ASSIGNED)

    def test_reassigning_does_not_notify_twice(self):
        url = reverse("passages:reader-assignments", args=[self.reader.participant_id])
        self.client.post(url, {"passage_id": "story"}, format="json")
        self.client.post(url, {"passage_id": "story"}, format="json")
        self.assertEqual(Assignment.objects.count(), 1)
        self.assertEqual(Notification.objects.count(), 1)

    def test_cannot_assign_to_someone_elses_reader(self):
        rival = User.objects.create_user(
            email="rival@example.com", password="studypass123", role=User.Role.THERAPIST
        )
        self.client.force_authenticate(rival)
        response = self.client.post(
            reverse("passages:reader-assignments", args=[self.reader.participant_id]),
            {"passage_id": "story"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_reader_sees_their_assignments(self):
        self.client.post(
            reverse("passages:reader-assignments", args=[self.reader.participant_id]),
            {"passage_id": "story"},
            format="json",
        )
        self.client.force_authenticate(self.reader_user)
        response = self.client.get(reverse("passages:my-assignments"))
        self.assertEqual(response.data["results"][0]["passage_id"], "story")


class PassageUploadTests(APITestCase):
    """The admin import — how study material actually gets into the app."""

    def _upload(self, payload, overwrite=True):
        file = SimpleUploadedFile(
            "passages.json",
            json.dumps(payload).encode("utf-8"),
            content_type="application/json",
        )
        admin = PassageAdmin(Passage, None)
        return admin._import(file, overwrite=overwrite)

    def test_imports_a_new_passage_with_its_pages(self):
        created, updated, skipped = self._upload(
            [
                {
                    # Not a seeded slug: importing one of those is an
                    # update, and this test is about creation.
                    "slug": "imported_story",
                    "title": "বৃষ্টির দিনে মিতু",
                    "difficulty": "easy",
                    "estimated_minutes": 3,
                    "pages": [["একদিন সকালে", "হঠাৎ মিতু দেখল"], ["পাখিটার ডানা"]],
                }
            ]
        )
        self.assertEqual((created, updated, skipped), (1, 0, 0))

        passage = Passage.objects.get(slug="imported_story")
        self.assertEqual(passage.title, "বৃষ্টির দিনে মিতু")
        self.assertEqual(passage.pages.count(), 2)
        self.assertEqual(
            passage.pages.first().paragraphs, ["একদিন সকালে", "হঠাৎ মিতু দেখল"]
        )

    def test_accepts_a_single_object_as_well_as_a_list(self):
        created, _, _ = self._upload(
            {"slug": "solo", "title": "Solo", "pages": [["এক"]]}
        )
        self.assertEqual(created, 1)

    def test_reupload_replaces_pages_rather_than_appending(self):
        self._upload({"slug": "s", "title": "S", "pages": [["a"], ["b"], ["c"]]})
        self._upload({"slug": "s", "title": "S v2", "pages": [["only page"]]})

        passage = Passage.objects.get(slug="s")
        self.assertEqual(passage.title, "S v2")
        self.assertEqual(
            passage.pages.count(), 1, "old pages must not survive a re-upload"
        )

    def test_overwrite_off_skips_existing(self):
        self._upload({"slug": "s", "title": "Original", "pages": [["a"]]})
        created, updated, skipped = self._upload(
            {"slug": "s", "title": "Changed", "pages": [["b"]]}, overwrite=False
        )
        self.assertEqual((created, updated, skipped), (0, 0, 1))
        self.assertEqual(Passage.objects.get(slug="s").title, "Original")

    def test_a_passage_without_pages_is_rejected(self):
        with self.assertRaises(ValueError):
            self._upload({"slug": "empty", "title": "Empty", "pages": []})

    def test_a_passage_without_a_slug_is_rejected(self):
        with self.assertRaises(ValueError):
            self._upload({"slug": "  ", "title": "No slug", "pages": [["a"]]})

    def test_a_bad_import_leaves_nothing_behind(self):
        # The second item is invalid, so the whole file must roll back rather
        # than half-importing a passage set.
        with self.assertRaises(ValueError):
            self._upload(
                [
                    {"slug": "good", "title": "Good", "pages": [["a"]]},
                    {"slug": "bad", "title": "Bad", "pages": []},
                ]
            )
        self.assertFalse(Passage.objects.filter(slug="good").exists())


class QuizQuestionTests(APITestCase):
    """Comprehension questions come from the backend so the researcher can
    author them per passage without shipping a new APK."""

    def setUp(self):
        self.user = User.objects.create_user(
            email="r@example.com", password="studypass123", role=User.Role.READER
        )
        ReaderProfile.objects.create(user=self.user, display_name="R")
        self.client.force_authenticate(self.user)

    def _upload(self, payload, overwrite=True):
        file = SimpleUploadedFile(
            "p.json", json.dumps(payload).encode("utf-8"), content_type="application/json"
        )
        return PassageAdmin(Passage, None)._import(file, overwrite=overwrite)

    def test_questions_come_back_with_the_passage(self):
        passage = make_passage("story")
        QuizQuestion.objects.create(
            passage=passage,
            order=1,
            prompt="মিতু কী দেখেছিল?",
            options=["একটা ভেজা পাখি", "একটা ছাতা"],
            correct_index=0,
        )
        response = self.client.get(reverse("passages:detail", args=["story"]))
        questions = response.data["questions"]
        self.assertEqual(len(questions), 1)
        self.assertEqual(questions[0]["prompt"], "মিতু কী দেখেছিল?")
        self.assertEqual(questions[0]["correct_index"], 0)

    def test_upload_imports_questions(self):
        self._upload(
            {
                "slug": "s",
                "title": "S",
                "pages": [["এক"]],
                "questions": [
                    {
                        "prompt": "কী?",
                        "options": ["ক", "খ"],
                        "correct_index": 1,
                        "kind": "multiple_choice",
                    }
                ],
            }
        )
        question = Passage.objects.get(slug="s").questions.get()
        self.assertEqual(question.correct_index, 1)

    def test_reupload_replaces_the_question_set(self):
        base = {"slug": "s", "title": "S", "pages": [["এক"]]}
        self._upload({**base, "questions": [
            {"prompt": "one", "options": ["a", "b"]},
            {"prompt": "two", "options": ["a", "b"]},
        ]})
        self._upload({**base, "questions": [{"prompt": "only", "options": ["a", "b"]}]})
        self.assertEqual(Passage.objects.get(slug="s").questions.count(), 1)

    def test_a_question_with_one_option_is_rejected(self):
        with self.assertRaises(ValueError):
            self._upload({
                "slug": "s", "title": "S", "pages": [["এক"]],
                "questions": [{"prompt": "bad", "options": ["only one"]}],
            })

    def test_correct_index_out_of_range_is_rejected(self):
        with self.assertRaises(ValueError):
            self._upload({
                "slug": "s", "title": "S", "pages": [["এক"]],
                "questions": [{"prompt": "bad", "options": ["a", "b"], "correct_index": 5}],
            })

    def test_a_passage_without_questions_still_imports(self):
        created, _, _ = self._upload({"slug": "s", "title": "S", "pages": [["এক"]]})
        self.assertEqual(created, 1)
        self.assertEqual(Passage.objects.get(slug="s").questions.count(), 0)


class SeededPassageTests(APITestCase):
    """A fresh install must find a real Library, not an empty one.

    The passages the app used to carry compiled in are seeded by migration, so
    a researcher can open the admin and edit study material rather than being
    handed a blank database.
    """

    def setUp(self):
        self.user = User.objects.create_user(
            email="r@example.com", password="studypass123", role=User.Role.READER
        )
        ReaderProfile.objects.create(user=self.user, display_name="R")
        self.client.force_authenticate(self.user)

    def test_the_library_is_populated_on_a_fresh_database(self):
        response = self.client.get(reverse("passages:list"))
        self.assertGreaterEqual(len(response.data["results"]), 5)

    def test_the_sample_story_has_its_pages_and_questions(self):
        response = self.client.get(
            reverse("passages:detail", args=["bristir_dine_mitu"])
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["title"], "বৃষ্টির দিনে মিতু")
        self.assertEqual(len(response.data["pages"]), 6)
        self.assertEqual(len(response.data["questions"]), 5)

    def test_paragraphs_survived_the_import_intact(self):
        page = Passage.objects.get(slug="bristir_dine_mitu").pages.first()
        paragraphs = page.paragraphs
        self.assertEqual(len(paragraphs), 2)
        # Dart concatenated adjacent literals; a bad import shows up as a
        # doubled space at the seam or a word split across it.
        for paragraph in paragraphs:
            self.assertNotIn('  ', paragraph)
        self.assertTrue(paragraphs[0].startswith('একদিন সকালে'))
        self.assertIn('ঝিরিঝিরি বৃষ্টি', paragraphs[0])

    def test_every_seeded_question_is_answerable(self):
        for question in QuizQuestion.objects.all():
            self.assertGreaterEqual(len(question.options), 2)
            self.assertLess(question.correct_index, len(question.options))

    def test_all_difficulties_are_represented(self):
        # The Library's difficulty filter is worth nothing if every passage is
        # Easy — the seed spans the range so the control can be exercised.
        levels = set(Passage.objects.values_list("difficulty", flat=True))
        self.assertGreaterEqual(len(levels), 3)
