"""Official records for Alabama -> one table of inspected food businesses (playbook/12-sources.md).

The Alabama Department of Public Health (ADPH) inspects restaurants through its county health departments on the state's 100-point
scale (85-100 satisfactory; 70-84 re-inspected within 60 days; 60-69 within 48 hours; below 60 closed). Two counties publish their
latest scores as plain lists (fetch_official.py): Montgomery County (name, street, date, score; no town or ZIP) and Jefferson County's
own health department, JCDH (permit, score, name, street with town and ZIP, date). Each row is the latest scored inspection only.
Everywhere else ADPH's scores are reached only through its search (foodscores.state.al.us), so they are only linked. Alcohol: the ABC
Board publishes no licensee list, so "Serves alcohol" is unknown everywhere.

The score is shown as each county publishes it, with its date and labeled official; it is never turned into a letter or a grade.

load() returns: jur, lic (our id), name, keys (name keys), addr, city, zip, num, street, lat, lon, kind, active, ltype, insp, biz.
"""
import os, re, json, datetime
import numpy as np, pandas as pd
from common import norm_name, RAW, name_sim, _stems, GENERIC, canon_city

OFF = os.path.join(RAW, "official")
DIRS = {"N": "N", "S": "S", "E": "E", "W": "W", "NORTH": "N", "SOUTH": "S", "EAST": "E", "WEST": "W"}
TYPES = set("ST STREET AVE AV AVENUE BLVD BOULEVARD RD ROAD DR DRIVE LN LANE CT COURT PL PLACE PKWY PARKWAY TER TRL TRAIL WAY HWY CIR "
            "CIRCLE PLZ SQ MALL BND PASS XING RUN ROW WALK RDG LOOP FWY FREEWAY EXPY EXPRESSWAY PIKE PK PKE".split())


def road(a):
    """One spelling for numbered roads. Alabama writes one road as 'Route 100', 'US 7', 'Rt 2', 'AL 100' or 'AL Route 100', so every
    numbered US or state route is 'SH n' (as in ri-eats); 'N INTERSTATE 95' = 'I-95'; 'COUNTY ROAD 5' = 'CR 5'."""
    a = re.sub(r"(\d)\s*&\s*(\d)", r"\1-\2", a.upper())
    a = re.sub(r"\b(US|AL|SR|SH|CR|I|IH|RT|RTE)-(\w)", r"\1 \2", a)
    a = re.sub(r"\b(?:INTERSTATE(?: HIGHWAY| HWY)?|IH|I H)\s*(?=\d)", "I ", a)
    a = re.sub(r"\b(?:US|U S)\s+(?:HIGHWAY|HWY)\b", "US", a)
    a = re.sub(r"\b(?:FARM[- ]TO[- ]MARKET(?: ROAD| RD)?|FARM (?:ROAD|RD)|F M)\b", "FM", a)
    a = re.sub(r"\b(?:RANCH[- ]TO[- ]MARKET(?: ROAD| RD)?|RANCH (?:ROAD|RD)|RR|RM)\b(?=\s*\d)", "RM", a)
    a = re.sub(r"\b(?:STATE (?:HIGHWAY|HWY|ROAD|RD|ROUTE|RTE)|SR|SH|WEST VIRGINIA (?:ROUTE|RTE|HIGHWAY|HWY)|AL (?:ROUTE|RTE|RT|HIGHWAY|HWY)|AL|"
               r"US (?:ROUTE|RTE|RT)|US|ROUTE|RTE|RT|HWY)\b\.?(?=\s*\d)", "SH", a)
    a = re.sub(r"\b(?:COUNTY (?:HIGHWAY|HWY|ROAD|RD)|CO RD|CTY (?:HWY|RD)|CR)\b", "CR", a)
    a = re.sub(r"\bHIGHWAY\b", "HWY", a)
    return re.sub(r"\b(US|SH|CR|HWY|FM|RM|I) (\w+)\s*-\s*\w+", r"\1 \2", a)


