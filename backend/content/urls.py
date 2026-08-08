from django.urls import path

from .views import AppContentView

app_name = "content"

urlpatterns = [
    path("content/", AppContentView.as_view(), name="content"),
]
