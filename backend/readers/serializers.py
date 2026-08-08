from rest_framework import serializers

from .models import Notification, ReaderNote, ReaderProfile, ReaderSettings


class ReaderProfileSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(source="user.email", read_only=True, default=None)
    is_claimed = serializers.BooleanField(read_only=True)
    therapist_name = serializers.SerializerMethodField()

    class Meta:
        model = ReaderProfile
        fields = (
            "id",
            "participant_id",
            "display_name",
            "email",
            "age",
            "class_grade",
            "school",
            "starting_profile",
            "is_claimed",
            "therapist_name",
            "claimed_at",
            "created_at",
        )
        read_only_fields = ("id", "participant_id", "is_claimed", "claimed_at", "created_at")

    def get_therapist_name(self, obj):
        if obj.therapist_id is None:
            return None
        return obj.therapist.full_name or obj.therapist.email


class ReaderCreateSerializer(serializers.ModelSerializer):
    """A therapist registering a child who has no account of their own.

    The reader is claimed by its creator immediately — someone who registered a
    participant is by definition already working with them, and leaving it
    unclaimed would offer it to every other therapist in the Add Reader list.
    """

    class Meta:
        model = ReaderProfile
        fields = ("display_name", "age", "class_grade", "school", "starting_profile")


class NotificationSerializer(serializers.ModelSerializer):
    is_read = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = ("id", "kind", "title", "body", "created_at", "read_at", "is_read")
        read_only_fields = fields

    def get_is_read(self, obj):
        return obj.read_at is not None


class ReaderNoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReaderNote
        fields = ("id", "text", "created_at")
        read_only_fields = ("id", "created_at")


class MyProfileSerializer(serializers.ModelSerializer):
    """What a reader may change about themselves.

    participant_id and therapist are deliberately absent: a participant must
    not be able to rewrite the id their data is keyed on, nor assign themselves
    to a therapist.
    """

    email = serializers.EmailField(source="user.email", read_only=True, default=None)
    therapist_name = serializers.SerializerMethodField()

    class Meta:
        model = ReaderProfile
        fields = (
            "participant_id",
            "display_name",
            "email",
            "age",
            "class_grade",
            "school",
            "starting_profile",
            "therapist_name",
            "created_at",
        )
        read_only_fields = ("participant_id", "email", "therapist_name", "created_at")

    def get_therapist_name(self, obj):
        if obj.therapist_id is None:
            return None
        return obj.therapist.full_name or obj.therapist.email


class ReaderSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReaderSettings
        fields = ("values", "updated_at")
        read_only_fields = ("updated_at",)
