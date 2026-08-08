from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import AboutEntry, AccessibilityPoint, AppNotice, Faq, HelpFeature


class SeededContentTests(APITestCase):
    """The migration seeds the copy the app used to hard-code.

    Without it a fresh deploy would serve empty arrays and every reader would
    open a blank Help and About screen — the two places someone goes when they
    are already stuck.
    """

    def test_a_fresh_database_already_has_content(self):
        data = self.client.get(reverse("content:content")).data
        self.assertGreater(len(data["help_features"]), 0)
        self.assertGreater(len(data["faqs"]), 0)
        self.assertGreater(len(data["about"]), 0)
        self.assertGreater(len(data["accessibility"]), 0)

    def test_the_disclaimer_is_present_and_says_what_it_must(self):
        notices = self.client.get(reverse("content:content")).data["notices"]
        self.assertIn("disclaimer", notices)
        body = notices["disclaimer"]["body"]
        self.assertIn("not a diagnostic", body)

    def test_seeded_copy_reflects_the_real_font_range(self):
        # The bundled strings said 12–72 px; the ceiling is 48 now, and the
        # copy a participant reads must not contradict the control they see.
        data = self.client.get(reverse("content:content")).data
        joined = " ".join(
            f["description"] for f in data["help_features"]
        ) + " ".join(data["accessibility"])
        self.assertNotIn("72", joined)
        self.assertIn("48", joined)


class AppContentTests(APITestCase):
    def setUp(self):
        # Cleared so these assertions are about exactly what this test wrote,
        # not what the seed migration happened to leave behind.
        HelpFeature.objects.all().delete()
        Faq.objects.all().delete()
        AboutEntry.objects.all().delete()
        AccessibilityPoint.objects.all().delete()
        AppNotice.objects.all().delete()

        HelpFeature.objects.create(
            order=2, icon="spellcheck", name="Conjunct support", description="…"
        )
        HelpFeature.objects.create(
            order=1, icon="volume_up", name="Read aloud", description="…"
        )
        HelpFeature.objects.create(
            order=3, name="Hidden", description="…", is_published=False
        )
        Faq.objects.create(order=1, question="Why does read aloud matter?")
        AboutEntry.objects.create(order=1, key="Researcher", value="Mitu Rahman")
        AccessibilityPoint.objects.create(order=1, text="WCAG AA contrast")
        AppNotice.objects.create(
            key="disclaimer", title="Disclaimer", body="Not a diagnostic tool."
        )

    def test_content_is_readable_without_signing_in(self):
        # The Help and About screens are reachable before login in the design.
        response = self.client.get(reverse("content:content"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_ordering_is_respected_and_unpublished_hidden(self):
        data = self.client.get(reverse("content:content")).data
        names = [f["name"] for f in data["help_features"]]
        self.assertEqual(names, ["Read aloud", "Conjunct support"])
        self.assertNotIn("Hidden", names)

    def test_all_sections_present(self):
        data = self.client.get(reverse("content:content")).data
        self.assertEqual(data["faqs"][0]["question"], "Why does read aloud matter?")
        self.assertEqual(data["about"][0]["key"], "Researcher")
        self.assertEqual(data["accessibility"], ["WCAG AA contrast"])
        self.assertEqual(data["notices"]["disclaimer"]["title"], "Disclaimer")
