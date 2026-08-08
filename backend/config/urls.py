from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path


def health(_request):
    """Cheap endpoint for the app to probe before syncing, and for a keep-warm
    ping — free hosts sleep after a few idle minutes, and this is what wakes
    them without touching the database."""
    return JsonResponse({"status": "ok", "service": "shohojpath"})


admin.site.site_header = "Shohojpath research admin"
admin.site.site_title = "Shohojpath"
admin.site.index_title = "Study data & content"

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/", health, name="health"),
    path("api/auth/", include("accounts.urls")),
    path("api/", include("readers.urls")),
    path("api/", include("passages.urls")),
    path("api/", include("sync.urls")),
    path("api/", include("content.urls")),
]
