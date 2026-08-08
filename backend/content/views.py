from rest_framework import permissions
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import AboutEntry, AccessibilityPoint, AppNotice, Faq, HelpFeature


class AppContentView(APIView):
    """GET /api/content/ — every editable copy block in one response.

    One request rather than five: this is a few dozen short strings, and the
    Help and About screens should not each wait on their own round trip to a
    host that may be waking from sleep.
    """

    permission_classes = [permissions.AllowAny]

    def get(self, request):
        return Response(
            {
                "help_features": [
                    {
                        "icon": f.icon,
                        "name": f.name,
                        "description": f.description,
                    }
                    for f in HelpFeature.objects.filter(is_published=True)
                ],
                "faqs": [
                    {"question": f.question, "answer": f.answer}
                    for f in Faq.objects.filter(is_published=True)
                ],
                "about": [
                    {"key": a.key, "value": a.value}
                    for a in AboutEntry.objects.filter(is_published=True)
                ],
                "accessibility": [
                    p.text for p in AccessibilityPoint.objects.filter(is_published=True)
                ],
                "notices": {
                    n.key: {"title": n.title, "body": n.body}
                    for n in AppNotice.objects.all()
                },
            }
        )
