from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import User
from passages.models import Passage, PassagePage
from readers.models import ReaderProfile

from .models import PageTime, StudySession


def session_payload(session_id, participant_id, **overrides):
    base = {
        "session_id": session_id,
        "participant_id": participant_id,
        "passage_id": "story",
        "started_at": timezone.now().isoformat(),
        "ended_at": timezone.now().isoformat(),
        "profile": "recommended",
        "total_reading_seconds": 252.0,
        "words_read": 400,
        "read_aloud_on": True,
        "audio_duration_seconds": 120.0,
        "quiz_score": 4,
        "quiz_total": 5,
        "page_times": [
            {"page_index": 0, "seconds": 60.0},
            {"page_index": 1, "seconds": 90.0},
        ],
        "quiz_answers": [
            {
                "question_index": 0,
                "selected_index": 1,
                "correct": True,
                "time_seconds": 8.0,
            }
        ],
        "settings_changes": [
            {
                "at": timezone.now().isoformat(),
                "key": "font_size",
                "old_value": "22",
                "new_value": "28",
                "profile": "custom",
            }
        ],
        "sus_responses": [{"item_index": 0, "response": 4}],
        "tlx_responses": [{"subscale": "mental", "value": 35}],
    }
    base.update(overrides)
    return base


class SyncTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="r@example.com", password="studypass123", role=User.Role.READER
        )
        self.reader = ReaderProfile.objects.create(
            user=self.user, display_name="Rafi"
        )
        self.client.force_authenticate(self.user)
        self.url = reverse("sync:upload")

    def test_uploads_a_session_with_all_its_children(self):
        response = self.client.post(
            self.url,
            {"sessions": [session_payload("s1", self.reader.participant_id)]},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["synced"], 1)

        session = StudySession.objects.get(session_id="s1")
        self.assertEqual(session.page_times.count(), 2)
        self.assertEqual(session.quiz_answers.count(), 1)
        self.assertEqual(session.settings_changes.count(), 1)
        self.assertEqual(session.sus_responses.count(), 1)
        self.assertEqual(session.tlx_responses.count(), 1)

    def test_links_the_session_to_the_reader_profile(self):
        self.client.post(
            self.url,
            {"sessions": [session_payload("s1", self.reader.participant_id)]},
            format="json",
        )
        self.assertEqual(StudySession.objects.get(session_id="s1").reader, self.reader)

    def test_re_uploading_the_same_session_is_idempotent(self):
        payload = {"sessions": [session_payload("s1", self.reader.participant_id)]}
        first = self.client.post(self.url, payload, format="json")
        second = self.client.post(self.url, payload, format="json")

        # Both must succeed. A rejected retry would leave these counts correct
        # too, so asserting the status is what makes this test mean anything.
        self.assertEqual(first.status_code, status.HTTP_200_OK)
        self.assertEqual(second.status_code, status.HTTP_200_OK)
        self.assertEqual(second.data["synced"], 1)

        self.assertEqual(StudySession.objects.count(), 1)
        self.assertEqual(
            PageTime.objects.count(), 2, "children must be replaced, not appended"
        )

    def test_re_uploading_updates_changed_fields(self):
        self.client.post(
            self.url,
            {"sessions": [session_payload("s1", self.reader.participant_id)]},
            format="json",
        )
        self.client.post(
            self.url,
            {
                "sessions": [
                    session_payload(
                        "s1", self.reader.participant_id, quiz_score=5, sus_score=82.5
                    )
                ]
            },
            format="json",
        )
        session = StudySession.objects.get(session_id="s1")
        self.assertEqual(session.quiz_score, 5)
        self.assertEqual(session.sus_score, 82.5)

    def test_uploads_a_batch(self):
        response = self.client.post(
            self.url,
            {
                "sessions": [
                    session_payload("s1", self.reader.participant_id),
                    session_payload("s2", self.reader.participant_id),
                ]
            },
            format="json",
        )
        self.assertEqual(response.data["synced"], 2)
        self.assertEqual(StudySession.objects.count(), 2)

    def test_anonymous_cannot_upload(self):
        self.client.force_authenticate(None)
        response = self.client.post(
            self.url,
            {"sessions": [session_payload("s1", self.reader.participant_id)]},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class DerivedDataTests(APITestCase):
    """Progress and Statistics are computed from synced rows, so a number on
    screen can always be traced back to the exported data."""

    def setUp(self):
        self.user = User.objects.create_user(
            email="r@example.com", password="studypass123", role=User.Role.READER
        )
        self.reader = ReaderProfile.objects.create(user=self.user, display_name="Rafi")
        passage = Passage.objects.create(slug="story", title="Story")
        for i in range(1, 5):
            PassagePage.objects.create(passage=passage, order=i, body=f"page {i}")
        self.client.force_authenticate(self.user)
        self.client.post(
            reverse("sync:upload"),
            {"sessions": [session_payload("s1", self.reader.participant_id)]},
            format="json",
        )

    def test_progress_reports_todays_reading(self):
        response = self.client.get(reverse("sync:progress"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertAlmostEqual(response.data["minutes_today"], 4.2, places=1)
        self.assertEqual(response.data["pages_today"], 2)
        self.assertEqual(len(response.data["week"]), 7)

    def test_progress_reports_current_passage_percent(self):
        response = self.client.get(reverse("sync:progress"))
        current = response.data["current_passage"]
        self.assertEqual(current["passage_id"], "story")
        self.assertEqual(current["page_count"], 4)
        self.assertEqual(current["pages_read"], 2)
        self.assertEqual(current["percent"], 50.0)

    def test_statistics_derive_speed_and_comprehension(self):
        response = self.client.get(reverse("sync:statistics"))
        self.assertEqual(response.data["words_this_week"], 400)
        # 400 words over 252 s = 95.2 wpm
        self.assertAlmostEqual(response.data["words_per_minute"], 95.2, places=1)
        self.assertEqual(response.data["comprehension_percent"], 80.0)
        self.assertEqual(response.data["read_aloud_percent"], 100.0)
        self.assertEqual(response.data["sessions_logged"], 1)

    def test_statistics_report_which_settings_were_touched(self):
        response = self.client.get(reverse("sync:statistics"))
        keys = [row["key"] for row in response.data["most_changed_settings"]]
        self.assertIn("font_size", keys)

    def test_a_reader_with_no_sessions_gets_zeroes_not_an_error(self):
        fresh = User.objects.create_user(
            email="new@example.com", password="studypass123", role=User.Role.READER
        )
        ReaderProfile.objects.create(user=fresh, display_name="New")
        self.client.force_authenticate(fresh)

        progress = self.client.get(reverse("sync:progress"))
        self.assertEqual(progress.status_code, status.HTTP_200_OK)
        self.assertEqual(progress.data["minutes_today"], 0)
        self.assertIsNone(progress.data["current_passage"])

        stats = self.client.get(reverse("sync:statistics"))
        self.assertEqual(stats.data["words_this_week"], 0)
        self.assertIsNone(stats.data["words_per_minute"])

    def test_history_lists_the_readers_own_sessions_only(self):
        other = User.objects.create_user(
            email="o@example.com", password="studypass123", role=User.Role.READER
        )
        ReaderProfile.objects.create(user=other, display_name="Other")
        self.client.force_authenticate(other)
        response = self.client.get(reverse("sync:my-sessions"))
        self.assertEqual(len(response.data["results"]), 0)


class TherapistOverviewTests(APITestCase):
    def setUp(self):
        self.therapist = User.objects.create_user(
            email="doc@example.com", password="studypass123", role=User.Role.THERAPIST
        )
        reader_user = User.objects.create_user(
            email="r@example.com", password="studypass123", role=User.Role.READER
        )
        self.reader = ReaderProfile.objects.create(
            user=reader_user, display_name="Rafi", therapist=self.therapist
        )
        self.client.force_authenticate(reader_user)
        self.client.post(
            reverse("sync:upload"),
            {"sessions": [session_payload("s1", self.reader.participant_id)]},
            format="json",
        )

    def test_counts_only_my_own_readers(self):
        self.client.force_authenticate(self.therapist)
        response = self.client.get(reverse("sync:overview"))
        self.assertEqual(response.data["reader_count"], 1)
        self.assertEqual(response.data["session_count"], 1)

    def test_a_reader_cannot_open_the_therapist_overview(self):
        response = self.client.get(reverse("sync:overview"))
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


class TherapistViewingReaderProgressTests(APITestCase):
    """A therapist must see exactly the figures their reader sees — and
    nothing at all for a reader who is not on their roster."""

    def setUp(self):
        self.therapist = User.objects.create_user(
            email="doc@example.com", password="studypass123", role=User.Role.THERAPIST
        )
        self.rival = User.objects.create_user(
            email="rival@example.com", password="studypass123", role=User.Role.THERAPIST
        )
        self.reader_user = User.objects.create_user(
            email="r@example.com", password="studypass123", role=User.Role.READER
        )
        self.reader = ReaderProfile.objects.create(
            user=self.reader_user, display_name="Rafi", therapist=self.therapist
        )
        passage = Passage.objects.create(slug="story", title="Story")
        for i in range(1, 5):
            PassagePage.objects.create(passage=passage, order=i, body=f"page {i}")

        self.client.force_authenticate(self.reader_user)
        self.client.post(
            reverse("sync:upload"),
            {"sessions": [session_payload("s1", self.reader.participant_id)]},
            format="json",
        )

    def test_therapist_sees_the_same_progress_as_the_reader(self):
        own = self.client.get(reverse("sync:progress")).data

        self.client.force_authenticate(self.therapist)
        theirs = self.client.get(
            reverse("sync:reader-progress", args=[self.reader.participant_id])
        ).data

        self.assertEqual(theirs["minutes_today"], own["minutes_today"])
        self.assertEqual(theirs["pages_today"], own["pages_today"])
        self.assertEqual(
            theirs["current_passage"]["percent"], own["current_passage"]["percent"]
        )
        self.assertEqual(theirs["display_name"], "Rafi")

    def test_therapist_sees_the_same_statistics_as_the_reader(self):
        own = self.client.get(reverse("sync:statistics")).data

        self.client.force_authenticate(self.therapist)
        theirs = self.client.get(
            reverse("sync:reader-statistics", args=[self.reader.participant_id])
        ).data

        self.assertEqual(theirs["words_per_minute"], own["words_per_minute"])
        self.assertEqual(
            theirs["comprehension_percent"], own["comprehension_percent"]
        )

    def test_another_therapist_cannot_see_this_readers_progress(self):
        self.client.force_authenticate(self.rival)
        for name in ("sync:reader-progress", "sync:reader-statistics", "sync:reader-sessions"):
            response = self.client.get(
                reverse(name, args=[self.reader.participant_id])
            )
            self.assertEqual(
                response.status_code,
                status.HTTP_404_NOT_FOUND,
                msg=f"{name} leaked a reader from another therapist's roster",
            )

    def test_a_reader_cannot_read_another_readers_progress(self):
        other = User.objects.create_user(
            email="o@example.com", password="studypass123", role=User.Role.READER
        )
        ReaderProfile.objects.create(user=other, display_name="Other")
        self.client.force_authenticate(other)
        response = self.client.get(
            reverse("sync:reader-progress", args=[self.reader.participant_id])
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_readers_summary_lists_the_roster_with_real_counts(self):
        self.client.force_authenticate(self.therapist)
        response = self.client.get(reverse("sync:readers-summary"))
        row = response.data["readers"][0]
        self.assertEqual(row["participant_id"], self.reader.participant_id)
        self.assertEqual(row["sessions_total"], 1)
        self.assertIsNotNone(row["last_read_at"])

    def test_summary_excludes_other_therapists_readers(self):
        self.client.force_authenticate(self.rival)
        response = self.client.get(reverse("sync:readers-summary"))
        self.assertEqual(response.data["readers"], [])
