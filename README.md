# TrojanMatch

TrojanMatch is a single-page web app for Wayzata High School that helps students find clubs. It has two modes:

- **Browse clubs** — a searchable, category-filtered directory of every club.
- **Help me choose** — a 3-step quiz ("What sounds like you?", "How do you like to work?", "Future plans?") that scores every club against the student's answers and returns a ranked, percentage-matched shortlist, each with a one-sentence AI-written "why this fits" explanation.

Made by Shaurya Kumar and Nayan Menon.

## How it's built

This is **not** a normal JS framework project — there's no `package.json`, no bundler, no `npm install`. It's a single static file, [index.html](index.html), authored in a template format called **"dc" (declarative component)**: HTML markup with `{{ expression }}` interpolations, `<sc-if>`/`<sc-for>` control-flow tags, and a `<script type="text/x-dc">` block containing a plain JS class (`Component`) that drives it. [support.js](support.js) is the runtime that parses that format and renders it as a React app in the browser (it's generated output — the file's own header says "GENERATED from dc-runtime/src/*.ts — do not edit").

Practically, that means:

- **[index.html](index.html)** is the entire app: markup, styles (inline `style="..."` + a `<style>` block for the `@media (max-width: 640px)` phone layout), and all application logic (state, the matching algorithm, event handlers) inside the trailing `<script>` tag's `Component` class.
- **[support.js](support.js)** is vendored infrastructure, not app code. It loads React/ReactDOM/Babel from a CDN, compiles the `{{ }}` template syntax into React elements, and manages component state/re-rendering. You should essentially never need to touch it.
- There's no build step. Opening `index.html` in a browser (or serving the folder statically) is the entire deployment.

## Architecture

```
Browser (index.html + support.js)
   │
   ├─ GET  {SUPABASE_URL}/rest/v1/clubs        →  Supabase Postgres "clubs" table (read-only, anon key)
   │        (falls back to uploads/clubs.json if Supabase is unreachable/empty)
   │
   └─ POST {SUPABASE_URL}/functions/v1/match-clubs  →  Supabase Edge Function ("match-clubs")
            │
            └─ POST api.groq.com  (Groq-hosted LLM, openai/gpt-oss-20b)
                     — writes one "why this fits" sentence per shortlisted club
                     — holds the Groq API key server-side (secret, never shipped to the browser)
```

Data source: [uploads/clubs.json](uploads/clubs.json) is the source of truth for club content and score vectors. The Supabase `clubs` table is a copy of it (kept in sync manually — see [supabase/update-scores.sql](supabase/update-scores.sql) and [supabase/update-instagram.sql](supabase/update-instagram.sql)). The live site reads from Supabase first and only falls back to the bundled JSON file if that fetch fails or returns zero rows (e.g. a misconfigured Row Level Security policy).

### Why matching is split between the browser and the server

**All ranking and scoring happens locally in the browser**, deterministically, from each club's score vector — see `scoreClubs()` in `index.html`. Given the same answers, it always produces the same order and the same match percentages.

