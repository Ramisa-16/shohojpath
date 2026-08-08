from django.contrib import admin

from .models import AboutEntry, AccessibilityPoint, AppNotice, Faq, HelpFeature


class OrderedAdmin(admin.ModelAdmin):
    list_editable = ("order", "is_published")
    list_display_links = None


@admin.register(HelpFeature)
class HelpFeatureAdmin(OrderedAdmin):
    list_display = ("name", "icon", "order", "is_published")
    list_display_links = ("name",)
    list_editable = ("order", "is_published")


@admin.register(Faq)
class FaqAdmin(OrderedAdmin):
    list_display = ("question", "order", "is_published")
    list_display_links = ("question",)
    list_editable = ("order", "is_published")


@admin.register(AboutEntry)
class AboutEntryAdmin(OrderedAdmin):
    list_display = ("key", "value", "order", "is_published")
    list_display_links = ("key",)
    list_editable = ("order", "is_published")


@admin.register(AccessibilityPoint)
class AccessibilityPointAdmin(OrderedAdmin):
    list_display = ("text", "order", "is_published")
    list_display_links = ("text",)
    list_editable = ("order", "is_published")


@admin.register(AppNotice)
class AppNoticeAdmin(admin.ModelAdmin):
    list_display = ("key", "title", "updated_at")
    prepopulated_fields = {"key": ("title",)}
