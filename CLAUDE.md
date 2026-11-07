# Alabama Eats (al-eats) — notes for Claude Code sessions

Built 2026-11-06 by a side session for Nick's "build the 17 states left" (group: Alabama, Mississippi, Arkansas, Oklahoma), ported from
`../wy-eats/` (the newest finished state, 2026-11-05: delivery-only brands hidden, the website blocklist and `link_blocklist.py`, the
Share link `Links.site + explore/#p=<id>`, over-the-air data, adult-venue filtering, the Denny's delivery-brand rule, the
`playbook/app-store/listing.json` format). Local only: git-ignored data, no repo, no remote, nothing published, nothing in App Store
Connect. Sources: `playbook/12-sources.md`. Brand: `playbook/05-naming.md` — **final** (Nick's decisions, 2026-11-07: "Alabama Eats:
Restaurant Guide", Home Screen "Alabama Eats"; a white-sauce chicken leg icon, concept C, on sand; Gulf teal #1F5F6B, flag crimson
#B0202E, dark crimson #8A1A24, yellowhammer gold #E8B04A as a fill only, sand #F7F1E3; a camellia header band).

## Status (2026-11-06)
- DONE: pipeline (Overture 2026-10-21.0, 67 counties, border towns checked), official scores (Montgomery County's page, JCDH's list),
  calibration, research (69 entries, all matched), app export **10,797 places / 10,274 restaurants** (2,037 with an official score),
  website link check (5,251 OK), Swift app, icon concepts (all pass check.swift) + make-brand, site (17 pages) + web app, OTA local
  copy `--check` OK, `listing.json` (lengths checked), 13-app-review-reply.md.
- Tests (iOS 27.0 simulators, Xcode 1.app 27.2): iPad 13" all unit + UI tests pass (1 skipped: the launch-time test skips on a
  busy Mac); iPhone 17 Pro Max: all unit and UI tests pass (testTourEveryScreen timed out once at a load over 200 and passed alone on
  2026-11-06 19:36).
- Screenshots: 13 iPhone + 6 iPad captures, App Store frames in `playbook/app-store/{iphone,ipad}/`, site images; full
  `qa-site.py` (static + browser) passes with 0 problems.
- **Ready to publish**; nothing is public. Nick's decisions (2026-11-07): the name "Alabama Eats: Restaurant Guide", icon C (the
  white-sauce chicken leg) and the palette are final, and "Yes, publish" (the parent session publishes). He also said yes to the ABC
  Board for "Serves alcohol", but the Board publishes no licensee list, download or search (checked 2026-11-07): only its public
  records request form (alabcboard.gov/form/public-records-request). That request waits on its own yes, so "Serves alcohol" stays
  unknown for now. Huntsville's and Montgomery's city license layers remain unused.

## Alabama is different
- **Official scores in two counties.** ADPH scores restaurants 0-100 (85+ satisfactory). Montgomery County's health department posts
  its latest scores as one HTML table ("Last Updated"); the Jefferson County Department of Health posts the most recent scored
  inspection per permit as a paged ASP.NET list (146 pages; no challenge; the reCAPTCHA script on jcdh.org is for its forms).
  `pipeline/fetch_official.py` reads both, one request at a time. Everywhere else scores are search-only (ADPH), so places link there
  (and Mobile County places to MCHD's ratings). The app shows a score only on the place ("Latest score (official) 93 of 100 · date",
  "Published by <county>") and in a white "Official Inspection Scores" card sorted by date, distance or name — never by score, never a
  grade. Nick (11-05): the app leads with the hand-checked guides; the scores card is the last guide on Home.
- **No Google data anywhere**, not even the private web build (`listings.py` makes an empty Google 2021 table; `alabama.py` reads no
  UCSD file). `calibrate.py` measures the keep rule against the two county lists instead (Jefferson: Meta ≥0.95 matched 78.4%).
- **Montgomery's list names no town**: rows are placed on address points at the same number and street inside the county
  (`geocode_official.py`), else the Census geocoder asked for "Montgomery". Records keep their list's county for matching.
