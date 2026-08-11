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
node audit.js     # data defects: unreachable clubs, thin matching text, gaps
```

## The two suites

`cases.js` is the set the changes were tuned against. `cases2.js` was written
afterwards and run once, so it measures whether the tuning generalised rather
than how well it was fitted. Keep that split: if you tune against a case, move
it out of `cases2.js`.

A case lists `must` (clubs a reasonable person expects in the top 5) and
`never` (clubs that would be an obvious miss). Both are deliberately
uncontroversial — no case asserts which of two equally good clubs should win.

## Where it stands

Measured on the same 93 profiles, before and after two rounds of work:

| | tuning | held-out | total | clubs reaching a top 5 |
|---|---|---|---|---|
| before | 45/55 | 35/38 | **80/93** | 74 of 81 |
| after | 55/55 | 38/38 | **93/93** | 80 of 81 |

Tokens per submission over the same profiles: mean 614 → **575**, worst case
1074 → **781**. Candidate count unchanged at 8, or 10 when the student typed
something. Worst case is the number that matters against a per-minute rate
limit.

## Things worth knowing before you change the data

- **`interests` is never displayed to students.** It exists to be matched
  against. Write it with the words a student would actually type — instrument
  names, "a dancer", both spellings of theatre. `node audit.js` flags records
  with fewer than four entries.
- **Band, Choirs and Orchestras are separated only by their `interests` text.**
  All three are `performing_arts: 5` and the vector cannot tell them apart. The
  instrument lists are what routes "violin" to Orchestras and "trumpet" to
  Band. Three regression cases in `cases.js` fail loudly if those are stripped.
- **A club needs one topic dimension at 3 or above to be reachable at all.**
  Below that it fails the relevance gate for every possible set of answers.
  Wayzata She Leads sat there, invisible to the quiz, until 2026-08-11.
- **Descriptions are capped at 320 characters before they go to the model.**
  Long write-ups are free on the site and cost money in the quiz.

## Known limitations

- "I want to make cards for sick children" puts Letters of Love third rather
  than first; two other phrasings of the same intent put it first and second.
- A club carrying a stray 1 on an unrelated dimension still loses a hair to an
  otherwise identical club that does not. `offTopicDamping` reduced this from
  decisive to cosmetic; it did not remove it.
