from django.db import models
from django.conf import settings
from django.contrib.auth.models import AbstractUser, UserManager


class CustomUserManager(UserManager):
    def get_by_natural_key(self, email):
        return self.get(email__iexact=email)


class CustomUser(AbstractUser):
    email = models.EmailField(unique=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    objects = CustomUserManager()  # Use the custom manager

    def __str__(self):
        return self.email.lower()  # Store and return email in lowercase

    def save(self, *args, **kwargs):
        self.email = self.email.lower()  # Ensure email is always stored in lowercase
        super().save(*args, **kwargs)


class AdoptedArea(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="adopted_areas"
    )
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField()
    note = models.TextField(blank=True)
    lat = models.FloatField()
    lng = models.FloatField()
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    country = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)
