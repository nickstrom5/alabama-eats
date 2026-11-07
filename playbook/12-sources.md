# Alabama sources and calibration (checked 2026-11-06)

## Official sources
| Source | What it has | Can a script read it? | Used |
|---|---|---|---|
| ADPH Food Establishment Scores (alabamapublichealth.gov/foodscores, foodscores.state.al.us) | every county's scores, 100-point scale (85-100 satisfactory, 70-84 follow-up in 60 days, 60-69 in 48 hours, <60 closed) | no: a search form, and foodscores.state.al.us didn't answer on 2026-11-06 | linked from every place outside the two counties |
| Montgomery County Health Department, "Montgomery County Food Inspection Scores" (alabamapublichealth.gov/montgomery/food-scores.html) | 1,350 rows: name, street, latest date, score; "Last Updated: 11/02/26"; includes child care, gyms, stores | yes: one HTML table (ADPH has no robots.txt) | yes: 1,349 establishments, 587 places with a score |
| Jefferson County Department of Health, Food Service Scores (jcdh.org/.../FoodServScores.aspx) | the most recent scored inspection per permit: permit, score, name, address with town and ZIP, date, smoke-free; 50 a page | yes: ASP.NET paging, 146 pages, no challenge (the site loads reCAPTCHA for its forms only); jcdh.org has no robots.txt | yes: 4,001 permits, 1,696 places with a score |
| The old Montgomery PDF (montgomery/assets/foodscores_mch.pdf) | the prompt's source | 404 on 2026-11-06 (replaced by the HTML page) | no |
| City of Montgomery ArcGIS "Food Scores" | 1,336 places, June 2026 snapshot | yes | no: superseded by the county's current page |
| Mobile County Health Department ratings (mchd.org) | last 4 inspections per place | no: 403 to scripts (bot protection) | linked from Mobile County places |
| Other county health department pages (probed all 67) | Baldwin and Elmore pages link the state search; the rest redirect | no list | no |
| ADPH Establishment Closings | a short list of recent closures | readable | no (a closure there usually reopens within hours) |
| Alabama ABC Board (alabcboard.gov) | licensing | no licensee list or download; lists need a records request (Nick's call) | no: "Serves alcohol" is unknown |
| Huntsville and Montgomery city license layers (ArcGIS) | alcohol / business licenses | yes, terms unstated | no (Nick's call) |
| Birmingham open data new business licenses | ends June 2017 | yes | no (stale) |

Scores are shown as published, dated, labeled as the county's own, only on the place (and an "Official Inspection Scores" list sorted by
date or distance, never by score); no grade is computed. Montgomery's list names no town, so its rows are placed on Overture address
points at the same number and street inside Montgomery County, else the Census geocoder; 50 Montgomery and 479 Jefferson rows have no
point and only match by name and street inside their county. Montgomery's records-through date is its page's own; one row dated
01/07/27 is dropped.

## Calibration (Jefferson and Montgomery counties, the app's grouping; pipeline/calibrate.py)
- Jefferson: 3,243 open listings vs 3,522 county records. High-confidence Meta listings matched an inspected business 78.4% of the time;
  Meta 0.90 with a website 49%, Meta below 0.90 21%, BrightQuery 23%, other sources 13%. 53% of the county's inspected food businesses
  are among the open listings (the rest come in from the list itself when the name says it's a place to eat).
- Montgomery: 1,036 listings vs 1,299 records; Meta 70% (web grouping), coverage 53%.
- No Google data anywhere (not even the private web build): listings.py's Google 2021 table is empty.
- Overture 2026-10-21.0: 20,406 eating and drinking listings in the box; the App Store build ships **10,797 places, 10,274 restaurants**
  in 389 towns and 67 counties (Census CBP 2023: 8,984 NAICS 722 establishments). 2,039 places are on a county list.
- Website links: 5,251 of 8,327 OK after the check and the transient retry; 63 gambling or adult and 13 hacked pages dropped.

## Research sources (each place cites its own; every host passed check_sources.py)
- Alabama Tourism Department, Alabama Catfish Trail brochure (June 2026; cdn.buttercms.com/elTIj6CTPOV1ZitLey1a, linked from
  alabama.travel/alabama-catfish-trail): 37 restaurant stops; 19 matched for the catfish guide.
- Gulf Shores & Orange Beach Tourism, The Oyster Trail and listing pages (gulfshores.com); Visit Mobile, "What to Eat in Mobile"
  (2026-02-24).
- Bham Now: the 25 best restaurants (2026-01-02), 25 Black-owned restaurants (2026-01-14), American Ranch House (2026-01-26), Gus's
  (2026-04-29), barbecue chicken (2026-07-10); Greater Birmingham CVB listing (Gus's).
- Alabama Living: Big Bob Gibson's centennial (2025), "Home-style food done right" (2026-03-03).
- Yellowhammer News: Chris' Famous Hotdogs sold (Oct 2025); HMdb markers (Chris' 1917, the Bright Star's building 1915).
- Tasting Table: oldest restaurant (2025-09-23) and oldest bar (2025-02-17) per state, best BBQ per state (2025-11-26).
- MICHELIN Guide American South, Alabama (guide.michelin.com, 2026 edition, read 2026-11-06): 17 places, 5 Bib Gourmands, no stars.
- jamesbeard.org: 2025 and 2026 semifinalists and nominees, 2022 and 2012 winners, the 2010 America's Classic (the Bright Star).
- Blocked (robots): al.com, southernliving.com, gardenandgun.com, bhamwiki.com, lagniappemobile.com; visittuscaloosa.com answers 403.
- Leads without a usable source or match (data/research/app/LEADS.md): Felix's Fish Camp (no listing), Fish River Grill (Foley), New
  Orleans Seafood (Mobile), Wharf Casual Seafood (Sylacauga), Clay Seafood House (listing in Valley Grande, trail says Montgomery), 278
  Restaurant (Gadsden; its name has no matchable word), Dew Drop Inn (only a 2022 source), Dreamland's Tuscaloosa original (source
  host blocked).
