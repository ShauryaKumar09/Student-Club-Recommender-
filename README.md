<div align="center">

<img src="assets/wayzata-high-school-logo.png" alt="Wayzata High School" height="72">

# TrojanMatch

**Find your club at Wayzata High School.**

[![Live site](https://img.shields.io/badge/live-trojanmatch.vercel.app-0b6cff?style=flat-square)](https://trojanmatch.vercel.app)
[![Clubs](https://img.shields.io/badge/clubs-86-f0b323?style=flat-square)](https://trojanmatch.vercel.app)
[![Build step](https://img.shields.io/badge/build%20step-none-brightgreen?style=flat-square)](#how-its-built)
[![Matching tests](https://img.shields.io/badge/matching%20tests-102%20cases-00457c?style=flat-square)](docs/matching-tests/README.md)
[![Data](https://img.shields.io/badge/data-Supabase-3ecf8e?style=flat-square)](https://supabase.com)

</div>

---

TrojanMatch is a single-page web app that helps Wayzata students find a club worth joining. Three ways in:

| | |
|---|---|
| **Browse clubs** | Searchable directory of all 86 clubs, filterable by category and by club type, each with photos, meeting times, advisor, and Instagram. |
| **Help me choose** | A 3-step quiz — *What sounds like you?* / *How do you like to work?* / *Future plans?* — that scores every club against the answers and returns a ranked shortlist, each with a one-sentence "why this fits". |
| **Club of the day** | A club is spotlighted on the landing page, picked deterministically per calendar day from the clubs that have photos, so everyone sees the same one and it rotates on its own. |

Students can also report a bug or submit a new/updated club from the footer; both post to a Google Sheet.

Made by Shaurya Kumar and Nayan Menon.

## Quick start

No dependencies, no build step, nothing to install.

```bash
git clone https://github.com/ShauryaKumar09/Student-Club-Recommender-.git
cd Student-Club-Recommender-
python3 -m http.server 8000
# open http://localhost:8000/index.html
```

Any static server works (`npx serve`, VS Code Live Server). `file://` mostly works too, but a server avoids fetch/CORS quirks.

The app loads clubs from the live Supabase project — the URL and **publishable/anon** key are hard-coded in `index.html` on purpose, because Row Level Security limits the anon role to read-only `SELECT`. If that fetch fails or returns zero rows it falls back to the bundled [`uploads/clubs.json`](uploads/clubs.json), so browse and the quiz work fully offline. Only the AI-written "why this fits" sentences need the network, and they degrade to showing which chips matched.

## How it's built

This is **not** a normal JS project — no `package.json`, no bundler, no `npm install`. It is one static file, [`index.html`](index.html) (~3,500 lines), authored in a template format called **dc (declarative component)**: HTML with `{{ expression }}` interpolation, `<sc-if>` / `<sc-for>` control-flow tags, and a `<script type="text/x-dc">` block holding a plain JS class (`Component`) that drives it.

- **[`index.html`](index.html)** is the whole app: markup, styles, and every bit of logic — state, the matching algorithm, event handlers.
- **[`support.js`](support.js)** is the vendored dc-runtime. It pulls React/ReactDOM/Babel from a CDN, compiles the template syntax into React elements, and manages state. It is **generated output — do not hand-edit it.**
- Deployment is "serve the folder". Vercel does that automatically on every push to `main`.

## Architecture

```
Browser (index.html + support.js)
   │
   ├─ GET  {SUPABASE_URL}/rest/v1/clubs        →  Supabase Postgres "clubs" table (read-only, anon key)
   │        falls back to uploads/clubs.json if unreachable or empty
   │
   ├─ IMG  {SUPABASE_URL}/storage/v1/object/public/club-photos/…
   │        public bucket; each row's photos[] holds the URLs
   │
   ├─ POST {SUPABASE_URL}/functions/v1/match-clubs  →  Supabase Edge Function
   │        │
   │        └─ POST api.groq.com  (Groq, openai/gpt-oss-20b)
   │                 — orders the shortlist and writes one "why this fits" line per club
   │                 — holds the Groq API key server-side, never shipped to the browser
   │
   └─ POST script.google.com/…/exec  →  two Apps Script web apps → Google Sheets
            bug reports  (docs/bug-report-apps-script.gs)
            club add/update submissions  (docs/club-info-apps-script.gs)
```

## The matching model

### What ranks, and what the model is allowed to touch

Local scoring runs first and decides **which clubs are relevant at all** and which are worth asking about. `LLM_RANKING` (currently `true`) then lets the model **order the shortlist it is handed** and write the reasons. It never sees the full catalogue, never adds a club, and never removes one — everything past the shortlist keeps the place local scoring gave it. Flip `LLM_RANKING` to `false` to put the deterministic local order back with no redeploy and nothing to unpick.

> Ranking moved to the model on 2026-08-03. Local scoring reads chips well but reads a typed sentence literally, and a student's own words are the strongest signal in the form. Match percentages were removed from the UI at the same time: the number was a rescaling of a score, not a measurement of anything a student could act on. Results now show a rank and a reason.

The call is bounded: the shortlist is **9 clubs when the student typed something, 8 when they didn't**, each sent as `id`, `name`, and a description trimmed to 320 characters at a word boundary. Clubs go over the wire numbered and the model answers in numbers. If the request fails or exceeds its **8-second** timeout, the local order stands and the UI shows matched chip labels instead of written reasons.

### The score vectors

Every club carries a `scores` object, 0–5 on each of **21 dimensions**.

**Topic — what the club is about (16):** `business_entrepreneurship`, `computer_science_tech`, `science_stem`, `arts_creative`, `performing_arts`, `community_service`, `cultural_identity`, `academic_competition`, `health_medical`, `writing_media_journalism`, `environmental_sustainability`, `leadership_government`, `social_special_interest`, `world_languages`, `sports_recreation`, `trades_technical`.

> `performing_arts` was split out of `arts_creative` because one arts dimension made "Visual arts & design" and "Performing on stage" produce identical vectors — a student who wanted to draw got Band, Choirs and Orchestras ahead of clubs that actually draw.

**Style — how the club runs (5):** `competitiveness`, `time_commitment`, `team_vs_individual`, `public_speaking_emphasis`, `leadership_opportunity`.

### Building the student's vector

| Input | How it scores |
|---|---|
| **Interest chips** (step 1) | Each chip declares which topic dimensions it feeds and how strongly (`topicChips`). |
| **Career chips** (step 3) | Same mechanism (`careerChips`), weighted **1.5×** — deliberately picking a career path is a stronger signal than a casual interest. |
| **Free text** (step 3) | Matched against a hand-built keyword→dimension map (`keywordDims`, ~200 stems like `nurs`, `robot`, `entrepreneur`) by prefix, so "nursing" and "nurse" both hit `nurs`. This is what surfaces HOSA for "I want to be a nurse" without calling any model. |

### Blending

- **Topic fit** — cosine similarity between the student's vector and the club's topic vector, measured over the dimensions the student actually asked about. A club's *other* strengths still count, but at `0.25` weight (`offTopicDamping`) instead of full. A plain cosine charges a club for every activity nobody asked for, which punished the rows with the most honest data: Showstoppers (then called Dance Club) scored 0.845 for someone who typed "dancer" while Art Club scored 0.929, purely because it also carries `cultural_identity 1` and Art Club carries nothing else.
- **Style fit** — per answered question, with asymmetric gaps: a club demanding *more* time or public speaking than requested is a worse mismatch than one demanding less, and offering *more* leadership than asked costs nothing.
- **Free-text fit** — literal substring/stem hits against the club's name, category, description and interests. It can only pull a score **up**.
- **Name match** — typing a club's name is a request for that club, not a topic hint, so a full name match floors the score near the top. Added after `reach.js` found that **17 of 87 clubs did not come back first when you typed their own name**.

```
raw = 0.68·topicFit + 0.32·styleFit
raw = raw + (1 − raw)·0.35·customFit          # free text, upward only
raw = raw·(1 − 0.12) + 0.12·affinity          # category affinity
raw = name-match floor / lift                 # if the query names the club
```

## Tests

Everything in [`docs/matching-tests/`](docs/matching-tests/README.md) runs the **real** `scoreClubs` lifted out of `index.html` against the **real** rows in `uploads/clubs.json` — nothing is reimplemented, so a pass means the shipped code passes.

```bash
cd docs/matching-tests
node run.js      # 102 ground-truth cases (64 tuning + 38 held-out), plus top-5 hogging
node reach.js    # can a student GET to each club? own name, own ideal student, relevance gate
node edge.js     # empty input, gibberish, emoji, every chip at once
node verify.js   # tokens per submission, measured against the shipped payload
node audit.js    # data defects: unreachable clubs, thin matching text, missing fields
node sweep.js    # grid over the scoring constants, tuning vs held-out reported apart
node search.js   # the browse search bar: acronyms, initials, spacing, partial names
```

`cases.js` is the set the scoring was tuned against; `cases2.js` was written afterwards and run once, so it measures whether the tuning generalised. **Keep that split** — if you tune against a case, move it out of `cases2.js`.

Run `run.js`, `reach.js` and `verify.js` before pushing anything that touches scoring, and `search.js` before pushing anything that touches the browse search.

### The search bar is a separate thing from the quiz

Browse search does not go through `scoreClubs` at all. `searchScore` ranks in tiers, best first: an acronym the club prints in its own name (**SPEC**, **BPA**, **WIC**) beats initials derived from its words (**NHS**, **MUN**), which beats the start of the name, which beats a word inside it, which beats anything found in the description. Queries are compared on letters and digits only, so `K E`, `k.e.` and `ke` are one query, and prose only joins in from three characters up — below that a student is typing initials, and matching `b` against 86 descriptions would bury what they were reaching for. While a query is live the page shows one ranked list instead of category sections, because the order *is* the answer.

## Club data

**Supabase is the source of truth.** [`uploads/clubs.json`](uploads/clubs.json) is the bundled offline fallback and has to be resynced by hand after a data change.

A row: `id`, `name`, `category`, `advisor`, `description`, `target_audience`, `detailed_description`, `meeting_location`, `meeting_days`, `meeting_time`, `is_student_led`, `interests[]`, `scores{}`, `photos[]`, `instagram`, `email`, `phone`. The `select` in `index.html` aliases the snake_case columns to the camelCase names the app uses, so rows arrive in the same shape as the JSON file.

**Categories** (7, in display order): Academic Competition · CTE · Sports & Recreation · Language & Culture · Service & Leadership · Performance Arts · Visual & Written Arts. `categoryOrder` is only a hint — browse renders whatever categories the loaded rows actually have, so a new category added in Supabase appears on its own instead of hiding its clubs.

**Club types** are shown as tags and drive the type filter: **Official Club** (school-sanctioned), **Student Organized Group** (`is_student_led`), and **Curricular** (Band, Choirs, Orchestras — class first, club second). Each tag carries an ⓘ button explaining what it means.

**Photos** live in the public Supabase Storage bucket `club-photos`, named `<club-id>-N.png|jpg`, with the public URLs stored in the row's `photos` array. A club with no photos is never eligible for Club of the day.

To change data: edit the Supabase table (the anon key cannot write — RLS blocks it, so use the dashboard or a service-role script), keep one `.sql` file under [`supabase/`](supabase) recording the change, then resync `uploads/clubs.json`.

> **Note:** the `service_role` key is never committed, never logged, and never goes in `index.html`. The only key that belongs in client code is the `sb_publishable_…` one.

## Deploying

| Piece | How |
|---|---|
| **The site** | Vercel builds on every push to `main`; there is no manual step. Check it landed with `gh api repos/ShauryaKumar09/Student-Club-Recommender-/commits/main/status --jq .state`. |
| **Edge Function** | `supabase secrets set GROQ_API_KEY=gsk_…` then `supabase functions deploy match-clubs --no-verify-jwt`. `--no-verify-jwt` is required — the frontend calls it without an auth header. |
| **Apps Scripts** | Paste [`docs/bug-report-apps-script.gs`](docs/bug-report-apps-script.gs) / [`docs/club-info-apps-script.gs`](docs/club-info-apps-script.gs) into the script bound to the sheet, deploy a **new version**, and put the `/exec` URL in `BUG_REPORT_URL` / `CLUB_INFO_URL`. Editing the script without publishing a new version changes nothing. |

## The club editor (localhost)

`admin/index.html` is a separate, local-only page where an advisor edits their own club and an admin adds clubs. It is **excluded from the deploy** — `.vercelignore` keeps it out of the upload and `vercel.json` redirects `/admin/*` back to `/`, so it does not exist on trojanmatch.vercel.app.

```bash
cd admin && python3 -m http.server 8788
# open http://localhost:8788
```

**It does nothing until [`supabase/admin-auth-setup.sql`](supabase/admin-auth-setup.sql) has been run once by hand** in the Supabase SQL editor. That file is the whole security model, and it cannot be applied over the REST API because that API cannot run DDL. It creates:

| | |
|---|---|
| `admins` | who may edit anything and add clubs |
| `club_editors` | which email may edit which single club |
| policies on `clubs` | an advisor updates their row and nobody else's; insert and delete are admin-only |
| a trigger | an advisor cannot change `scores`, `category`, `is_student_led`, `photos` or `id` |

Sign-in is Supabase Auth: a Wayzata address plus a password the advisor creates, confirmed by an emailed link, with a magic link as an alternative. **Signing in grants nothing by itself.** Supabase has open signup, so anyone can create an account; authorization is membership in `club_editors` or `admins`, checked by the policies on every request. Someone with an account and no assignment signs in successfully and sees an empty page.

The scores trigger is the part worth understanding. Column privileges are per-role and every signed-in person is the same `authenticated` role, so they cannot separate an advisor from an admin. Without the trigger, an advisor editing their own club could edit their own matching vector — which is an advisor deciding where their club ranks in the quiz.

Two things must be set in the Supabase dashboard before the emails work:

- **Authentication → URL Configuration → Redirect URLs**: add `http://localhost:8788`, or the link in the email refuses to complete.
- **Authentication → Emails**: the built-in sender is rate-limited to a handful of messages per hour, which is fine for you and not fine for 37 advisors signing up in one afternoon. Point it at real SMTP before sending anyone there.

## Analytics

GA4 (`gtag.js`, `G-DSQFDSKKDQ`) loads in `<head>`, guarded against ad blockers removing `gtag`. One custom event, `quiz_submitted`, records how many interest and career chips were picked and whether free text was typed — **never the text itself**.

## Project layout

```
index.html                          The entire app: markup, styles, Component logic
support.js                          Vendored dc-runtime (GENERATED — do not hand-edit)
uploads/clubs.json                  Offline fallback snapshot of the clubs table
assets/                             Logo, Trojan mascot, favicons, header photo
admin/index.html                    Local-only club editor (never deployed)
docs/matching-tests/                Scoring test suites — see its own README
docs/bug-report-apps-script.gs      Apps Script behind the bug reporter
docs/club-info-apps-script.gs       Apps Script behind the add/update-a-club form
supabase/functions/match-clubs/     Edge Function: ranks the shortlist, writes reasons
supabase/admin-auth-setup.sql       Auth tables, RLS policies, the scores trigger
supabase/*.sql                      One file per data change, newest last
.vercelignore, vercel.json          Keep admin/ out of the public deployment
```
