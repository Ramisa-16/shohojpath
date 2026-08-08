from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import User
from .serializers import (
    ChangePasswordSerializer,
    LoginSerializer,
    SignUpSerializer,
    UserSerializer,
)


class SignUpView(generics.CreateAPIView):
    """POST /api/auth/signup/ — create a reader or therapist account."""

    serializer_class = SignUpSerializer
    permission_classes = [permissions.AllowAny]
    throttle_scope = "signup"
    queryset = User.objects.all()

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Signed straight in: making someone type the password again
        # immediately after choosing it is friction with no security value.
        refresh = RefreshToken.for_user(user)
        refresh["role"] = user.role
        profile = getattr(user, "reader_profile", None)

        return Response(
            {
                "refresh": str(refresh),
                "access": str(refresh.access_token),
                "user": UserSerializer(user).data,
                "participant_id": profile.participant_id if profile else None,
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(TokenObtainPairView):
    """POST /api/auth/login/ — email + password, returns JWT pair.

    Rate limited: the error message is deliberately identical for a wrong
    password and an unknown email, so guessing is the only way to learn
    anything — and the throttle is what makes guessing impractical.
    """

    serializer_class = LoginSerializer
    permission_classes = [permissions.AllowAny]
    throttle_scope = "login"


class MeView(generics.RetrieveAPIView):
    """GET /api/auth/me/ — who the current token belongs to."""

    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class ChangePasswordView(generics.GenericAPIView):
    serializer_class = ChangePasswordSerializer
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(status=status.HTTP_204_NO_CONTENT)
