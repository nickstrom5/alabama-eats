# Alabama Eats: name, icon and palette (final: Nick's decisions, 2026-11-07)

## Name
- **Alabama Eats** (App Store name "Alabama Eats: Restaurant Guide", Nick's choice 2026-11-07, 30 characters; Home Screen "Alabama Eats", 12, which fits under the
  icon). A web search (2026-11-06) found no app, magazine, show or site called "Alabama Eats"; near ones are the state tourism app
  "Alabama Road Trips" (which folded in "100 Dishes to Eat in Alabama"), an "Alabama Food & Drink" volunteer app (2010s), Edible Lower
  Alabama and the Reedy Press book "Unique Eats and Eateries of Alabama". The Sep 2026 prompt found no exact App Store match either.
- Alternatives from the prompt: **Alabama Plates**; **Yellowhammer Eats** (Yellowhammer News and many businesses use the word).
- Avoided: "Sweet Home Alabama" (the tourism brand), "Bama" ("BamaEats" exists; the University of Alabama licenses the word), "Roll
  Tide", "War Eagle", "Heart of Dixie". The Home header's eyebrow is "THE YELLOWHAMMER STATE" (the state bird nickname).
- Subtitle: "White Sauce, Oysters & Catfish" (30).

## Icon (state-prompts/ICON-STYLE.md; all three pass check.swift; 60 px strip judged)
- **C, Nick's choice (2026-11-07): a smoked chicken leg with a drizzle of Alabama white sauce** (Decatur, 1925), on sand. It reads best at
  60 px and is the most Alabama of the three.
- A: a Gulf oyster on the half shell, on Gulf teal. Passes, but at 60 px it can read as an egg or an eye.
- B: a slice of Lane cake (the state cake since 2016) on flag crimson. Passes; reads as a layer cake, not specifically Alabama.
Drawn by `scripts/icon-concepts.swift` (PNGs in `playbook/brand/`); `scripts/make-brand.swift` makes the app icon, site icons and
docs/og.png from C. scripts/make-site.py's LOGO is the same mark as an SVG.

## Palette (the prompt's, as proposed; Nick's yes 2026-11-07. The Iron Bowl splits the state, so no school colours)
Gulf teal #1F5F6B (7.2:1 on white) for titles and tint; flag crimson #B0202E (white on it 6.8:1; not the University of Alabama's
#9E1B32) for the hand-checked guide cards; dark crimson #8A1A24 for honors chips; yellowhammer gold #E8B04A only as a fill under coal
#1E1E1E (8.5:1), never as text (2:1); sand #F7F1E3 pages. Header band: a row of camellias (the state flower) in crimson with gold
centres on a Gulf-teal line. Light mode only.
