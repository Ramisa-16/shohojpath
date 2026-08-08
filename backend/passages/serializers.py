from rest_framework import serializers

from .models import Assignment, Bookmark, Passage, PassagePage, QuizQuestion


class PassagePageSerializer(serializers.ModelSerializer):
    paragraphs = serializers.ListField(child=serializers.CharField(), read_only=True)

    class Meta:
        model = PassagePage
        fields = ("order", "paragraphs")


class QuizQuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizQuestion
        fields = ("order", "kind", "prompt", "options", "correct_index")


class PassageSerializer(serializers.ModelSerializer):
    """Shaped to match the Flutter `Passage` model exactly, so the app can
    build one straight from this JSON with no reshaping in between."""

    id = serializers.CharField(source="slug", read_only=True)
    pages = PassagePageSerializer(many=True, read_only=True)
    questions = QuizQuestionSerializer(many=True, read_only=True)
    page_count = serializers.IntegerField(read_only=True)
    word_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Passage
        fields = (
            "id",
            "title",
            "category",
            "difficulty",
            "estimated_minutes",
            "page_count",
            "word_count",
            "pages",
            "questions",
            "updated_at",
        )


class PassageSummarySerializer(serializers.ModelSerializer):
    """The Library list — no page bodies, so a 30-passage library is one small
    response rather than the entire corpus."""

    id = serializers.CharField(source="slug", read_only=True)
    page_count = serializers.IntegerField(read_only=True)
    word_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Passage
        fields = (
            "id",
            "title",
            "category",
            "difficulty",
            "estimated_minutes",
            "page_count",
            "word_count",
            "updated_at",
        )


class BookmarkSerializer(serializers.ModelSerializer):
    passage_id = serializers.SlugRelatedField(
        source="passage", slug_field="slug", queryset=Passage.objects.all()
    )
    passage_title = serializers.CharField(source="passage.title", read_only=True)

    class Meta:
        model = Bookmark
        fields = (
            "id",
            "passage_id",
            "passage_title",
            "page_index",
            "excerpt",
            "created_at",
        )
        read_only_fields = ("id", "created_at")


class AssignmentSerializer(serializers.ModelSerializer):
    passage_id = serializers.SlugRelatedField(
        source="passage", slug_field="slug", queryset=Passage.objects.all()
    )
    passage_title = serializers.CharField(source="passage.title", read_only=True)
    participant_id = serializers.CharField(
        source="reader.participant_id", read_only=True
    )

    class Meta:
        model = Assignment
        fields = (
            "id",
            "passage_id",
            "passage_title",
            "participant_id",
            "profile",
            "assigned_at",
        )
        read_only_fields = ("id", "assigned_at")
