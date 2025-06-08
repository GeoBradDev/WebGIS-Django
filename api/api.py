from django.contrib.gis.geos import Polygon, Point, LineString, GEOSGeometry
from django.contrib.gis.db.models.functions import AsGeoJSON, Area, Distance, Centroid
from django.http import JsonResponse
from ninja import NinjaAPI, Schema
from api.models import DemoPoint, DemoPolygon, DemoLine
from .schemas import PolygonIn, PolygonOut, PointIn, PointOut, LineIn, LineOut

api = NinjaAPI(
    csrf=False,
    title="Django WebGIS API Template",
    description="""
A boilerplate WebGIS API demonstrating common geospatial capabilities using GeoDjango and PostGIS.

This template provides a starting point for building full-featured WebGIS applications with a RESTful API.

Included examples:

- Query features in GeoJSON format
- Bounding box filtering
- Buffer queries (distance-based selection)
- Area calculation for polygon features
- Spatial joins (points within polygons)
- Nearest neighbor search
- Geometry simplification
- Centroid calculation
- Geometric intersection
- Geometric difference
- Geometric union

This API is designed to be easily cloned and adapted for your own WebGIS projects.

Built with:
- Django
- Django Ninja
- GeoDjango
- PostGIS
""",
    version="0.2.0"
)


# --- Polygon Features ---

@api.get("/polygons", tags=["Polygons"])
def list_polygons(request):
    """Return all polygons as GeoJSON."""
    polygons = DemoPolygon.objects.annotate(geojson=AsGeoJSON('geom')).values('id', 'name', 'geojson')
    return {"polygons": list(polygons)}


@api.get("/polygons_in_bbox", tags=["Polygons"])
def polygons_in_bbox(request, minx: float, miny: float, maxx: float, maxy: float):
    """Return polygons within a bounding box."""
    bbox = Polygon.from_bbox((minx, miny, maxx, maxy))
    polygons = DemoPolygon.objects.filter(geom__intersects=bbox).annotate(geojson=AsGeoJSON('geom')).values('id',
                                                                                                            'name',
                                                                                                            'geojson')
    return {"polygons": list(polygons)}


@api.get("/polygon_areas", tags=["Polygons"])
def polygon_areas(request):
    """Return area of polygons."""
    polygons = DemoPolygon.objects.annotate(area=Area('geom')).values('id', 'name', 'area')
    return {"polygons": list(polygons)}


@api.get("/simplify_polygons", tags=["Polygons"])
def simplify_polygons(request, tolerance: float = 0.001):
    """Return simplified polygon geometries."""
    polygons = DemoPolygon.objects.all()
    simplified = []
    for poly in polygons:
        simplified_geom = poly.geom.simplify(tolerance, preserve_topology=True)
        simplified.append({
            "id": poly.id,
            "name": poly.name,
            "geojson": simplified_geom.geojson
        })
    return {"polygons": simplified}


@api.get("/polygon_centroids", tags=["Polygons"])
def polygon_centroids(request):
    """Return centroid of polygons."""
    polygons = DemoPolygon.objects.annotate(centroid=Centroid('geom')).annotate(geojson=AsGeoJSON('centroid')).values(
        'id', 'name', 'geojson')
    return {"polygons": list(polygons)}


@api.post("/polygons", response=PolygonOut, tags=["Polygons"])
def create_polygon(request, payload: PolygonIn):
    geom = GEOSGeometry(payload.geojson)
    polygon = DemoPolygon.objects.create(name=payload.name, geom=geom)
    return PolygonOut(id=polygon.id, name=polygon.name, geojson=polygon.geom.geojson)


@api.get("/polygons/{polygon_id}", response=PolygonOut, tags=["Polygons"])
def get_polygon(request, polygon_id: int):
    polygon = DemoPolygon.objects.get(id=polygon_id)
    return PolygonOut(id=polygon.id, name=polygon.name, geojson=polygon.geom.geojson)


@api.put("/polygons/{polygon_id}", response=PolygonOut, tags=["Polygons"])
def update_polygon(request, polygon_id: int, payload: PolygonIn):
    polygon = DemoPolygon.objects.get(id=polygon_id)
    polygon.name = payload.name
    polygon.geom = GEOSGeometry(payload.geojson)
    polygon.save()
    return PolygonOut(id=polygon.id, name=polygon.name, geojson=polygon.geom.geojson)


@api.delete("/polygons/{polygon_id}", tags=["Polygons"])
def delete_polygon(request, polygon_id: int):
    DemoPolygon.objects.filter(id=polygon_id).delete()
    return {"success": True}


# --- Point Features ---

@api.get("/points", tags=["Points"])
def list_points(request):
    """Return all points as GeoJSON."""
    points = DemoPoint.objects.annotate(geojson=AsGeoJSON('geom')).values('id', 'name', 'geojson')
    return {"points": list(points)}


@api.get("/points_near", tags=["Points"])
def points_near(request, lng: float, lat: float, radius_meters: float):
    """Return points within X meters of a point."""
    point = Point(lng, lat, srid=4326)
    points = DemoPoint.objects.filter(geom__distance_lte=(point, radius_meters)).annotate(
        geojson=AsGeoJSON('geom')).values('id', 'name', 'geojson')
    return {"points": list(points)}


# Create Point
@api.post("/points", response=PointOut, tags=["Points"])
def create_point(request, payload: PointIn):
    point = DemoPoint.objects.create(
        name=payload.name,
        geom=Point(payload.lng, payload.lat)
    )
    return PointOut(id=point.id, name=point.name, lng=point.geom.x, lat=point.geom.y)


