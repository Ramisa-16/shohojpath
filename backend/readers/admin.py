from django.contrib import admin
from django.utils import timezone

from .models import Notification, ReaderNote, ReaderProfile, ReaderSettings


class ReaderNoteInline(admin.TabularInline):
    model = ReaderNote
    extra = 0
    readonly_fields = ("created_at",)


@admin.register(ReaderProfile)
class ReaderProfileAdmin(admin.ModelAdmin):
    list_display = (
        "display_name",
        "participant_id",
        "age",
        "school",
        "therapist",
        "claimed_at",
    )
    list_filter = ("therapist", "starting_profile", "class_grade")
    search_fields = ("display_name", "participant_id", "school", "user__email")
    readonly_fields = ("participant_id", "created_at", "claimed_at")
    inlines = [ReaderNoteInline]
    actions = ["release_readers"]

    @admin.action(description="Release selected readers (make available again)")
    def release_readers(self, request, queryset):
        count = queryset.update(therapist=None, claimed_at=None)
        self.message_user(request, f"{count} reader(s) returned to the available list.")


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("title", "recipient", "kind", "created_at", "read_at")
    list_filter = ("kind", "read_at")
    search_fields = ("title", "body", "recipient__email")
    readonly_fields = ("created_at",)
    actions = ["mark_read"]

    @admin.action(description="Mark selected as read")
    def mark_read(self, request, queryset):
        queryset.filter(read_at__isnull=True).update(read_at=timezone.now())


@admin.register(ReaderSettings)
class ReaderSettingsAdmin(admin.ModelAdmin):
    """Read-only: this mirrors what the device holds. Editing it here would
    not reach the handset, so a change would look applied but do nothing."""

    list_display = ("reader", "updated_at")
    search_fields = ("reader__display_name", "reader__participant_id")
    readonly_fields = ("reader", "values", "updated_at")

    def has_add_permission(self, request):
        return False
