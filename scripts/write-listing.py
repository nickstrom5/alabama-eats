#!/usr/bin/env python3
"""Writes playbook/app-store/listing.json (the App Store listing, the family's format: wy-eats/playbook/app-store/listing.json) with
every count taken from data/app/places.json, so the copy can't drift from the data. Checks Apple's lengths, that no keyword repeats a
word of the name or subtitle, and that no keyword is "best", "top" or "#1".
Usage (from al-eats/): .venv/bin/python scripts/write-listing.py   (re-run after every data rebuild)"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
d = json.load(open(f"{ROOT}/data/app/places.json"))
P = [p for p in d["places"] if not p.get("v")]
bit = {t: 1 << i for i, t in enumerate(d["tags"])}
n = {t: sum(1 for p in P if p.get("hc") and (p.get("g", 0) & bit[t])) for t in d["tags"]}
n_hc = sum(1 for p in P if p.get("hc") and (p.get("g", 0) & sum(bit.values())))
hon = sum(1 for p in P if p.get("mi") or p.get("jbf"))
bib = sum(1 for p in P if p.get("mi") == 2)
towns = len({p["c"] for p in P if p.get("c") is not None})
R = len(P)
scored = sum(1 for p in P if p.get("in"))
SITE = "https://nickstrom5.github.io/alabama-eats/"
name = "Alabama Eats: Restaurant Guide"
sub = "White Sauce, Oysters & Catfish"
desc = f"""Alabama's restaurants, from the Decatur pit where white sauce began to the oyster bars of Mobile Bay.

Alabama Eats is a free guide to eating in Alabama: {n['bbq']} white-sauce and barbecue spots, {n['meat3']} meat-and-threes, {n['oysters']} Gulf oyster bars and seafood kitchens, {n['catfish']} catfish houses and {n['greek']} Greek diners and hot dog stands we checked by hand, plus {R:,} restaurants, cafés, bars and bakeries in {towns} towns, from Birmingham, Huntsville and Montgomery to Mobile and the Gulf beaches. No account, no ads.

ALABAMA GUIDES
• White Sauce & Barbecue: Decatur, where the sauce began in 1925, to Northport and Mobile.
• Meat-and-Threes: Birmingham's steam-table lunch.
• Gulf Oysters & Seafood: Dauphin Street to Orange Beach and Fort Morgan.
• Catfish Houses: fish camps and catfish houses on the state's 2026 Catfish Trail.
• Greek Diners & Hot Dogs: the Bright Star, Gus's and Chris'.
• Oldest Places: {n['oldest']} restaurants open at the same address since 1960 or earlier.
• MICHELIN & James Beard: {hon} honored Alabama restaurants, {bib} of them Bib Gourmands.

FIND IT FAST
• Sort by distance, or browse the map by guide.
• Search by name, town, street or dish: "white sauce", "oysters mobile", "meat and three".
• Filter by town or cuisine, show only Bib Gourmands, or hide chains.
• Save places, and find hand-checked places from iPhone search (Spotlight).

LIVE DETAILS FROM APPLE MAPS
Tap "Ratings, hours & photos" on any place to open Apple Maps' own place card, with current hours, photos, ratings and directions.

HOW THE LISTS ARE BUILT
Every guide place was checked by hand in fall 2026 against a 2025 or 2026 source: the Alabama Tourism Department's Catfish Trail, the Gulf Shores & Orange Beach and Mobile tourism boards, the MICHELIN Guide or a dated local story. The rest come from Overture Maps open data, kept by the rule that matched an inspected business most often in Jefferson and Montgomery counties. For {scored:,} restaurants in those two counties, a place shows the county's latest published inspection score, dated and labeled as the county's own; the app computes no grades and never ranks by a score. Website links are checked too. Newer restaurant data downloads from the Alabama Eats website when there is some.

PRIVATE BY DESIGN
No account, no tracking, no ads. Your location, if you share it, only sorts lists on your device. Saved places stay on your device.

Places open and close, so check before you go. Spot a mistake? Email nick@eatsranked.com.

