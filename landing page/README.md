# Handoff: TrojanMatch Landing Page (desktop + mobile)

## Overview
A new **landing page** for TrojanMatch that sits *in front of* the existing app (Browse / Help-me-choose). Today the app drops students straight into all 81 clubs, which can feel overwhelming. The landing page briefly says what TrojanMatch is over a Wayzata High School photo, then sends the student into the product in one click. It is intentionally minimal — one screen, no extra pages, no scrolling required.

It is **responsive with two distinct layouts**:
- **Desktop / laptop (> 768px):** a "two doors" layout — a welcome photo band, then two side-by-side cards ("Help me choose" and "Browse all clubs").
- **Phone (≤ 768px):** a full-bleed photo hero — the WHS photo fills the screen with the welcome text and two stacked buttons overlaid at the bottom.

## About the Design Files
The file in this bundle (`TrojanMatch Landing.dc.html`) is a **design reference created in HTML** — a prototype showing the intended look and behavior, not production code to ship as-is. The task is to **recreate this design inside the existing TrojanMatch codebase using its established patterns.**

This project's existing app (`index.html`) is authored in the **"dc" declarative-component format** (HTML markup with `{{ }}` interpolation + `<sc-if>`/`<sc-for>` and a `Component` class), styled with **inline `style="..."` attributes** plus one `<style>` block reserved for the `@media (max-width:640px)` phone overrides. Match that: the landing page should become either a new view inside the existing `Component` (e.g. a `view: 'landing'` state that renders before Browse/Quiz) or its own small dc file, styled the same way the rest of the app is. The buttons should wire to the app's existing navigation — "Take the quiz" / "Find my clubs" → the quiz view (`setQuiz`), "Browse all clubs" / "See the directory" → the browse view (`setBrowse`).

Note: this prototype uses a `.desk-only` / `.phone-only` pair toggled by a CSS media query for clarity. The existing app instead keys its phone layout off `@media (max-width: 640px)` with `!important` overrides on inline styles — either approach is fine; follow whichever fits the integration best. If you keep both layouts in the DOM, the media-query show/hide pattern is simplest.

## Fidelity
**High-fidelity.** Final colors, typography, spacing, copy, and the photo are all as intended. Recreate pixel-perfectly. The one open value is the photo crop, documented below.

---

## Screens / Views

### Shared header (both layouts)
- White background, `1px solid #eef2f5` bottom border.
- Left group (horizontal flex, `gap: 18px` desktop / `10px` mobile, vertically centered):
  - WHS logo `assets/wayzata-high-school-logo.png`, `height: 48px` desktop / `28px` mobile, `width: auto`.
  - A `1px solid #e2e8ee` left divider with `padding-left: 18px` (10px mobile), then the wordmark **TrojanMatch**: Archivo 800, `25px` desktop / `18px` mobile, color `#00335c`, with **"Match"** in `#f0b323`.