ORD = {"FIRST": "1ST", "SECOND": "2ND", "THIRD": "3RD", "FOURTH": "4TH", "FIFTH": "5TH", "SIXTH": "6TH", "SEVENTH": "7TH",
       "EIGHTH": "8TH", "NINTH": "9TH", "TENTH": "10TH", "ELEVENTH": "11TH", "TWELFTH": "12TH"}


def street_key(a):
    """'2505 Monroe St' -> ('2505', 'MONROE'); '1000 OSAGE STREET' -> ('1000', 'OSAGE'); 'E Colfax Ave' keeps 'COLFAX'."""
    if not isinstance(a, str):
        return None, None
    a = re.sub(r"[.,#]", " ", road(a))
    # "20940-A North Frederick Ave": a hyphenated unit letter is part of the number (Maryland's Montgomery County wrote them so)
    m = re.match(r"^\s*(\d+)(?:-?[A-Z])?(?:\s*-\s*\d+[A-Z]?)?\s+(.*)$", a)
    if not m:
        return None, None
    words = [w for w in m.group(2).split() if w]
    if len(words) > 1 and words[0] in DIRS:
        words = words[1:]
    core = []
    for w in words:
        if w in TYPES and core:
            break
        core.append(w)
    core = [ORD.get(w, w) for w in core]
    return m.group(1), " ".join(core[:3]) or None


def street_compat(a, b):
    """Same street, or one is a whole-word prefix of the other: Boulder's 2025 set sometimes truncates ("1206 CENTAUR" = Centaur Village Dr)."""
    if not isinstance(a, str) or not isinstance(b, str) or not a or not b:
        return False
    return a == b or a.startswith(b + " ") or b.startswith(a + " ")


def street_nums(a):
    """'157-159 W Main St' -> {'157', '159'}; '2505 Monroe St' -> {'2505'}."""
    if not isinstance(a, str):
        return set()
    a = road(a)
    m = re.match(r"^\s*(\d+)[A-Z]?(?:\s*-\s*(\d+)[A-Z]?)?\s", a.upper() + " ")
    if not m:
        return set()
    lo = int(m.group(1)); hi = int(m.group(2)) if m.group(2) else lo
    if hi < lo:   # "1500-02"
        hi = int(str(lo)[: len(str(lo)) - len(m.group(2))] + m.group(2)) if m.group(2) else lo
    return {str(x) for x in range(lo, hi + 1, 2 if (hi - lo) % 2 == 0 else 1)} if 0 <= hi - lo <= 12 else {str(lo)}


def _names(*vals):
    out = []
    for v in vals:
        if not isinstance(v, str):
            continue
        v = re.sub(r"\s*\((?:MOBILE|MOBILE UNIT|COMMISSARY|CATERING|SPECIAL EVENT|SPEC EVENT|TEMP(?:ORARY)? EVENT|CP|INSIDE [^)]*)\)\s*$", "", v, flags=re.I)
        for part in re.split(r"\s*/\s*|\s+\bdba\b\s+|\s+&\s+(?=[A-Z][a-z])", v, flags=re.I):
            k = norm_name(re.sub(r"\b(?:LLC|INC|CORP|CORPORATION|LTD|CO)\b\.?", "", part, flags=re.I))
            if k and k not in out:
                out.append(k)
    return out


META = json.load(open(os.path.join(OFF, "meta.json"))) if os.path.exists(os.path.join(OFF, "meta.json")) else {}
LIST_DATE = (META.get("montgomery") or {}).get("updated")   # Montgomery County's "Last Updated" date
# Montgomery County's own list page; ADPH's statewide search (every county's scores, search-only, only linked)
MONT_PAGE = "https://www.alabamapublichealth.gov/montgomery/food-scores.html"
JCDH_PAGE = "https://www.jcdh.org/SitePages/Programs-Services/Scores-Lists/Food/FoodServScores.aspx"
INSPECTIONS_URL = "https://www.alabamapublichealth.gov/foodscores/index.html"
# the score as published, 0 to 100: index = score
RESULTS = tuple(str(n) for n in range(101))
ONPREM_T = ()      # no alcohol license list (the ABC Board publishes none)


