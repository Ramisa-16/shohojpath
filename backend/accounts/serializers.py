from django.contrib.auth import password_validation
from django.utils.translation import gettext_lazy as _
from django.db import transaction
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from readers.models import ReaderProfile

from .models import User


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "email", "full_name", "role")
        read_only_fields = fields


class SignUpSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8, trim_whitespace=False)

    # Reader-only, all optional: a reader signing themselves up on a phone
    # should not be blocked by fields a therapist will fill in later.
    age = serializers.IntegerField(required=False, allow_null=True, min_value=3, max_value=120)
    class_grade = serializers.CharField(required=False, allow_blank=True, max_length=40)
    school = serializers.CharField(required=False, allow_blank=True, max_length=160)

    class Meta:
        model = User
        fields = ("email", "password", "full_name", "role", "age", "class_grade", "school")

    def validate_email(self, value):
        email = value.strip().lower()
        if User.objects.filter(email__iexact=email).exists():
            raise serializers.ValidationError("An account with this email already exists.")
        return email

    def validate_password(self, value):
        # Runs Django's configured validators, so the rules stay in settings
        # rather than being restated here.
        password_validation.validate_password(value)
        return value

    @transaction.atomic
    def create(self, validated):
        profile_fields = {
            "age": validated.pop("age", None),
            "class_grade": validated.pop("class_grade", "") or "",
            "school": validated.pop("school", "") or "",
        }
        password = validated.pop("password")
        user = User.objects.create_user(password=password, **validated)

        # Every reader gets a profile at signup, which is what makes them
        # visible to therapists in the unclaimed list.
        if user.is_reader:
            ReaderProfile.objects.create(
                user=user,
                display_name=user.full_name or user.email.split("@")[0],
                **profile_fields,
            )
        return user


class LoginSerializer(TokenObtainPairSerializer):
    """Adds the signed-in user to the token response.

    Without this the app would have to make a second call to /auth/me/ purely
    to find out whether it just signed in a reader or a therapist, which is the
    one thing it needs before it can pick a screen.
    """

    # SimpleJWT's default is "No active account found with the given
    # credentials", which tells an attacker whether an email is registered.
    # That is account enumeration, and this database holds children's names and
    # schools — a wrong password and an unknown email must be indistinguishable.
    default_error_messages = {
        "no_active_account": _("Email or password is incorrect."),
    }

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["role"] = user.role
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        data["user"] = UserSerializer(self.user).data
        if self.user.is_reader:
            profile = getattr(self.user, "reader_profile", None)
            data["participant_id"] = profile.participant_id if profile else None
        return data


class ChangePasswordSerializer(serializers.Serializer):
    current_password = serializers.CharField(write_only=True, trim_whitespace=False)
    new_password = serializers.CharField(write_only=True, min_length=8, trim_whitespace=False)

    def validate_current_password(self, value):
        if not self.context["request"].user.check_password(value):
            raise serializers.ValidationError("Current password is incorrect.")
        return value

    def validate_new_password(self, value):
        password_validation.validate_password(value, self.context["request"].user)
        return value

    def save(self, **kwargs):
        user = self.context["request"].user
        user.set_password(self.validated_data["new_password"])
        user.save(update_fields=["password"])
        return user
