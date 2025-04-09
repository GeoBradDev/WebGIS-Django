from django.http import JsonResponse
from ninja import NinjaAPI

api = NinjaAPI(
    csrf=False,
    title="Django WebGIS API",
    description="Endpoints for user authentication, registration, and password management."
)