def liq_kind(t):
    """A license type as shown -> on-premises or retail (none in Alabama's data)."""
    if not isinstance(t, str):
        return None
    return "onprem" if t in ONPREM_T else "retail" if "package" in t or "off-premises" in t else None


COLUMNS = ["jur", "lic", "name", "dba", "holder", "keys", "addr", "city", "zip", "num", "street", "lat", "lon", "kind", "active", "ltype",
           "insp", "issued", "biz", "drinks", "county"]


def _zip(z):
    z = re.sub(r"\D", "", str(z or ""))
    return z[:5] if len(z) >= 5 else ""


def _title(a):
    """'500 MINERAL TRCE' -> '500 Mineral Trce'; Montgomery's mixed case stays."""
    a = re.sub(r"\s+", " ", a or "").strip()
    return re.sub(r"\b([A-Z][A-Z']+)\b", lambda m: m.group(1).title() if len(m.group(1)) > 2 or m.group(1) not in DIRS else m.group(1), a) if a.isupper() else a


def _date(md):
    m = re.match(r"^(\d{1,2})/(\d{1,2})/(\d{2,4})$", (md or "").strip())
    if not m:
        return None
    mo, d, y = (int(x) for x in m.groups())
    try:
        return datetime.date(2000 + y if y < 100 else y, mo, d).isoformat()
    except ValueError:
        return None


# Who isn't a place to go out to eat, by the record's name: care homes, schools, day cares, hospitals, jails, stores and gas
# stations, pharmacies, gyms, churches, caterers and commissaries. They still match their own listings (which are hidden as
# non-restaurants), but never come in as places of their own. A truck or mobile unit is a truck.
NOT_PUBLIC = re.compile(r"\b(?:NURSING|REHAB\w*|ASSISTED LIVING|SENIOR|RETIREMENT|HOSPICE|HOSPITAL|MEDICAL|HEALTH CARE|HEALTHCARE|"
                        r"SCHOOL|ELEMENTARY|ACADEMY|HEAD START|CHILD ?CARE|DAY ?CARE|DAYCARE|PRESCHOOL|LEARNING|KIDS|KINDER\w*|"
                        r"JAIL|DETENTION|CORRECTION\w*|CHURCH|MINISTR\w*|TABERNACLE|"
                        r"PHARMACY|DRUGS?|WALGREENS|CVS|FITNESS|GYM|YMCA|SPA|"
                        r"SUPERMARKET|SUPER MARKET|GROCERY|FOOD ?MART|FOODMART|MARKET ?PLACE|DOLLAR|CITGO|SHELL|CHEVRON|EXXON|TEXACO|"
                        r"MARATHON|SUNOCO|MOBIL|BP|VALERO|CIRCLE K|RACETRAC|QUIKTRIP|QT|MURPHY USA|FUEL|GAS|PETRO\w*|TRAVEL CENTER|"
                        r"KROGER|PUBLIX|WINN ?DIXIE|WAL ?MART|WALMART|SAMS CLUB|COSTCO|TARGET|ALDI|PIGGLY WIGGLY|FOOD GIANT|"
                        r"CATER\w*|COMMISSARY|VENDING|CONCESSIONS?|CONCESSION STAND|BANQUET|"
                        r"CORPORATION|PLANT|WAREHOUSE|DISTRIBUT\w*|HS|JCBE|BOE|"
                        r"INN (?:AND|&) SUITES|HAMPTON INN|HOLIDAY INN|MICROTEL|COMFORT INN|QUALITY INN|SLEEP INN|DAYS INN|BEST WESTERN|"
                        r"MARRIOTT|HILTON|HOMEWOOD SUITES|SPRINGHILL|FAIRFIELD INN|COURTYARD BY|EXTENDED STAY|LA QUINTA|MOTEL|"
                        r"ELKS|MOOSE LODGE|VFW|AMERICAN LEGION|MASONIC|COUNTRY CLUB)\b")
