from django.db import migrations

# The copy the app shipped with, moved into the database so a researcher can
# reword it — for an ethics board, say — without a new build. Seeded rather
# than left empty: a fresh deploy must not give participants a blank Help and
# About screen.

HELP_FEATURES = [
    ("volume_up", "Read aloud", "Bangla text-to-speech with word-by-word highlighting."),
    ("spellcheck", "Conjunct support", "Highlight or split যুক্তাক্ষর to reveal the spelling."),
    ("format_size", "Font & size control", "Four Bangla typefaces, 12–48 px."),
    ("format_line_spacing", "Spacing control", "Word, line and paragraph spacing."),
    ("straighten", "Reading ruler", "A guide bar that follows the line you read."),
    ("bookmark", "Bookmarks & progress", "Resume exactly where you stopped."),
]

FAQS = [
    (
        "Why does read aloud matter more than the font?",
        "Dyslexia is a phonological difficulty — hearing the words addresses it "
        "directly. Research has not shown that any single typeface improves "
        "reading accuracy, so font choice is offered as a comfort preference.",
    ),
    (
        "Can I use the app without an account?",
        "Yes. Continue as Guest keeps everything on this device. Nothing is "
        "uploaded and a therapist cannot see it.",
    ),
    (
        "Where is my reading data stored?",
        "On this device first. If you are signed in, completed sessions are "
        "also synced to the research server so your therapist can see your "
        "progress.",
    ),
]

ABOUT = [
    ("University", "Department of CSE"),
    ("Researcher", "—"),
    ("Supervisor", "—"),
    ("Version", "1.0 (2026)"),
]

ACCESSIBILITY = [
    "WCAG AA contrast on all text",
    "14 px minimum text size",
    'Screen reader support with lang="bn"',
    "Text-to-speech with word tracking",
    "12–48 px scalable typography",
    "Conjunct decomposition (যুক্তাক্ষর)",
]

NOTICES = [
    (
        "help_intro",
        "How to use Shohojpath",
        "Pick a passage from the Library, then tap the settings button while "
        "reading. Start with Read Aloud — it helps most. Adjust spacing and "
        "theme until the text feels comfortable. Your choices are saved "
        "automatically.",
    ),
    (
        "disclaimer",
        "Disclaimer",
        "This application is a reading support tool. It is not a diagnostic or "
        "therapeutic instrument and does not replace assessment or instruction "
        "by qualified professionals.",
    ),
    (
        "research_title",
        "Research title",
        "Design and Evaluation of a Dyslexia-Friendly Bangla Reading Interface "
        "Using Human-Centered Design Principles",
    ),
]


def seed(apps, schema_editor):
    HelpFeature = apps.get_model("content", "HelpFeature")
    Faq = apps.get_model("content", "Faq")
    AboutEntry = apps.get_model("content", "AboutEntry")
    AccessibilityPoint = apps.get_model("content", "AccessibilityPoint")
    AppNotice = apps.get_model("content", "AppNotice")

    for order, (icon, name, description) in enumerate(HELP_FEATURES, start=1):
        HelpFeature.objects.get_or_create(
            name=name,
            defaults={"icon": icon, "description": description, "order": order},
        )

    for order, (question, answer) in enumerate(FAQS, start=1):
        Faq.objects.get_or_create(
            question=question, defaults={"answer": answer, "order": order}
        )

    for order, (key, value) in enumerate(ABOUT, start=1):
        AboutEntry.objects.get_or_create(
            key=key, defaults={"value": value, "order": order}
        )

    for order, text in enumerate(ACCESSIBILITY, start=1):
        AccessibilityPoint.objects.get_or_create(
            text=text, defaults={"order": order}
        )

    for key, title, body in NOTICES:
        AppNotice.objects.get_or_create(
            key=key, defaults={"title": title, "body": body}
        )


def unseed(apps, schema_editor):
    # Deliberately a no-op: reversing this migration must not delete copy the
    # researcher has since edited in the admin.
    pass


class Migration(migrations.Migration):
    dependencies = [("content", "0001_initial")]
    operations = [migrations.RunPython(seed, unseed)]
