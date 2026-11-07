"""Download the Overture Maps extracts that alabama.py reads -> data/al/

- overture_al_bbox.parquet     every place in Alabama's bounding box (name, category, address, point)
- overture_al_sources.parquet  which datasets each Alabama eating/drinking listing came from (Meta, Foursquare, ...)
- al_shapes.json               simplified state and county outlines for the map
- al_state_detail.geojson      the state outline at full detail, for the in-state test

Reads the public Overture bucket over S3 with DuckDB (no account needed). Ported from wy-eats/pipeline/fetch_overture.py.
Alabama: land division areas (so Mobile Bay and the Gulf are out); the "counties" are its 67. The script checks the towns on and near
its lines (Phenix City across from Columbus, Lanett across from West Point, Florala, Ardmore, the Gulf beaches by Perdido Key) so a
Georgia, Florida, Tennessee or Mississippi listing stays out.
"""
import os, json, time
import duckdb
from shapely import wkb
from shapely.geometry import mapping, Polygon

RELEASE = "2026-10-21.0"
OUT = os.path.join(os.path.dirname(__file__), "..", "data", "al")
# Alabama (30.14°N–35.01°N, 84.89°W–88.47°W) plus a margin for the border towns
BBOX = "bbox.xmin BETWEEN -88.6 AND -84.75 AND bbox.ymin BETWEEN 30.1 AND 35.1"
EAT = "('restaurant','casual_eatery','bar','fast_food_restaurant','coffee_shop','cafe','smoothie_juice_bar','brewery','food_court')"
os.makedirs(OUT, exist_ok=True)

con = duckdb.connect()
con.execute("INSTALL httpfs; LOAD httpfs; INSTALL spatial; LOAD spatial; SET s3_region='us-west-2';")
places = f"s3://overturemaps-us-west-2/release/{RELEASE}/theme=places/type=place/*.parquet"

t = time.time()
if not os.path.exists(f"{OUT}/overture_al_bbox.parquet"):
    con.execute(f"""
COPY (
  SELECT id, names.primary AS name, basic_category AS cat, taxonomy.primary AS tax, taxonomy.hierarchy AS hier, confidence,
         operating_status AS status, brand.names.primary AS brand, addresses[1].freeform AS street, addresses[1].locality AS city,
         addresses[1].postcode AS zip, addresses[1].region AS region, ST_Y(geometry) AS lat, ST_X(geometry) AS lon, websites[1] AS web,
         phones[1] AS phone
  FROM read_parquet('{places}', hive_partitioning=1) WHERE {BBOX}
) TO '{OUT}/overture_al_bbox.parquet' (FORMAT PARQUET)""")
    print("places in bbox", round(time.time() - t), "s", flush=True)
if not os.path.exists(f"{OUT}/overture_al_sources.parquet"):
    con.execute(f"""
COPY (
  SELECT id, list_transform(sources, lambda x: x.dataset) AS ds, list_transform(sources, lambda x: x.update_time) AS ut,
         list_transform(sources, lambda x: x.record_id) AS rid,
         len(socials) AS n_soc, len(websites) AS n_web, len(phones) AS n_ph
  FROM read_parquet('{places}', hive_partitioning=1)
  WHERE {BBOX} AND basic_category IN {EAT}
) TO '{OUT}/overture_al_sources.parquet' (FORMAT PARQUET)""")
    print("sources", round(time.time() - t), "s", flush=True)

areas = f"s3://overturemaps-us-west-2/release/{RELEASE}/theme=divisions/type=division_area/*.parquet"
rows = con.execute(f"""
  SELECT subtype, names.primary AS name, ST_AsWKB(geometry) AS g
  FROM read_parquet('{areas}', hive_partitioning=1)
  WHERE country = 'US' AND region = 'US-AL' AND subtype IN ('region', 'county') AND class = 'land'
    AND bbox.xmin > -88.7 AND bbox.xmax < -84.7 AND bbox.ymin > 29.9 AND bbox.ymax < 35.2""").fetchall()