TRUCK = re.compile(r"\b(?:FOOD TRUCK|TRUCK|MOBILE|TRAILER|CART|PUSH ?CART|KIOSK)\b")
JEF_TOWNS = ["VESTAVIA HILLS", "MOUNTAIN BROOK", "CENTER POINT", "PLEASANT GROVE", "MOUNT OLIVE", "SYLVAN SPRINGS", "NORTH JOHNS",
             "WEST JEFFERSON"]


def _kind(name):
    k = (name or "").upper()
    if TRUCK.search(k):
        return "truck"
    return "other" if NOT_PUBLIC.search(norm_name(k) + " " + re.sub(r"[^A-Z ]", " ", k)) else "food"


def _jef_split(a):
    """'500 MINERAL TRCE HOOVER 35244' -> ('500 Mineral Trce', 'Hoover', '35244')."""
    m = re.match(r"^(.*?)\s+(\d{5})(?:-\d{4})?$", (a or "").strip())
    if not m:
        return _title(a), None, ""
    body, z = m.group(1), m.group(2)
    for t in JEF_TOWNS:
        if body.endswith(" " + t):
            return _title(body[: -len(t) - 1]), canon_city(t.title()), z
    words = body.split()
    return _title(" ".join(words[:-1])), canon_city(words[-1].title()), z


def load_montgomery():
    rows = []
    upd = LIST_DATE
    for n, r in enumerate(json.load(open(os.path.join(OFF, "montgomery.json")))):
        name = re.sub(r"\s+", " ", r.get("name") or "").strip()
        if not name:
            continue
        addr = _title(r.get("addr"))
        num, st = street_key(addr)
        d = r.get("date")
        sc = r.get("score") or ""
        ok = bool(re.fullmatch(r"\d{1,3}", sc)) and int(sc) <= 100 and d and (not upd or d <= upd)
        rows.append({"jur": "montgomery", "lic": f"montgomery-{n}", "name": name, "dba": name, "holder": None, "keys": _names(name),
                     "addr": addr, "city": None, "zip": "", "num": num, "street": st, "lat": None, "lon": None, "kind": _kind(name),
                     "active": True, "ltype": "Montgomery County Health Department food establishment",
                     "insp": [[d, str(int(sc)), None, f"m{n}"]] if ok else [], "issued": None, "drinks": None,
                     "county": "Montgomery County"})
    return rows


def load_jefferson():
    rows, seen = [], set()
    for r in json.load(open(os.path.join(OFF, "jefferson.json"))):
        name = re.sub(r"\s+", " ", r.get("name") or "").strip()
        if not name or not r.get("permit") or r["permit"] in seen:
            continue
        seen.add(r["permit"])
        addr, city, z = _jef_split(r.get("addr"))
        num, st = street_key(addr)
        d = _date(r.get("date_raw"))
        sc = r.get("score") or ""
        ok = bool(re.fullmatch(r"\d{1,3}", sc)) and int(sc) <= 100 and d
        rows.append({"jur": "jefferson", "lic": "jcdh-" + r["permit"], "name": name, "dba": name, "holder": None, "keys": _names(name),
                     "addr": addr, "city": city, "zip": z, "num": num, "street": st, "lat": None, "lon": None, "kind": _kind(name),
                     "active": True, "ltype": "Jefferson County Department of Health food service permit " + r["permit"],
                     "insp": [[d, str(int(sc)), None, "j" + r["permit"] + "-" + (r.get("insp") or "")]] if ok else [], "issued": None,
                     "drinks": None, "county": "Jefferson County"})
    return rows


def load():
    """Montgomery County's and Jefferson County's published latest scores, one row per establishment."""
    rows = []
    if os.path.exists(os.path.join(OFF, "montgomery.json")):
        rows += load_montgomery()
    if os.path.exists(os.path.join(OFF, "jefferson.json")):
        rows += load_jefferson()
    df = pd.DataFrame(rows) if rows else pd.DataFrame({c: pd.Series(dtype=object) for c in COLUMNS})
    for c_ in COLUMNS:
        if c_ not in df.columns:
            df[c_] = None
    df["lat"] = df["lat"].astype(float); df["lon"] = df["lon"].astype(float); df["active"] = df["active"].astype(bool)
    df["biz"] = np.arange(len(df))
    return df
