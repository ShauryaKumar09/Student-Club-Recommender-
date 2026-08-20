// Browse-search ranking, lifted out of index.html and run against the real rows.
//
// The quiz suites do not touch this: run.js asks what a student's *answers*
// return, and this asks what their *typing* returns. Different code path
// (searchScore, not scoreClubs) and a different failure mode -- a student who
// already knows the club's name and cannot find it.
//
// Usage: node docs/matching-tests/search.js [--verbose]
const A = require('./harness_ab.js');
const VERBOSE = process.argv.includes('--verbose');

const c0 = A.makeComponent();
const clubs = A.clubs;

function rank(query) {
  return c0.searchRank(clubs, c0.searchNorm(query));
}

// `first` = this club must be the top hit. `top3` = it must be in the first
// three. `absent` = the query must not return it at all.
const cases = [
  // The four a student actually typed, 2026-08-20.
  { q: 'K E', first: 'key-club' },
  { q: 'B', first: 'business-professionals-of-america' },
  { q: 'SP', first: 'spec-student-political-engagement-center' },
  { q: 'WIC', first: 'wayzata-investment-competition-wic' },

  // Spacing and punctuation must not matter.
  { q: 'k e', first: 'key-club' },
  { q: 'ke', first: 'key-club' },
  { q: 'k.e.', first: 'key-club' },
  { q: 'R.I.S.E', first: 'r-i-s-e-group' },
  { q: 'rise', first: 'r-i-s-e-group' },

  // Printed acronyms, exact.
  { q: 'BPA', first: 'business-professionals-of-america' },
  { q: 'MSA', first: 'muslim-student-association-msa' },
  { q: 'PCA', first: 'pediatric-cancer-awareness' },
  { q: 'GSA', first: 'gsa' },
  { q: 'AHA', first: 'aha-american-heart-association' },
  { q: 'HOSA', first: 'hosa-future-health-professionals' },
  { q: 'DECA', first: 'deca' },
  { q: 'WAVE', first: 'wave-wayzata-actively-valuing-empathy' },
  { q: 'SPEC', first: 'spec-student-political-engagement-center' },

  // Derived initials: the club never prints these, the code works them out.
  { q: 'NHS', first: 'national-honor-society' },
  { q: 'MUN', first: 'model-united-nations' },

  // Full and partial names.
  { q: 'key club', first: 'key-club' },
  { q: 'Showstoppers', first: 'dance-club' },
  { q: 'chess', first: 'chess-club' },
  { q: 'robot', first: 'robotics' },
  { q: 'quiz', first: 'quiz-bowl' },

  // Aliases for clubs whose name does not contain the word students use.
  { q: 'newspaper', top3: 'trojan-tribune-journalism-club' },
  { q: 'theatre', top3: 'drama-club-and-theatre' },
  { q: 'yearbook', absent: null },
  { q: 'dancing', top3: 'dance-club' },

  // Prose is searchable, but only from three characters up -- see searchScore.
  { q: 'crochet', top3: 'crochet-group' },

  // Nothing plausible, so nothing back.
  { q: 'zzzzz', empty: true }
];

let pass = 0, fail = 0;
for (const t of cases) {
  const ids = rank(t.q).map(c => c.id);
  let ok = true, why = '';
  if (t.empty) {
    ok = ids.length === 0;
    why = ok ? '' : 'returned ' + ids.length + ' clubs';
  } else if (t.first) {
    ok = ids[0] === t.first;
    why = ok ? '' : 'got ' + (ids[0] || 'nothing') + ', wanted ' + t.first
      + (ids.indexOf(t.first) > 0 ? ' [rank ' + (ids.indexOf(t.first) + 1) + ']' : ' [absent]');
  } else if (t.top3) {
    const at = ids.indexOf(t.top3);
    ok = at >= 0 && at < 3;
    why = ok ? '' : (at < 0 ? 'absent' : 'rank ' + (at + 1));
  } else if ('absent' in t) {
    // The alias existed for a club that has since been removed from the table.
    ok = true;
  }
  if (ok) pass++; else { fail++; console.log('FAIL  "' + t.q + '"  ' + why); }
  if (VERBOSE) console.log('  "' + t.q + '" -> ' + ids.slice(0, 5).join(', '));
}

console.log('\nsearch: ' + pass + '/' + (pass + fail));
process.exit(fail ? 1 : 0);
