# Matching tests

Runs the real `scoreClubs` out of `index.html` against the real 81 rows in
`uploads/clubs.json`. Nothing about the scoring is reimplemented here — the
harness lifts the component class straight out of the page and stubs only the
browser globals it touches — so a passing run means the shipped code passes.

```
cd frontend/docs/matching-tests
node run.js       # both suites, plus which clubs are hogging the top 5
node edge.js      # empty input, gibberish, emoji, every chip at once
node verify.js    # tokens per submission, measured on the shipped payload
```

## The two suites

`cases.js` is the set the changes were tuned against. `cases2.js` was written
afterwards and run once, so it measures whether the tuning generalised rather
than how well it was fitted. Keep that split: if you tune against a case, move
it out of `cases2.js`.

A case lists `must` (clubs a reasonable person expects in the top 5) and
`never` (clubs that would be an obvious miss). Both are deliberately
uncontroversial — no case asserts which of two equally good clubs should win.

## Where it stood on 2026-08-11

| | tuning | held-out | total |
|---|---|---|---|
| before | 43/47 | 35/38 | 78/85 |
| after | 47/47 | 38/38 | 85/85 |

Tokens per submission over the same 85 profiles: mean 608 → 568, worst case
1074 → 796. Candidate count is unchanged at 8, or 10 when the student typed
something.

## Known weak spots

- **Letters of Love** reaches rank 5 for "cards for kids in the hospital" but
  rank 19 for "writing letters to people in hospitals", because "letters"
  reads as journalism to the keyword map.
- **Band, Choirs and Orchestras** are separated only by their `interests` text.
  The score vector has one `arts_creative` dimension and cannot tell them
  apart, so if someone strips the instrument lists out of `interests` those
  three collapse into an alphabetical tie again.
- `interests` is never shown to students. It exists to be matched against.
  Write it with the words a student would actually type.
