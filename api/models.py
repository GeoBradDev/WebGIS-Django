from django.db import models
from django.contrib.auth.models import AbstractUser, UserManager
from django.contrib.gis.db import models


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


class DemoPolygon(models.Model):
    name = models.CharField(max_length=255)
    geom = models.PolygonField(srid=4326)

    def __str__(self):
        return self.name


class DemoPoint(models.Model):
    name = models.CharField(max_length=255)
    geom = models.PointField(srid=4326)

    def __str__(self):
        return self.name


class DemoLine(models.Model):
    name = models.CharField(max_length=255)
    geom = models.LineStringField(srid=4326)

    def __str__(self):
        return self.name
