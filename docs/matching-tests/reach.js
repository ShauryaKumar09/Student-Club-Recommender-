// Reachability sweep: can a student actually GET to each club?
//
// run.js measures accuracy on 93 hand-written cases. This asks the opposite
// question -- for every club in the table, is there any realistic quiz input
// that surfaces it -- so a club nobody can reach shows up as a hole rather than
// as a case nobody thought to write.
//
// Three passes, each stricter than the last:
//   chips   every single chip, every career, every chip pair  -> top 5
//   named   the club's own name typed into the box            -> rank 1
//   gate    does the club clear the relevance filter at all
//
// Usage: node docs/matching-tests/reach.js [--verbose]
const A = require('./harness_ab.js');
const VERBOSE = process.argv.includes('--verbose');

const c0 = A.makeComponent();
const chips = c0.topicChips.map(t => t.id);
const careers = c0.careerChips.map(t => t.id);
const clubs = A.clubs;
const topicDims = c0.topicScoreDims;
const TOP = 5;

// ---- pass 1: chip-driven ------------------------------------------------
const queries = [];
chips.forEach(id => queries.push({ label: 'chip:' + id, chips: [id] }));
careers.forEach(id => queries.push({ label: 'career:' + id, careers: [id] }));
for (let i = 0; i < chips.length; i++)
  for (let j = i + 1; j < chips.length; j++)
    queries.push({ label: `chips:${chips[i]}+${chips[j]}`, chips: [chips[i], chips[j]] });

const reachedBy = new Map();   // club id -> first query that surfaced it
const everRanked = new Set();  // club id -> appeared anywhere in a result list
for (const q of queries) {
  const r = A.rank(q);
  r.ids.forEach(id => everRanked.add(id));
  r.ids.slice(0, TOP).forEach(id => { if (!reachedBy.has(id)) reachedBy.set(id, q.label); });
}

// ---- pass 2: the club's own name --------------------------------------
// A student who knows what they want types its name. That has to work.
const nameRank = new Map();
for (const c of clubs) {
  const r = A.rank({ text: c.name });
  nameRank.set(c.id, r.ids.indexOf(c.id));
}

// ---- pass 2b: the club's own ideal student ----------------------------
// A single chip cannot surface every club: there are 87 clubs and 5 slots, and
// fifteen of them are service clubs. The fair question is not "does one chip
// find it" but "does the student this club is FOR find it" -- someone who ticks
// the club's own strongest subjects and answers the style questions the way the
// club actually runs. A club its own ideal student cannot reach is a real hole.
const DIM_CHIP = {
  business_entrepreneurship: 'business', computer_science_tech: 'tech',
  science_stem: 'science', arts_creative: 'visual', community_service: 'help',
  cultural_identity: 'culture', academic_competition: 'trivia', health_medical: 'health',
  writing_media_journalism: 'write', environmental_sustainability: 'enviro',
  leadership_government: 'lead', social_special_interest: 'gaming',
  world_languages: 'newlang', sports_recreation: 'sports', performing_arts: 'perform'
};
const DIM_CAREER = { trades_technical: 'c-trades' };
const STYLE = c0.styleDims.map(sd => sd.id);

function idealProfile(c) {
  const sc = c.scores || {};
  const top = topicDims.map(d => [d, sc[d] || 0]).filter(x => x[1] >= 3)
    .sort((a, b) => b[1] - a[1]).slice(0, 2);
  const q = { chips: [], careers: [], style: {} };
  top.forEach(([d]) => {
    if (DIM_CHIP[d]) q.chips.push(DIM_CHIP[d]);
    else if (DIM_CAREER[d]) q.careers.push(DIM_CAREER[d]);
  });
  STYLE.forEach(d => { if (sc[d] != null) q.style[d] = sc[d]; });
  return q;
}

const idealRank = new Map();
for (const c of clubs) idealRank.set(c.id, A.rank(idealProfile(c)).ids.indexOf(c.id));
const idealMiss = clubs.filter(c => { const r = idealRank.get(c.id); return r < 0 || r >= TOP; });

// ---- pass 3: the relevance gate ---------------------------------------
// related = namedInText || topicDims.some(dim => scores[dim] >= 3). With no
// topic dimension at 3+, only typing a matching word can ever surface the club.
const gated = clubs.filter(c => !topicDims.some(d => (c.scores || {})[d] >= 3));

// ---- report ------------------------------------------------------------
const unreachable = clubs.filter(c => !reachedBy.has(c.id));
const notFirstByName = clubs.filter(c => nameRank.get(c.id) !== 0);
const neverRanked = clubs.filter(c => !everRanked.has(c.id));

console.log(`${queries.length} chip/career queries over ${clubs.length} clubs\n`);

console.log(`top-${TOP} unreachable by any chip combination (${unreachable.length})`);
unreachable.forEach(c => {
  const best = topicDims.map(d => [d, (c.scores || {})[d] || 0]).sort((a, b) => b[1] - a[1])[0];
  console.log(`   ${c.name}  [best topic dim: ${best[0]} ${best[1]}]`);
});

console.log(`\nnever appears in ANY result list (${neverRanked.length})`);
neverRanked.forEach(c => console.log('   ' + c.name));

console.log(`\nits own ideal student does not reach it in the top ${TOP} (${idealMiss.length})`);
idealMiss.forEach(c => {
  const r = idealRank.get(c.id);
  console.log(`   ${c.name}  [${r < 0 ? 'absent' : 'rank ' + (r + 1)}]`);
});

console.log(`\nsearching the club's own name does not put it first (${notFirstByName.length})`);
notFirstByName.forEach(c => {
  const r = nameRank.get(c.id);
  console.log(`   ${c.name}  [${r < 0 ? 'absent' : 'rank ' + (r + 1)}]`);
});

console.log(`\nno topic dimension >= 3, so only free text can surface it (${gated.length})`);
gated.forEach(c => console.log('   ' + c.name));

if (VERBOSE) {
  console.log('\nhow each club is first reached');
  clubs.forEach(c => console.log(`   ${c.name.padEnd(46)} ${reachedBy.get(c.id) || 'NEVER'}`));
}

// The chip sweep above is reported for information only: with 87 clubs and five
// slots, one chip provably cannot surface all of them. The bar that has to hold
// is that every club is reachable by the student it is for, findable by name,
// and not filtered out by the relevance gate before it is ever ranked.
const ok = idealMiss.length === 0 && notFirstByName.length === 0 && gated.length === 0;
console.log('\n' + (ok ? 'PASS: every club is reachable' :
  `FAIL: ${idealMiss.length} unreachable by their own profile, `
  + `${notFirstByName.length} not first by name, ${gated.length} gated out`));
process.exit(ok ? 0 : 1);
