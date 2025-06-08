from ninja import Schema

# GeoJSON as string — for now (simple approach)
class PolygonIn(Schema):
    name: str
    geojson: str

class PolygonOut(Schema):
    id: int
    name: str
    geojson: str

class PointIn(Schema):
    name: str
    lng: float
    lat: float

class PointOut(Schema):
    id: int
    name: str
    lng: float
    lat: float

class LineIn(Schema):
    name: str
    geojson: str

class LineOut(Schema):
    id: int
    name: str
    geojson: str