- Desktop right side: nav links (Public Sans 600, `15.5px`, `#1a2c39`, `gap: 32px`): `Help me choose`, `Browse clubs`, and `wayzata.k12.mn.us ↗` in `#00457c`.
- Mobile right side: a hamburger icon (3 lines, `stroke #1a2c39`, `stroke-width 2.2`, ~25px). (The mobile menu itself is not designed yet — wire to the app's existing nav.)
- Desktop header inner content is centered in a `max-width: 1200px` container, `padding: 14px 34px`. Mobile header `padding: 16px 18px`.

### DESKTOP view — "Two doors"
- **Purpose:** explain + let the student pick quiz or browse.
- **Welcome band** (directly under header): `height: 440px`, `position: relative`, contents centered (flex column, centered, `text-align: center`).
  - Background image `assets/whs-fog.jpg`, `object-fit: cover`, `object-position: center 40%`, `filter: saturate(1.14) brightness(1.08)`, absolutely positioned to fill.
  - Overlay on top of the photo: `linear-gradient(180deg, rgba(0,31,61,0.18), rgba(0,45,84,0.42))`.
  - Heading `<h1>`: "Welcome to *TrojanMatch*". "Welcome to " is Archivo 800, `56px`, `#fff`, `letter-spacing: -0.01em`; "TrojanMatch" is **Playfair Display italic 700**, `#f0b323`. `text-shadow: 0 2px 18px rgba(0,20,45,0.4)`.
  - Sub-line: Public Sans, `19px`, `#eef4fa`, `line-height: 1.5`, `max-width: 640px`, centered, `margin-top: 18px`. Text: "Wayzata High School's club finder — start whichever way feels easiest."
- **Two cards** below the band: `max-width: 1080px` centered container, `display: grid; grid-template-columns: 1fr 1fr; gap: 26px; padding: 56px 34px 72px`.
  - Each card: `border: 1px solid #d9dde2`, `border-radius: 4px`, `padding: 40px 38px`, flex column, `gap: 16px`.
  - Card heading `<h2>`: Archivo 800, `27px`, `#1a2330`.
  - Card body `<p>`: Public Sans, `17px`, `line-height: 1.55`, `#5a6570`, `flex: 1` (so the button bottom-aligns).
  - Card button: Archivo 700, `16px`, `padding: 14px 28px`, `border-radius: 8px`, no border, background `#00457c`, color `#fff`, `align-self: flex-start`.
  - Card 1 — "Help me choose" / "Answer a few quick questions and get a ranked shortlist matched to you." / button **Take the quiz** → quiz view.
  - Card 2 — "Browse all clubs" / "Search and filter the full club directory by category." / button **See the directory** → browse view.

### PHONE view — Full-bleed hero
- **Purpose:** single welcoming screen, one tap into the product. This is the default landing on phones.
- Root: flex column, `min-height: 100vh` (fills the viewport).
- Header as described above (mobile variant).
- **Hero** = the rest of the screen (`flex: 1`, `position: relative`, contents bottom-aligned):
  - Background image `assets/whs-fog.jpg`, `object-fit: cover`, **`object-position: 16% 40%`** (this crop shows the full Trojan "W" logo on the building at upper-left — keep it), `filter: saturate(1.14) brightness(1.08)`.
  - Overlay: `linear-gradient(180deg, rgba(0,31,61,0.05) 0%, rgba(0,31,61,0) 34%, rgba(0,31,61,0.66) 100%)` — light at top, darker at the bottom so the text is readable.
  - Text block, `padding: 0 24px 40px`, bottom of hero:
    - Eyebrow: Archivo 700, `11px`, `letter-spacing: 0.14em`, uppercase, `#f0b323` — "Wayzata High School".
    - Heading `<h1>`, `line-height: 1.0`: block "Welcome to" (Archivo 800, `42px`, `#fff`, `letter-spacing: -0.02em`) over block "TrojanMatch" (Playfair Display italic 700, `39px`, `#f0b323`).
    - Sub-line: Public Sans, `15.5px`, `line-height: 1.5`, `#eaf1f8`, `margin: 14px 0 22px` — "Answer a few quick questions and we'll match you to the WHS clubs that fit you best."
    - Two **full-width stacked buttons**, `gap: 11px`, both Archivo 700, `16px`, `padding: 16px`, `border-radius: 8px` (boxy, not pill):
      - Primary **Find my clubs** — background `#f0b323`, color `#00335c`, no border → quiz view.
      - Secondary **Browse all clubs** — `background: rgba(255,255,255,0.08)`, `1.5px solid rgba(255,255,255,0.7)` border, color `#fff` → browse view.

---

## Interactions & Behavior
- **Buttons** navigate into the existing app (no new routes needed): quiz buttons → the "Help me choose" quiz; browse buttons → the club directory. In the current app these are the `setQuiz` / `setBrowse` handlers on the `Component`.
- **Responsive:** switch layouts at a **768px** breakpoint (≤768px = phone hero, >768px = desktop two-doors). Both layouts are static — no internal animations required. (Optional: a subtle fade-in on mount, matching the app's existing `dc-fade-in` keyframe.)
- No loading, error, or form states — this is a static entry screen.
- Consider making the landing the initial view and letting the user skip it (any button) into the app; the app's existing `view` state is the natural place to add a `'landing'` value.

## State Management
- One addition: an initial `view === 'landing'` (or a `hasSeenLanding` flag) so the app opens on the landing page and both button groups set `view` to `'quiz'` or `'browse'`. No data fetching on this screen.

## Design Tokens
**Colors**
- Navy (primary) `#00457c`
- Navy dark (headings/wordmark) `#00335c`
- Deep navy (overlays) `#001f3d` / `rgba(0,31,61,*)` and `rgba(0,45,84,*)`
- Gold (accent) `#f0b323`
- Heading near-black `#1a2330` / `#1a2c39`
- Body grey `#5a6570`; muted `#54636e`
- Card border `#d9dde2`; header border `#eef2f5`; divider `#e2e8ee`
- Light text on photo `#eef4fa` / `#eaf1f8`; white `#fff`

**Typography**
- Display / headings / buttons / eyebrows: **Archivo** (weights 500–800). Google Fonts.
- Body / nav / sub-lines: **Public Sans** (400–600, plus italic). Google Fonts.
- Italic script accent (the word "TrojanMatch" in headings): **Playfair Display** italic 700. Google Fonts.
- (These are the fonts the existing app already loads — Archivo + Public Sans; Playfair Display is the only new addition, used solely for the gold "TrojanMatch" accent.)

**Photo treatment (reused everywhere a WHS photo appears)**
- `object-fit: cover` + `filter: saturate(1.14) brightness(1.08)` + a navy gradient overlay for text contrast.

**Radii**: cards `4px`; buttons `8px`.

**Breakpoint**: `768px`.

## Assets
- `assets/wayzata-high-school-logo.png` — WHS horizontal lockup (navy trojan + "Wayzata High School" + "We're here for you."). Already in the repo at `assets/wayzata-high-school-logo.png`.
- `assets/whs-fog.jpg` — Wayzata High School at sunrise in fog (the chosen hero photo). Provided by the school; included in this bundle. Original is 3875×2906. Desktop uses `object-position: center 40%`; phone uses `object-position: 16% 40%` to reveal the building's Trojan "W".
- Fonts load from Google Fonts (same `<link>` the app already uses, with `Playfair+Display:ital,wght@1,600;1,700` added).

## Files
- `TrojanMatch Landing.dc.html` — the working responsive prototype (both layouts, media-query toggled). Open it in a browser and resize past 768px to see desktop vs. phone.
- `assets/` — the two images referenced above.
- In the live project, the existing app lives in `index.html`; integrate the landing there (or as a sibling view) following its inline-style dc conventions.
