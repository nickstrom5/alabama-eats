"""Alabama's published official records -> data/raw/official/ (git-ignored, never public).

Checked 2026-11-06 (playbook/12-sources.md). Alabama's inspections are run by the Alabama Department of Public Health (ADPH) through
its county health departments on the state's 100-point scale (85-100 satisfactory, 70-84 a follow-up within 60 days, 60-69 within
48 hours, below 60 closed: alabamapublichealth.gov/foodscores/system.html). The statewide search (foodscores.state.al.us) is a search
form, and it did not answer on 2026-11-06; it is only linked. Two lists are published as plain pages:

- Montgomery County: the county health department's "Montgomery County Food Inspection Scores" page
  (alabamapublichealth.gov/montgomery/food-scores.html), one HTML table of name, address, latest date and score, headed
  "Last Updated". It includes non-restaurants (child care, gyms, stores). ADPH's site has no robots.txt (404).
- Jefferson County: the Jefferson County Department of Health (JCDH) list of "the most recent scored inspections"
  (jcdh.org/SitePages/Programs-Services/Scores-Lists/Food/FoodServScores.aspx): permit, score, name, address with town and ZIP, date
  and smoke-free, 50 rows a page behind ASP.NET paging. JCDH also does non-scored "alternative" inspections, so a place missing
  from the list is not a zero. jcdh.org has no robots.txt (404). The site loads Google's reCAPTCHA script for its forms; the list
  itself needs none. If a page ever answers with a challenge instead of the list, this script stops (no workaround).

Mobile County's ratings (mchd.org) answer 403 to scripts and are only linked; every other county is search-only. One request at a time,
an honest user agent, two seconds apart; no owner or person names are kept.
"""
import datetime, html, json, os, re, sys, time
import requests

OUT = os.path.join(os.path.dirname(__file__), "..", "data", "raw", "official")
os.makedirs(OUT, exist_ok=True)
UA = "AlabamaEatsDataCheck/1.0 (+https://nickstrom5.github.io/alabama-eats/; nick@eatsranked.com)"
S = requests.Session(); S.headers["User-Agent"] = UA
MONT = "https://www.alabamapublichealth.gov/montgomery/food-scores.html"
JCDH = "https://www.jcdh.org/SitePages/Programs-Services/Scores-Lists/Food/FoodServScores.aspx"
TODAY = datetime.date.today().isoformat()


def text(s):
    return html.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", s or ""))).strip()


def get(url):
    for attempt in range(4):
        r = S.get(url, timeout=90)
        if r.status_code == 200:
            return r
        time.sleep(5 * (attempt + 1))
    r.raise_for_status()


def montgomery():
    r = get(MONT)
    s = r.text
    upd = re.search(r"Last Updated:\s*(\d{1,2})/(\d{1,2})/(\d{2,4})", s)
    updated = None
    if upd:
        m, d, y = (int(x) for x in upd.groups())
        updated = datetime.date(2000 + y if y < 100 else y, m, d).isoformat()
    rows = []
    for tr in re.findall(r"(?s)<tr[^>]*>(.*?)</tr>", s):
        cells = [text(c) for c in re.findall(r"(?s)<t[hd][^>]*>(.*?)</t[hd]>", tr)]
        if len(cells) != 4 or cells[0] == "Establishment":
            continue
        name, addr, date, score = cells
        mm = re.match(r"^(\d{1,2})/(\d{1,2})/(\d{2,4})$", date)
        iso = None
        if mm:
            m, d, y = (int(x) for x in mm.groups())
            try:
                iso = datetime.date(2000 + y if y < 100 else y, m, d).isoformat()
            except ValueError:
                iso = None
        rows.append({"name": name, "addr": addr, "date": iso, "date_raw": date, "score": score})
    assert len(rows) > 500, f"Montgomery list too short: {len(rows)}"
    return rows, updated


def _hidden(s):
    return {k: html.unescape(v) for k, v in re.findall(r'<input type="hidden" name="([^"]+)" id="[^"]*" value="([^"]*)"', s)}


