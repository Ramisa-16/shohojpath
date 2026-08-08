from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models
from django.utils.translation import gettext_lazy as _


class UserManager(BaseUserManager):
    """Email-keyed manager.

    Django's default manager insists on a username; this app has none, so the
    creation helpers are rewritten around email.
    """

    use_in_migrations = True

    def _create_user(self, email, password, **extra):
        if not email:
            raise ValueError("An email address is required.")
        email = self.normalize_email(email).lower()
        user = self.model(email=email, **extra)
        # set_password hashes; never assign to user.password directly.
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email, password=None, **extra):
        extra.setdefault("is_staff", False)
        extra.setdefault("is_superuser", False)
        return self._create_user(email, password, **extra)

    def create_superuser(self, email, password=None, **extra):
        extra.setdefault("is_staff", True)
        extra.setdefault("is_superuser", True)
        extra.setdefault("role", User.Role.THERAPIST)
        if extra.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")
        return self._create_user(email, password, **extra)


class User(AbstractUser):
    """A person who can sign in — a reader or a therapist.

    One table for both roles rather than two: they share sign-in, password
    reset and token handling entirely, and the only thing that differs is what
    they are allowed to see. Splitting them would duplicate all of that for no
    gain.
    """

    class Role(models.TextChoices):
        READER = "reader", _("Reader")
        THERAPIST = "therapist", _("Therapist")

    # Removed rather than left unused: a blank unique username column would
    # collide on the second user created without one.
    username = None
    first_name = None
    last_name = None

    email = models.EmailField(_("email address"), unique=True)
    full_name = models.CharField(_("full name"), max_length=120, blank=True)
    role = models.CharField(
        max_length=16,
        choices=Role.choices,
        default=Role.READER,
        db_index=True,
    )

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    objects = UserManager()

    class Meta:
        ordering = ("email",)

    def __str__(self):
        return f"{self.full_name or self.email} ({self.role})"

    @property
    def is_reader(self):
        return self.role == self.Role.READER

    @property
    def is_therapist(self):
        return self.role == self.Role.THERAPIST
