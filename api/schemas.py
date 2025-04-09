from pydantic import BaseModel, EmailStr, Field

class AdoptAreaInput(BaseModel):
    first_name: str = Field(..., max_length=100)
    last_name: str = Field(..., max_length=100)
    email: EmailStr
    note: str = Field('', max_length=500)
    lat: float
    lng: float
    city: str
    state: str
    country: str
