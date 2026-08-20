# Matching tests

Runs the real `scoreClubs` and `searchScore` out of `index.html` against the
real rows in `uploads/clubs.json` (86 of them as of 2026-08-20). Nothing is
reimplemented here — the harness lifts the component class straight out of the
page and stubs only the browser globals it touches — so a passing run means the
shipped code passes.

```
cd frontend/docs/matching-tests
node run.js       # both suites, plus which clubs are hogging the top 5
node reach.js     # can a student GET to each club? name search, ideal student
node edge.js      # empty input, gibberish, emoji, every chip at once
node verify.js    # tokens per submission, measured on the shipped payload
node audit.js     # data defects: unreachable clubs, thin matching text, gaps
node sweep.js     # grid over the scoring constants, tuning vs held-out
node search.js    # the browse search bar: acronyms, initials, partial names
```

`run.js` asks whether the ranking is right. `reach.js` asks the opposite
question -- for every club in the table, is there any input that surfaces it --
which is how the name-match bug below was found: no case in either suite
happened to type a club's name, so nothing caught that seventeen of them did
not come back first when you did.

`search.js` covers a different code path and a different student. `run.js` is
about someone who answers the quiz; `search.js` is about someone who already
knows the club and is typing at the browse bar. Nothing links the two, so a
change to `scoreClubs` cannot break search and a change to `searchScore` cannot
break the quiz -- but both have to pass before a scoring change ships.

## The two suites

`cases.js` is the set the changes were tuned against. `cases2.js` was written
afterwards and run once, so it measures whether the tuning generalised rather
than how well it was fitted. Keep that split: if you tune against a case, move
it out of `cases2.js`.

A case lists `must` (clubs a reasonable person expects in the top 5) and
`never` (clubs that would be an obvious miss). Both are deliberately
uncontroversial — no case asserts which of two equally good clubs should win.

## Where it stands

| | tuning | held-out | total |
|---|---|---|---|
| before any of this work | 45/55 | 35/38 | **80/93** |
| after two rounds | 55/55 | 38/38 | **93/93** |
| on 87 clubs and 100 cases | 61/62 | 38/38 | **99/100** |
| now, on 86 clubs and 102 cases | 63/64 | 38/38 | **101/102** |

The totals are not comparable across rows: the table grew from 81 clubs to 88
and back down to 86, four clubs have been deleted out from under a case, and
cases have been added each round. The one standing failure is "STEM +
healthcare", which puts Biology Club sixth behind five clubs that are more
purely medical. `sweep.js` says no setting of the three constants fixes it
without costing more elsewhere.

`search.js` is at **31/31**, including the four queries a student typed on
2026-08-20 that the old substring search got wrong.

`reach.js` is the stronger statement, and it passes: **all 86 clubs come back
first when you search their own name, all 86 are reachable in the top 5 by the
student they are for, and none is filtered out by the relevance gate.**

One club -- Forget Me Not -- cannot be surfaced by any single chip or chip
pair. That is a slot shortage rather than a defect: there are fifteen service
clubs and five slots, and it does surface once the style questions are
answered.

Tokens per submission: mean 614 → 575 → **552**, worst case 1074 → 790 →
**746**. Worst case is the number that matters against a per-minute rate limit.
The last step came from dropping the typed-submission candidate count from 10
to 9; `verify.js` now reads that number out of `index.html` instead of
repeating it, because it was hardcoded and went stale.

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
- **A club's name is scored separately from its write-up.** Typing a name that
  accounts for the whole of a club's distinctive name is treated as asking for
  that club, and lifted above the range ordinary topical scoring reaches. The
  words every name shares -- club, group, team, Wayzata -- are stripped from
  both sides first, so "club" on its own still matches nobody. Before this,
  typing "Band" returned Art Club: the two share a keyword vector and nothing
  marked Band as the thing being asked for.
- **Dotted acronyms are flattened before tokenising.** "R.I.S.E" became four
  one-letter tokens that the three-character filter then dropped, so R.I.S.E
  Group could not be found by typing its own name.

## Things worth knowing before you change the search bar

- **Tiers, not one big `includes()`.** `searchScore` scores a club by how
  deliberate the match is: an acronym the club prints in its own name (SPEC,
  BPA, WIC) beats initials this code derived on its behalf (NHS, MUN), which
  beats the start of the name, which beats a word inside it, which beats prose.
  Adding a tier means picking where in that order it belongs.
- **Everything is compared on letters and digits only.** "K E", "k.e." and "ke"
  are one query. The old search compared raw strings, so a student typing a
  space between two initials got nothing at all.
- **Prose only joins in from three characters up.** One- and two-letter queries
  are initials, and matching "b" against 86 descriptions buries the club the
  student was reaching for.
- **A search returns one ranked list, not category sections.** Order is the
  answer; grouping by category during a search scatters the good matches behind
  whichever category sorts first.
- **`extraAcronyms` is keyed by club id.** A typo there is a silent dead alias
  -- `trojan-tribune` sat in that map for weeks doing nothing, because the id
  ends `-journalism-club`.

## Known limitations

- "I want to make cards for sick children" puts Letters of Love third rather
  than first; two other phrasings of the same intent put it first and second.
- A club carrying a stray 1 on an unrelated dimension still loses a hair to an
  otherwise identical club that does not. `offTopicDamping` reduced this from
  decisive to cosmetic; it did not remove it.