def rings(geom, tol, min_area):
    geom = geom.simplify(tol, preserve_topology=True)
    polys = [p for p in getattr(geom, "geoms", [geom]) if p.geom_type == "Polygon" and p.area >= min_area]
    return [[[round(x, 3), round(y, 3)] for x, y in p.exterior.coords] for p in polys]


out = {"state": None, "counties": []}
for sub, name, g in rows:
    geom = wkb.loads(bytes(g)).buffer(0)
    if sub == "region":
        json.dump(mapping(geom.simplify(0.0005, preserve_topology=True)), open(f"{OUT}/al_state_detail.geojson", "w"))
        out["state"] = [[r] for r in rings(geom, 0.002, 0.000005)]
    else:
        out["counties"].append({"name": name, "c": rings(geom, 0.004, 0.00002)})
# full-detail county polygons for assigning each place to a county (not shipped)
json.dump({name: mapping(wkb.loads(bytes(g)).buffer(0).simplify(0.0003, preserve_topology=True))
           for sub, name, g in rows if sub == "county"}, open(f"{OUT}/al_counties_detail.geojson", "w"))
json.dump(out, open(f"{OUT}/al_shapes.json", "w"), separators=(",", ":"))
print("outlines: state", len(out["state"] or []), "rings +", len(out["counties"]), "counties;", round(time.time() - t), "s total")
# border towns: each must fall on the right side of the detailed state outline
from shapely.geometry import shape, Point
st = shape(json.load(open(f"{OUT}/al_state_detail.geojson")))
for nm, lon, lat, want in [("Phenix City", -85.0008, 32.4709, True), ("Lanett", -85.1905, 32.8687, True), ("Florala", -86.3283, 31.0052, True),
                           ("Ardmore, AL", -86.8467, 34.9905, True), ("Dauphin Island", -88.1100, 30.2552, True), ("Orange Beach", -87.5866, 30.2697, True),
                           ("Bridgeport", -85.7144, 34.9476, True), ("Cottonwood", -85.3040, 31.0499, True), ("Columbus, GA", -84.9877, 32.4610, False),
                           ("West Point, GA", -85.1833, 32.8779, False), ("Paxton, FL", -86.3083, 30.9827, False), ("Perdido Key, FL", -87.4500, 30.2900, False),
                           ("Pensacola, FL", -87.2169, 30.4213, False), ("Meridian, MS", -88.7037, 32.3643, False), ("Ardmore, TN", -86.8475, 35.0010, False),
                           ("Fort Oglethorpe, GA", -85.2566, 34.9490, False)]:
    ok = st.contains(Point(lon, lat))
    print(f"  {nm}: {'inside' if ok else 'outside'}{'' if ok == want else '  <-- WRONG'}")
print("counties:", len(out["counties"]), sorted(c["name"] for c in out["counties"]))

# the neighbours' land (Mississippi, Tennessee, Georgia, Florida): listings.py widens Alabama's outline ~300 m, but only where no
# neighbour's land is, so a Columbus or West Point listing on the far side of the Chattahoochee stays out
nb = con.execute(f"""
  SELECT region, ST_AsWKB(geometry) FROM read_parquet('{areas}', hive_partitioning=1)
  WHERE country = 'US' AND region IN ('US-MS', 'US-TN', 'US-GA', 'US-FL') AND subtype = 'region' AND class = 'land'""").fetchall()
from shapely.ops import unary_union
from shapely.geometry import box
near = box(-88.7, 29.9, -84.7, 35.2)
nbg = unary_union([wkb.loads(bytes(g)).buffer(0).intersection(near) for _, g in nb])
json.dump(mapping(nbg.simplify(0.0002, preserve_topology=True)), open(f"{OUT}/al_neighbors.geojson", "w"))
print("neighbours:", sorted(r for r, _ in nb))
