from django.core.cache import cache
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import User

from .models import Notification, ReaderProfile


def make_reader(email, name="Reader"):
    user = User.objects.create_user(
        email=email, password="studypass123", full_name=name, role=User.Role.READER
    )
    return ReaderProfile.objects.create(user=user, display_name=name)


def make_therapist(email, name="Therapist"):
    return User.objects.create_user(
        email=email, password="studypass123", full_name=name, role=User.Role.THERAPIST
    )


class SignUpTests(APITestCase):
    def setUp(self):
        # Throttle counters live in the cache and outlive a single test.
        cache.clear()

    def test_reader_signup_creates_a_profile_and_signs_in(self):
        response = self.client.post(
            reverse("accounts:signup"),
            {
                "email": "Mitu@Example.com",
                "password": "studypass123",
                "full_name": "Mitu Rahman",
                "role": "reader",
                "age": 11,
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("access", response.data)
        self.assertIsNotNone(response.data["participant_id"])

        user = User.objects.get(email="mitu@example.com")
        self.assertTrue(user.is_reader)
        self.assertEqual(user.reader_profile.age, 11)
        # Never stored in the clear.
        self.assertNotEqual(user.password, "studypass123")
        self.assertTrue(user.check_password("studypass123"))

    def test_email_is_unique_case_insensitively(self):
        make_reader("mitu@example.com")
        response = self.client.post(
            reverse("accounts:signup"),
            {"email": "MITU@example.com", "password": "studypass123", "role": "reader"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_weak_password_is_rejected(self):
        response = self.client.post(
            reverse("accounts:signup"),
            {"email": "x@example.com", "password": "12345678", "role": "reader"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_therapist_signup_has_no_reader_profile(self):
        self.client.post(
            reverse("accounts:signup"),
            {
                "email": "doc@example.com",
                "password": "studypass123",
                "role": "therapist",
            },
            format="json",
        )
        user = User.objects.get(email="doc@example.com")
        self.assertTrue(user.is_therapist)
        self.assertFalse(hasattr(user, "reader_profile"))

    def test_login_returns_role_and_participant_id(self):
        make_reader("mitu@example.com", "Mitu")
        response = self.client.post(
            reverse("accounts:login"),
            {"email": "mitu@example.com", "password": "studypass123"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["user"]["role"], "reader")
        self.assertTrue(response.data["participant_id"].startswith("P-"))

    def test_wrong_password_is_rejected(self):
        make_reader("mitu@example.com")
        response = self.client.post(
            reverse("accounts:login"),
            {"email": "mitu@example.com", "password": "wrongpassword"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class AvailableReaderTests(APITestCase):
    def setUp(self):
        self.therapist = make_therapist("doc@example.com", "Dr Karim")
        self.other = make_therapist("other@example.com", "Dr Other")
        self.free = make_reader("free@example.com", "Rafi Ahmed")
        self.taken = make_reader("taken@example.com", "Nusrat Jahan")
        self.taken.therapist = self.other
        self.taken.save()
        self.client.force_authenticate(self.therapist)

    def test_lists_only_unclaimed_readers(self):
        response = self.client.get(reverse("readers:available"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        names = [r["display_name"] for r in response.data["results"]]
        self.assertIn("Rafi Ahmed", names)
        self.assertNotIn(
            "Nusrat Jahan", names, "a reader another therapist added must be hidden"
        )

    def test_search_matches_name_and_participant_id(self):
        by_name = self.client.get(reverse("readers:available"), {"search": "rafi"})
        self.assertEqual(len(by_name.data["results"]), 1)

        by_id = self.client.get(
            reverse("readers:available"), {"search": self.free.participant_id}
        )
        self.assertEqual(len(by_id.data["results"]), 1)

        no_match = self.client.get(reverse("readers:available"), {"search": "zzzz"})
        self.assertEqual(len(no_match.data["results"]), 0)

    def test_a_reader_cannot_browse_the_directory(self):
        self.client.force_authenticate(self.free.user)
        response = self.client.get(reverse("readers:available"))
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_anonymous_is_rejected(self):
        self.client.force_authenticate(None)
        response = self.client.get(reverse("readers:available"))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class ClaimTests(APITestCase):
    def setUp(self):
        self.therapist = make_therapist("doc@example.com", "Dr Karim")
        self.rival = make_therapist("rival@example.com", "Dr Rival")
        self.reader = make_reader("rafi@example.com", "Rafi Ahmed")

    def _claim_url(self):
        return reverse("readers:claim", args=[self.reader.participant_id])

    def test_claiming_assigns_and_notifies_the_reader(self):
        self.client.force_authenticate(self.therapist)
        response = self.client.post(self._claim_url())
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.reader.refresh_from_db()
        self.assertEqual(self.reader.therapist, self.therapist)
        self.assertIsNotNone(self.reader.claimed_at)

        note = Notification.objects.get(recipient=self.reader.user)
        self.assertEqual(note.kind, Notification.Kind.THERAPIST_ADDED)
        self.assertIn("Dr Karim", note.body)
        self.assertIsNone(note.read_at)

    def test_a_second_therapist_gets_a_conflict_not_a_silent_takeover(self):
        self.client.force_authenticate(self.therapist)
        self.client.post(self._claim_url())

        self.client.force_authenticate(self.rival)
        response = self.client.post(self._claim_url())

        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)
        self.reader.refresh_from_db()
        self.assertEqual(
            self.reader.therapist, self.therapist, "the first claim must stand"
        )
        self.assertEqual(Notification.objects.count(), 1)

    def test_reclaiming_my_own_reader_is_harmless(self):
        self.client.force_authenticate(self.therapist)
        self.client.post(self._claim_url())
        response = self.client.post(self._claim_url())
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            Notification.objects.count(), 1, "must not notify the reader twice"
        )

    def test_claimed_reader_appears_on_my_roster(self):
        self.client.force_authenticate(self.therapist)
        self.client.post(self._claim_url())
        response = self.client.get(reverse("readers:mine"))
        self.assertEqual(len(response.data["results"]), 1)

    def test_releasing_returns_the_reader_to_the_directory(self):
        self.client.force_authenticate(self.therapist)
        self.client.post(self._claim_url())
        self.client.post(reverse("readers:release", args=[self.reader.participant_id]))

        available = self.client.get(reverse("readers:available"))
        names = [r["display_name"] for r in available.data["results"]]
        self.assertIn("Rafi Ahmed", names)

    def test_therapist_registered_reader_is_claimed_immediately(self):
        self.client.force_authenticate(self.therapist)
        response = self.client.post(
            reverse("readers:mine"),
            {"display_name": "Offline Child", "age": 9},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        created = ReaderProfile.objects.get(display_name="Offline Child")
        self.assertEqual(created.therapist, self.therapist)

        # And is therefore not offered to anyone else.
        self.client.force_authenticate(self.rival)
        available = self.client.get(reverse("readers:available"))
        names = [r["display_name"] for r in available.data["results"]]
        self.assertNotIn("Offline Child", names)


class NotificationTests(APITestCase):
    def setUp(self):
        self.therapist = make_therapist("doc@example.com", "Dr Karim")
        self.reader = make_reader("rafi@example.com", "Rafi")
        self.client.force_authenticate(self.therapist)
        self.client.post(reverse("readers:claim", args=[self.reader.participant_id]))
        self.client.force_authenticate(self.reader.user)

    def test_reader_sees_their_own_notification(self):
        response = self.client.get(reverse("readers:notifications"))
        self.assertEqual(len(response.data["results"]), 1)
        self.assertFalse(response.data["results"][0]["is_read"])

    def test_marking_read(self):
        note_id = self.client.get(reverse("readers:notifications")).data["results"][0][
            "id"
        ]
        response = self.client.post(reverse("readers:notification-read", args=[note_id]))
        self.assertTrue(response.data["is_read"])

        unread = self.client.get(reverse("readers:notifications"), {"unread": "true"})
        self.assertEqual(len(unread.data["results"]), 0)

    def test_a_reader_cannot_see_another_readers_notifications(self):
        other = make_reader("other@example.com", "Other")
        self.client.force_authenticate(other.user)
        response = self.client.get(reverse("readers:notifications"))
        self.assertEqual(len(response.data["results"]), 0)


class MyProfileAndSettingsTests(APITestCase):
    """A reader owns their own profile and settings; nobody else does."""

    def setUp(self):
        self.reader = make_reader("rafi@example.com", "Rafi Ahmed")
        self.client.force_authenticate(self.reader.user)

    def test_reader_reads_their_own_profile(self):
        response = self.client.get(reverse("readers:my-profile"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["display_name"], "Rafi Ahmed")
        self.assertEqual(response.data["participant_id"], self.reader.participant_id)
        self.assertIsNone(response.data["therapist_name"])

    def test_reader_updates_their_own_profile(self):
        response = self.client.patch(
            reverse("readers:my-profile"),
            {"display_name": "Rafi A.", "age": 12, "school": "Shimultoli High"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.reader.refresh_from_db()
        self.assertEqual(self.reader.display_name, "Rafi A.")
        self.assertEqual(self.reader.age, 12)

    def test_participant_id_cannot_be_rewritten(self):
        original = self.reader.participant_id
        self.client.patch(
            reverse("readers:my-profile"),
            {"participant_id": "P-HACKED"},
            format="json",
        )
        self.reader.refresh_from_db()
        self.assertEqual(
            self.reader.participant_id,
            original,
            "the id every data row is keyed on must be immutable",
        )

    def test_settings_start_empty_rather_than_404(self):
        response = self.client.get(reverse("readers:my-settings"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["values"], {})

    def test_settings_round_trip(self):
        values = {"profile": "custom", "font_size": 28.0, "surface": "cream"}
        put = self.client.put(
            reverse("readers:my-settings"), {"values": values}, format="json"
        )
        self.assertEqual(put.status_code, status.HTTP_200_OK)

        got = self.client.get(reverse("readers:my-settings"))
        self.assertEqual(got.data["values"], values)

    def test_settings_are_replaced_not_merged(self):
        self.client.put(
            reverse("readers:my-settings"),
            {"values": {"font_size": 22.0, "surface": "cream"}},
            format="json",
        )
        self.client.put(
            reverse("readers:my-settings"),
            {"values": {"font_size": 40.0}},
            format="json",
        )
        got = self.client.get(reverse("readers:my-settings"))
        self.assertEqual(got.data["values"], {"font_size": 40.0})

    def test_a_non_object_payload_is_rejected(self):
        response = self.client.put(
            reverse("readers:my-settings"), {"values": "nope"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_therapist_can_read_their_own_readers_settings(self):
        self.client.put(
            reverse("readers:my-settings"),
            {"values": {"profile": "recommended"}},
            format="json",
        )
        therapist = make_therapist("doc@example.com", "Dr Karim")
        self.reader.therapist = therapist
        self.reader.save()

        self.client.force_authenticate(therapist)
        response = self.client.get(
            reverse("readers:reader-settings", args=[self.reader.participant_id])
        )
        self.assertEqual(response.data["values"], {"profile": "recommended"})

    def test_another_therapist_cannot(self):
        rival = make_therapist("rival@example.com")
        self.client.force_authenticate(rival)
        response = self.client.get(
            reverse("readers:reader-settings", args=[self.reader.participant_id])
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


class CredentialDisclosureTests(APITestCase):
    """Signing in must not reveal which emails have accounts.

    This database holds children's names, ages and schools. If a wrong password
    and an unknown email produce different answers, anyone can enumerate the
    participant list from the login screen alone.
    """

    def setUp(self):
        cache.clear()
        make_reader("known@example.com", "Known Reader")

    def _login(self, email, password):
        return self.client.post(
            reverse("accounts:login"),
            {"email": email, "password": password},
            format="json",
        )

    def test_unknown_email_and_wrong_password_are_indistinguishable(self):
        unknown = self._login("nobody@example.com", "studypass123")
        wrong = self._login("known@example.com", "wrongpassword")

        self.assertEqual(unknown.status_code, wrong.status_code)
        self.assertEqual(
            unknown.data["detail"],
            wrong.data["detail"],
            "the two failures must not be distinguishable",
        )

    def test_the_message_does_not_mention_the_account(self):
        detail = str(self._login("nobody@example.com", "studypass123").data["detail"])
        lowered = detail.lower()
        # SimpleJWT's default was "No active account found with the given
        # credentials", which answers "is this email registered?".
        self.assertNotIn("no active account", lowered)
        self.assertNotIn("not found", lowered)
        self.assertIn("incorrect", lowered)

    def test_a_correct_sign_in_still_works(self):
        response = self._login("known@example.com", "studypass123")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)


class LoginThrottleTests(APITestCase):
    """A generic message stops someone reading which emails exist; it does not
    stop them guessing. The throttle is what makes guessing impractical."""

    def setUp(self):
        cache.clear()
        make_reader("target@example.com", "Target")

    def test_repeated_failures_are_eventually_refused(self):
        url = reverse("accounts:login")
        saw_throttle = False

        # The configured cap is 20/min; 40 attempts must not all be served.
        for _ in range(40):
            response = self.client.post(
                url,
                {"email": "target@example.com", "password": "wrong"},
                format="json",
            )
            if response.status_code == status.HTTP_429_TOO_MANY_REQUESTS:
                saw_throttle = True
                break

        self.assertTrue(
            saw_throttle,
            "brute-forcing the login was never rate limited",
        )