- **Hand-checked town wins** over a listing's mailing town (The Bright Star's listing said Birmingham), and a hand-checked copy's
  checked name survives a duplicate merge with a county record (JCDH's "Bright Star Restaurant").
- **"MOBILE" is a city here**: it's out of the venue words (it meant food trucks elsewhere).
- **Guides** (tags in `alabama.py` TAGS; bits 1..32): bbq (white sauce / pit), meat3, oysters (oyster bar / Gulf seafood), catfish
  (the Alabama Tourism Department's June 2026 Catfish Trail), greek (Greek diners and hot dog stands), oldest (≤1960 at this address:
  Peerless 1899, Bright Star 1915, Chris' 1917, Callaghan's 1946, Big Bob Gibson 1952). Research is hand-written in
  `data/research/app/*.json`; `build_research.py` only checks it and writes `LEADS.md`.
- **Honors**: MICHELIN Guide American South 2026, 17 Alabama places (5 Bib Gourmand, no stars); James Beard (the Bright Star 2010
  Classic; Hastings 2012 and Evans 2022 Best Chef: South; Bottega 2026 finalist; 2025-26 semifinalists). Highlands Bar & Grill is on the
  closed list.

## Rebuild
```bash
cd pipeline
../.venv/bin/python check_sources.py URL...   # a new host first
../.venv/bin/python fetch_overture.py && ../.venv/bin/python fetch_extras.py && ../.venv/bin/python fetch_official.py
../.venv/bin/python geocode_official.py && ../.venv/bin/python geocode_census.py && ../.venv/bin/python listings.py
../.venv/bin/python calibrate.py && ../.venv/bin/python alabama.py && ../.venv/bin/python build_research.py
AL_APP=1 ../.venv/bin/python alabama.py && cd .. && cp data/app/places.json data/app/detail-*.json AlabamaEats/Resources/
.venv/bin/python pipeline/check_websites.py && .venv/bin/python pipeline/check_websites.py --retry-transient   # then re-export
.venv/bin/python scripts/make-site.py && .venv/bin/python scripts/publish_app_data.py && .venv/bin/python scripts/publish_app_data.py --check
.venv/bin/python scripts/qa-site.py --static && .venv/bin/python scripts/write-listing.py
```
The `.venv` is on the python.org framework Python 3.12 with md-eats' versions. `data/chain_auv.json` is a copy of wy-eats'.

## App, site, screenshots
- App: `AlabamaEats/` (XcodeGen `project.yml`, bundle `com.alabamaeats.ios`, display "Alabama Eats"), tests in `AlabamaEatsTests/`
  (fixture, guides, the scores list, outline towns: Phenix City in / Columbus GA out, data guards incl. Alabama news hosts) and
  `AlabamaEatsUITests/`. Tests: `xcodebuild test -scheme AlabamaEats -destination id=<sim> -parallel-testing-enabled NO` with
  `DEVELOPER_DIR="/Applications/Xcode 1.app/Contents/Developer"` (no CODE_SIGNING_ALLOWED=NO: UI tests need a signed runner).
  Archive only with Xcode 1.app (27.2, 27B52). Run `xcodegen generate` whenever `Resources/*.json` changes.
- Site: `scripts/make-site.py` → `docs/`; `scripts/explore.js` the web app (an "Inspection scores" list from core column `sd`, the
  score itself only in the place panel); `scripts/qa-site.py`. URL for now: nickstrom5.github.io/alabama-eats (no CNAME). City pages:
  Birmingham, Mobile, Orange Beach.
- Screenshots: `scripts/capture-screenshots.sh <sim> home bbq meat3 oysters catfish greek detail map honors oldest inspections saved
  about` (ScreenshotMode pins downtown Birmingham; Orange Beach for oysters; Bessemer for the detail, The Bright Star), then
  `scripts/site-images.sh`, make-site, qa-site; App Store frames `scripts/appstore-screenshots.py` (iPhone: home bbq detail oysters
  catfish map meat3 saved; iPad: home bbq oysters map catfish greek). No inspections screen in any App Store image.

## Rules
No commits, pushes, public repos, App Store Connect or DNS changes without Nick's yes each time; never submit for review or accept
agreements; never publish Google-derived data. Support email nick@eatsranked.com. Commit author "Nick Soderstrom"
<329204362+nickstrom5@users.noreply.github.com> via `-c user.name -c user.email`.