An independent app, not affiliated with any restaurant, chain or government agency (including the State of Alabama, the Alabama Department of Public Health, the Jefferson County Department of Health or the Alabama Tourism Department), or with the MICHELIN Guide or the James Beard Foundation. MICHELIN is a trademark of Michelin. James Beard Foundation and James Beard Award are trademarks of the James Beard Foundation. Place data from Overture Maps Foundation (CDLA Permissive 2.0) and others; sources and licenses are on the About tab."""
kw = "birmingham,mobile,huntsville,montgomery,tuscaloosa,gulf shores,bbq,meat and three,seafood,hot dog"
promo = (f"White-sauce barbecue, meat-and-threes, Gulf oysters and catfish houses: {n_hc} places checked by hand, plus {R:,} Alabama "
         "restaurants, nearest first.")
review = f"""1. Purpose and audience: Alabama Eats is a free guide to restaurants in Alabama (the U.S. state). Its focus is the state's own food: white-sauce and pit barbecue, meat-and-threes, Gulf oysters and seafood, catfish houses, and Greek diners and hot dog stands, {n_hc} places checked by hand in fall 2026 against a 2025 or 2026 source, plus the MICHELIN Guide and James Beard honorees. It also lists {R:,} restaurants, cafés and bars in {towns} towns from open map data. It is for residents and visitors deciding where to eat, with no ads, account or tracking.

2. How to use it (no login, no setup, no sample files needed):
- Home → White Sauce & Barbecue (or Meat-and-Threes, Gulf Oysters & Seafood, Catfish Houses, Greek Diners & Hot Dogs, MICHELIN & James Beard, Oldest Places, Official Inspection Scores, Near Me) → tap any place.
- On a place, tap "Ratings, hours & photos" to open Apple Maps' own place card through MapKit. Directions, Call and Website are below it; further down, the Health inspections section shows a Montgomery or Jefferson County place's latest published score, or links to the Alabama Department of Public Health's search in Safari.
- Search from the Home search box by name, town, street or dish ("white sauce", "oysters mobile", "meat and three").
- The Map tab shows each guide as pins. "My location" and the Nearest sort use location only if allowed, on the device.
- The heart saves a place on the device (Saved tab). The About tab lists the sources, licenses and the independence statement.
- On iPad, a sidebar replaces the tabs; a place opens in the right-hand column.
- Location: if you're outside Alabama (as App Review usually is), the map says so and stays on Alabama, and distance sorting still works from where you are.
- "Alabama Eats" is the Home Screen name of "Alabama Eats: Restaurant Guide".

3. External services and data:
- Apple MapKit: maps, local search to find a place's Apple Maps listing, and Apple's place card for live hours, photos and ratings.
- Core Location: optional, on-device only, for distance sorting.
- Data updates: at most once a day, the app checks the Alabama Eats website (static files on GitHub Pages) for newer restaurant data and downloads it if there is some. The requests carry no identifiers or location.
- No backend, accounts, analytics, advertising, payments or AI services. The restaurant data is bundled in the app.
- Bundled data sources: Overture Maps Foundation open place data (CDLA Permissive 2.0 and others; license texts are in the app); the latest inspection scores Montgomery County's health department and the Jefferson County Department of Health publish on their public websites; MICHELIN Guide and James Beard Foundation honors (facts only); and our own research of public tourism lists and local news.
- The website with the privacy policy and support page is static and hosted on GitHub Pages: {SITE}

4. Regional differences: none. The content covers Alabama; the app is offered in the United States and works the same everywhere.

5. Regulated or protected material: the app is not in a regulated industry and includes no protected third-party material. The data is open-licensed or public record, with attribution and licenses on the About tab. Inspection scores are shown only as the two counties publish them, dated and labeled official; the app computes no grade and never ranks by a score. Ratings, hours and photos are shown only inside Apple's own place card through MapKit; the app stores no ratings or reviews. Every website link was checked before release, and adult venues are excluded. The app is independent and not affiliated with any restaurant, agency, the MICHELIN Guide or the James Beard Foundation.

Support: nick@eatsranked.com"""
L = {"bundleId": "com.alabamaeats.ios", "name": name, "subtitle": sub, "privacyPolicyUrl": SITE + "privacy.html",
     "primaryCategory": "FOOD_AND_DRINK", "secondaryCategory": "TRAVEL", "description": desc, "keywords": kw, "promotionalText": promo,
     "supportUrl": SITE, "marketingUrl": SITE, "reviewNotes": review}
for k, lim in [("name", 30), ("subtitle", 30), ("keywords", 100), ("promotionalText", 170), ("description", 4000), ("reviewNotes", 4000)]:
    assert len(L[k]) <= lim, (k, len(L[k]), lim)
    print(f"{k}: {len(L[k])}/{lim}")
words = {w.lower().strip(":,&") for w in (name + " " + sub).split()}
assert not ({w for w in kw.replace(",", " ").split()} & words), "a keyword repeats the name or subtitle"
assert not any(b in kw.split(",") for b in ("best", "top", "#1"))
os.makedirs(f"{ROOT}/playbook/app-store", exist_ok=True)
json.dump(L, open(f"{ROOT}/playbook/app-store/listing.json", "w"), indent=1, ensure_ascii=False)
print("wrote playbook/app-store/listing.json")
