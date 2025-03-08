from django.views.decorators.csrf import csrf_exempt
from ninja import NinjaAPI
from ninja.security import django_auth
from django.contrib.auth import authenticate, login, logout
from django.middleware.csrf import get_token
from django.http import JsonResponse
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.core.mail import send_mail

from .models import CustomUser as User
from . import schemas
from .schemas import RegisterSchema, LoginSchema, ForgotPasswordSchema, ResetPasswordSchema

# Initialize API with CSRF protection
api = NinjaAPI(
    csrf=True,
    title="Django WebGIS API",
    description="Endpoints for user authentication, registration, and password management."
)


def generate_response(success: bool, message: str, status: int = 200, **kwargs):
    """Utility function to format JSON responses."""
    return JsonResponse({"success": success, "message": message, **kwargs}, status=status)


@api.get("/set-csrf-token", tags=["CSRF"])
def get_csrf_token(request):
    """Retrieve and set CSRF token for frontend security."""
    csrf_token = get_token(request)
    response = generate_response(True, "CSRF token set successfully.", csrftoken=csrf_token)
    response.set_cookie("csrftoken", csrf_token, httponly=False, secure=False, samesite="Lax")
    return response


@api.post("/login", tags=["Authentication"], description="Authenticate and log in a user.")
def login_user(request, payload: LoginSchema):
    """Logs in a user with valid email and password."""
    try:
        user = User.objects.get(email__iexact=payload.email)
    except User.DoesNotExist:
        return generate_response(False, "Invalid email or password", status=401)

    if not user.check_password(payload.password):
        return generate_response(False, "Invalid email or password", status=401)

    login(request, user)
    request.session.save()
    return generate_response(True, "Login successful", user={"username": user.username, "email": user.email})


@api.post("/logout", tags=["Authentication"], description="Log out the current user.")
def logout_user(request):
    """Logs out the authenticated user and clears session cookies."""
    logout(request)
    request.session.flush()
    response = generate_response(True, "Logged out successfully")
    response.delete_cookie("sessionid")
    response.delete_cookie("csrftoken")
    return response


@api.get("/user", auth=django_auth, tags=["User"], description="Get details of the authenticated user.")
def get_user(request):
    """Retrieve information about the logged-in user."""
    if not request.user.is_authenticated:
        return generate_response(False, "Not authenticated", status=401)
    return generate_response(True, "User details retrieved",
                             user={"username": request.user.username, "email": request.user.email})


@api.post("/register", tags=["Authentication"], description="Register a new user.")
def register_user(request, payload: RegisterSchema):
    """Creates a new user account."""
    email = payload.email.lower()
    if User.objects.filter(email=email).exists():
        return generate_response(False, "This email is already registered. Please log in or reset your password.",
                                 status=400)

    user = User.objects.create_user(
        email=email,
        username=email,
        first_name=payload.first_name,
        last_name=payload.last_name,
        password=payload.password
    )

    # Send confirmation email
    subject = "Welcome to Our Platform"
    message = f"Hello {payload.first_name},\n\nThank you for registering. Your account has been successfully created."
    send_mail(subject, message, "noreply@yourdomain.com", [payload.email])

    return generate_response(True, "User registered successfully. A confirmation email has been sent.")


@api.post("/forgot-password", tags=["Password Reset"], description="Send a password reset email.")
@csrf_exempt
def forgot_password(request, payload: ForgotPasswordSchema):
    """Sends an email with a password reset link if the email exists in the system."""
    try:
        user = User.objects.get(email=payload.email)
    except User.DoesNotExist:
        return generate_response(True, "If the email is registered, a password reset email has been sent.")

    token = default_token_generator.make_token(user)
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    reset_link = f"https://yourfrontend.com/reset-password?uid={uid}&token={token}"

    send_mail(
        subject="Password Reset Request",
        message=f"Click the link to reset your password: {reset_link}",
        from_email="noreply@yourdomain.com",
        recipient_list=[user.email],
        fail_silently=False,
    )
    return generate_response(True, "If the email is registered, a password reset email has been sent.")


@api.post("/reset-password", tags=["Password Reset"], description="Reset a user's password using a token.")
def reset_password(request, payload: ResetPasswordSchema):
    """Allows users to reset their password with a valid token."""
    try:
        uid = force_str(urlsafe_base64_decode(payload.uid))
        user = User.objects.get(pk=uid)
    except (TypeError, ValueError, OverflowError, User.DoesNotExist):
        return generate_response(False, "Invalid UID", status=400)

    if not default_token_generator.check_token(user, payload.token):
        return generate_response(False, "Invalid or expired token", status=400)

    user.set_password(payload.new_password)
    user.save()
    return generate_response(True, "Password reset successfully.")