**The LLM (via the Supabase Edge Function) is never allowed to rank, score, add, or remove clubs.** It only receives the shortlist the local scorer already produced (just `id`, `name`, and the first sentence of each club's `description`) and writes one short "why this fits" sentence per club, referencing the student's stated interests/career goals in their own words. This split exists because:

1. Letting the model rank made results non-deterministic — a club could land at #4/82% one run and #1/92% on an identical re-submit.
2. Sending only a 6-club shortlist (vs. the whole catalogue with score vectors) uses roughly a tenth of the tokens of a full ranking call, which matters because the app runs on Groq's free tier (rate-limited per minute/day).

If the Edge Function call fails or times out (6s timeout), the UI simply falls back to showing which of the student's picked interest/career chips matched — the ranking and percentages, which are already computed locally, are unaffected.

## The scoring model

Each club has a **score vector** (`scores` field, 0–5 per dimension) across 20 dimensions, stored in [uploads/clubs.json](uploads/clubs.json) / the Supabase table:

**Topic dimensions** (15) — what the club is about: `business_entrepreneurship`, `computer_science_tech`, `science_stem`, `arts_creative`, `community_service`, `cultural_identity`, `academic_competition`, `health_medical`, `writing_media_journalism`, `environmental_sustainability`, `leadership_government`, `social_special_interest`, `world_languages`, `sports_recreation`, `trades_technical`.

**Style dimensions** (5) — how the club operates: `competitiveness`, `time_commitment`, `team_vs_individual`, `public_speaking_emphasis`, `leadership_opportunity`.

The quiz builds a **student interest vector** from three inputs, all merged into the same topic-dimension space:

1. **Interest chips** (Step 1) and **career chips** (Step 3) — each chip declares which topic dimensions it contributes to and by how much (`topicChips` / `careerChips` in `index.html`). Career picks are weighted 1.5x higher than interest chips (`careerWeightBoost`) — deliberately choosing a career path to explore is treated as a stronger signal than a casual interest.
2. **Free-text answers** (Step 3, "Anything else you're into?") — typed words are matched against a hand-built keyword→dimension map (`keywordDims`, ~150 stems like `nurs`, `robot`, `entrepreneur`) using prefix matching, so "nursing" or "nurse" both hit the `nurs` stem. This is what lets typing "I want to be a nurse" surface HOSA even though no club description literally contains the word "nurse" — the mapping supplies the semantic link, deterministically and without calling any model.

**Topic fit** is the cosine similarity between the student's interest vector and each club's topic score vector — chosen specifically so a specialized club (e.g. HOSA) isn't penalized for interests it doesn't cover just because the student also picked unrelated chips.

**Style fit** is computed per answered question as a closeness score, with asymmetric gaps: a club demanding *more* time commitment or public speaking than requested counts as a bigger mismatch than a club offering *less*; a club offering *more* leadership than requested costs nothing.

**Free-text fit** additionally does a literal substring/stem check against each club's name/category/description/interests, and can only ever pull a club's score *up*, never down.

The three are blended (`raw = 0.68·topicFit + 0.32·styleFit`, then nudged up by free-text hits) into a single score used for both the sort order and the displayed match percentage.

## Project layout

```
index.html                        The entire app: markup + styles + Component logic
support.js                        Vendored dc-runtime (generated — do not hand-edit)
uploads/clubs.json                Source-of-truth club data (id, name, category, advisor,
                                   description, targetAudience, detailedDescription,
                                   interests[], scores{}, instagram, email, phone)
uploads/*.png                     Pasted screenshots, unrelated to app assets
assets/wayzata-high-school-logo.png   Header logo
assets/wayzata-trojan.png             Loading-spinner mascot art
supabase/functions/match-clubs/index.ts   Edge Function: writes match reasons via Groq
supabase/update-scores.sql        One-off SQL to push clubs.json score vectors into Supabase
supabase/update-instagram.sql     One-off SQL to push Instagram handles into Supabase
supabase/update-form-submissions.sql    Club-info form responses through 2026-08-07
supabase/update-form-submissions-2.sql  Club-info form responses 2026-08-08 to 08-10
```

## Running it locally

No build step, no dependencies to install. From the project root:

```bash
python3 -m http.server 8000
# then open http://localhost:8000/index.html
```

(Any static file server works — `npx serve`, VS Code's Live Server, etc. Opening the file directly via `file://` also mostly works, but a local server avoids any fetch/CORS quirks.)

The app will try to load clubs from the live Supabase project (URL and **publishable/anon** key are hard-coded in `index.html` — this is intentional and safe, since the anon role only has read access enforced by Postgres Row Level Security). If that fetch fails, it automatically falls back to the bundled [uploads/clubs.json](uploads/clubs.json), so the browse/quiz experience works fully offline — the only feature that needs the network is the AI-written "why this fits" sentences from the Edge Function, which degrade gracefully to showing matched interest labels instead.

## Editing club data

[uploads/clubs.json](uploads/clubs.json) is the source of truth. To add or edit a club:

1. Add/edit an entry in `uploads/clubs.json` with the shape shown above, including a full `scores` object across all 20 dimensions (0–5 each).
2. If the live site should reflect the change, also update the Supabase `clubs` table — either by hand or by generating a new `update ... set scores = '...'::jsonb where id = '...'` statement (see [supabase/update-scores.sql](supabase/update-scores.sql) for the pattern) and running it in the Supabase SQL editor. Writes are blocked for the anon key by RLS, so this must be done from the Supabase dashboard, not from the browser app.
3. Category must be one of the six fixed values in `Component.categories` in `index.html` (`Academic Competition`, `CTE`, `Language & Culture`, `Service & Leadership`, `Performance Arts`, `Visual & Written Arts`) — the browse sidebar and category counts are driven off that fixed list.

## Deploying the Edge Function

The `match-clubs` function (`supabase/functions/match-clubs/index.ts`) runs on Supabase and needs a Groq API key as a secret:

```bash
supabase secrets set GROQ_API_KEY=gsk_...
supabase functions deploy match-clubs --no-verify-jwt
```

`--no-verify-jwt` is required — the frontend calls it without an auth header, matching `MATCH_CLUBS_URL` in `index.html`.

## Analytics

Google Analytics (`gtag.js`, measurement ID `G-DSQFDSKKDQ`) is loaded in `<head>`. A single custom event, `quiz_submitted`, fires when a student submits the quiz, recording how many interest/career chips they picked and whether they typed free text (no free-text content itself is sent). It's guarded against ad blockers removing `gtag` entirely.