def _jrows(s):
    out = []
    for tr in re.findall(r"(?s)<tr[^>]*>(.*?)</tr>", s):
        tds = re.findall(r"(?s)<td[^>]*>(.*?)</td>", tr)
        if len(tds) < 3 or not re.fullmatch(r"\s*\d+\s*", text(tds[0])):
            continue
        sc = re.search(r'PermitNbr=(\d+)&amp;InspNbr=(\d+)"[^>]*>\s*(\d+)\s*<', tds[1])
        nm = re.search(r'LblBusinessName_\d+"[^>]*>(.*?)</span>', tds[2], re.S)
        ad = re.search(r'LblBusinessAddress_\d+"[^>]*>(.*?)</span>', tds[2], re.S)
        dt = re.search(r'LblDate_\d+"[^>]*>(?:<i>Date:</i>)?(.*?)</span>', tds[2], re.S)
        sf = re.search(r'LblSmokeFree_\d+"[^>]*>(?:<i>Smoke Free:</i>)?(.*?)</span>', tds[2], re.S)
        out.append({"permit": text(tds[0]), "insp": sc.group(2) if sc else None, "score": sc.group(3) if sc else text(tds[1]),
                    "name": text(nm.group(1)) if nm else None, "addr": text(ad.group(1)) if ad else None,
                    "date_raw": text(dt.group(1)) if dt else None, "smoke_free": text(sf.group(1)) if sf else None})
    return out


def jefferson():
    r = get(JCDH)
    s = r.text
    rows, seen_pages, page = _jrows(s), 1, 1
    if not rows:
        sys.exit("JCDH: no list on the first page (stopping; nothing saved)")
    while True:
        h = _hidden(s)
        nxt = page + 1
        if f"Page${nxt}" not in s.replace("&#39;", "'").replace("&#36;", "$"):
            break
        h.update({"__EVENTTARGET": "ctl00$MainContent$gvFoodScores", "__EVENTARGUMENT": f"Page${nxt}"})
        time.sleep(2)
        for attempt in range(3):
            resp = S.post(JCDH, data=h, timeout=90)
            if resp.status_code == 200:
                break
            time.sleep(10 * (attempt + 1))
        if resp.status_code != 200:
            sys.exit(f"JCDH page {nxt}: HTTP {resp.status_code} (stopping; nothing saved)")
        s = resp.text
        got = _jrows(s)
        if not got:
            if re.search(r"(?i)g-recaptcha|captcha", re.sub(r"(?s)<script.*?</script>", "", s)):
                sys.exit(f"JCDH page {nxt}: a challenge instead of the list (stopping; nothing saved; ask Nick)")
            break
        rows += got
        page = nxt
        if page % 20 == 0:
            print("  JCDH page", page, "rows", len(rows), flush=True)
    return rows, page


mont, mont_updated = montgomery()
print("Montgomery County:", len(mont), "rows, updated", mont_updated, flush=True)
time.sleep(2)
jef, pages = jefferson()
print("Jefferson County:", len(jef), "rows on", pages, "pages", flush=True)
json.dump(mont, open(os.path.join(OUT, "montgomery.json"), "w"), indent=0)
json.dump(jef, open(os.path.join(OUT, "jefferson.json"), "w"), indent=0)
meta = {"montgomery": {"name": "Montgomery County Health Department (ADPH): Montgomery County Food Inspection Scores", "url": MONT,
                       "fetched": TODAY, "updated": mont_updated, "rows": len(mont),
                       "terms": "Published on ADPH's public website; no terms or robots.txt posted"},
        "jefferson": {"name": "Jefferson County Department of Health: Food Service Scores (most recent scored inspections)", "url": JCDH,
                      "fetched": TODAY, "rows": len(jef), "pages": pages,
                      "terms": "Published on JCDH's public website; no terms or robots.txt posted; non-scored alternative inspections not listed"}}
json.dump(meta, open(os.path.join(OUT, "meta.json"), "w"), indent=1)