# Read Point by ID
@api.get("/points/{point_id}", response=PointOut, tags=["Points"])
def get_point(request, point_id: int):
    point = DemoPoint.objects.get(id=point_id)
    return PointOut(id=point.id, name=point.name, lng=point.geom.x, lat=point.geom.y)


# Update Point
@api.put("/points/{point_id}", response=PointOut, tags=["Points"])
def update_point(request, point_id: int, payload: PointIn):
    point = DemoPoint.objects.get(id=point_id)
    point.name = payload.name
    point.geom = Point(payload.lng, payload.lat)
    point.save()
    return PointOut(id=point.id, name=point.name, lng=point.geom.x, lat=point.geom.y)


# Delete Point
@api.delete("/points/{point_id}", tags=["Points"])
def delete_point(request, point_id: int):
    DemoPoint.objects.filter(id=point_id).delete()
    return {"success": True}


# --- Line Features ---
@api.post("/lines", response=LineOut, tags=["Lines"])
def create_line(request, payload: LineIn):
    geom = GEOSGeometry(payload.geojson)
    line = DemoLine.objects.create(name=payload.name, geom=geom)
    return LineOut(id=line.id, name=line.name, geojson=line.geom.geojson)


@api.get("/lines/{line_id}", response=LineOut, tags=["Lines"])
def get_line(request, line_id: int):
    line = DemoLine.objects.get(id=line_id)
    return LineOut(id=line.id, name=line.name, geojson=line.geom.geojson)


@api.put("/lines/{line_id}", response=LineOut, tags=["Lines"])
def update_line(request, line_id: int, payload: LineIn):
    line = DemoLine.objects.get(id=line_id)
    line.name = payload.name
    line.geom = GEOSGeometry(payload.geojson)
    line.save()
    return LineOut(id=line.id, name=line.name, geojson=line.geom.geojson)


@api.delete("/lines/{line_id}", tags=["Lines"])
def delete_line(request, line_id: int):
    DemoLine.objects.filter(id=line_id).delete()
    return {"success": True}


# --- Spatial Join ---

@api.get("/points_in_polygon/{polygon_id}", tags=["Spatial Join"])
def points_in_polygon(request, polygon_id: int):
    """Return points within a polygon."""
    try:
        polygon = DemoPolygon.objects.get(id=polygon_id)
    except DemoPolygon.DoesNotExist:
        return JsonResponse({"error": "Polygon not found"}, status=404)

    points = DemoPoint.objects.filter(geom__within=polygon.geom).annotate(geojson=AsGeoJSON('geom')).values('id',
                                                                                                            'name',
                                                                                                            'geojson')
    return {"points": list(points)}


# --- Nearest Neighbor ---

@api.get("/nearest_point", tags=["Nearest Neighbor"])
def nearest_point(request, lng: float, lat: float):
    """Return the nearest point to a location."""
    point = Point(lng, lat, srid=4326)
    nearest = DemoPoint.objects.annotate(distance=Distance('geom', point)).order_by('distance').first()

    if nearest:
        return {
            "id": nearest.id,
            "name": nearest.name,
            "distance_meters": nearest.distance.m,
        }
    return {"error": "No points found"}


# --- Geometry Operations ---

@api.get("/intersection/{poly1_id}/{poly2_id}", tags=["Geometry Operations"])
def intersection(request, poly1_id: int, poly2_id: int):
    """Return the intersection of two polygons."""
    try:
        poly1 = DemoPolygon.objects.get(id=poly1_id)
        poly2 = DemoPolygon.objects.get(id=poly2_id)
    except DemoPolygon.DoesNotExist:
        return JsonResponse({"error": "One or both polygons not found"}, status=404)

    intersection = poly1.geom.intersection(poly2.geom)
    if not intersection.empty:
        return {"intersection_geojson": intersection.geojson}
    return {"intersection_geojson": None}


@api.get("/difference/{poly1_id}/{poly2_id}", tags=["Geometry Operations"])
def difference(request, poly1_id: int, poly2_id: int):
    """Return the difference of polygon 1 minus polygon 2."""
    try:
        poly1 = DemoPolygon.objects.get(id=poly1_id)
        poly2 = DemoPolygon.objects.get(id=poly2_id)
    except DemoPolygon.DoesNotExist:
        return JsonResponse({"error": "One or both polygons not found"}, status=404)

    difference = poly1.geom.difference(poly2.geom)
    if not difference.empty:
        return {"difference_geojson": difference.geojson}
    return {"difference_geojson": None}


@api.get("/union_all_polygons", tags=["Geometry Operations"])
def union_all_polygons(request):
    """Return the union of all polygons."""
    polygons = DemoPolygon.objects.all()
    if polygons.exists():
        union_geom = polygons.first().geom
        for poly in polygons[1:]:
            union_geom = union_geom.union(poly.geom)
        return {"union_geojson": union_geom.geojson}
    return {"union_geojson": None}


@api.get("/buffer_polygon/{polygon_id}", tags=["Geometry Operations"])
def buffer_polygon(request, polygon_id: int, buffer_meters: float):
    """Return buffered geometry of polygon."""
    try:
        polygon = DemoPolygon.objects.get(id=polygon_id)
    except DemoPolygon.DoesNotExist:
        return JsonResponse({"error": "Polygon not found"}, status=404)

    buffer = polygon.geom.buffer(buffer_meters)
    return {"buffer_geojson": buffer.geojson}
