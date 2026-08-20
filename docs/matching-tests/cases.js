// Ground-truth quiz profiles. `must` = clubs a reasonable person would call a
// clear hit and expect in the top 5. `never` = clubs that would be an obvious
// miss in the top 5. Kept deliberately uncontroversial: no judgement calls
// about which of two equally good clubs should rank first.
module.exports = [
  // ---- single interest chip, the simplest possible input ----
  { name: 'coding & robotics', chips: ['tech'],
    must: ['robotics'], never: [] },
  { name: 'science & STEM', chips: ['science'],
    must: ['science-olympiad', 'science-bowl'], never: [] },
  { name: 'healthcare', chips: ['health'],
    must: ['hosa-future-health-professionals'], never: [] },
  { name: 'business', chips: ['business'],
    must: ['deca', 'business-professionals-of-america'], never: [] },
  { name: 'community service', chips: ['help'],
    must: ['volunteer-club'], never: [] },
  { name: 'leadership', chips: ['lead'],
    must: ['student-council'], never: [] },
  { name: 'creative writing', chips: ['write'],
    must: ['creative-writing-club'], never: [] },
  { name: 'visual arts', chips: ['visual'],
    must: ['art-club'], never: [] },
  { name: 'performing on stage', chips: ['perform'],
    must: ['drama-club-and-theatre'], never: [] },
  { name: 'new language', chips: ['newlang'],
    must: ['spanish-club'], never: [] },
  // International Club was the expected hit here until the school had it removed
  // (2026-08-20). It was the one club whose whole subject was world cultures in
  // general; everything left under Language & Culture is specific -- one nation,
  // one language or one faith each. No surviving club can be named as THE answer
  // to this chip, so the case now only asserts it does not wander off-subject.
  { name: 'world cultures', chips: ['culture'],
    must: [], never: ['robotics', 'math-team', 'deca'] },
  { name: 'environment', chips: ['enviro'],
    must: ['earthrise'], never: [] },
  { name: 'gaming & pop culture', chips: ['gaming'],
    must: ['esports'], never: [] },
  // This chip has outlived every club it originally matched: Cricket Group
  // disbanded (2026-08-11), Sports Talk Group was removed, and Trap & Skeet was
  // removed on 2026-08-20 because it is an athletics team listed on the athletics
  // site, not a club. That left nothing in the table scoring sports_recreation at
  // all, so Esports and Sports Promotional Team were scored at 3 -- Esports is
  // filed under Sports & Recreation, and Sports Promotional Team shoots the games.
  // Those two are now the whole of what this chip can return.
  { name: 'sports', chips: ['sports'],
    must: ['esports', 'sports-promotional-team'], never: [] },
  { name: 'debating', chips: ['debate'],
    must: ['debate'], never: [] },
  { name: 'trivia', chips: ['trivia'],
    must: ['quiz-bowl'], never: [] },
  { name: 'math & logic', chips: ['math'],
    must: ['math-team'], never: [] },
  { name: 'hands-on building', chips: ['build'],
    must: ['robotics'], never: [] },

  // ---- career chips ----
  { name: 'career: medicine', careers: ['c-health'],
    must: ['hosa-future-health-professionals'], never: [] },
  { name: 'career: software', careers: ['c-software'],
    must: ['robotics'], never: [] },
  { name: 'career: trades', careers: ['c-trades'],
    must: ['skills-usa'], never: [] },
  { name: 'career: law & politics', careers: ['c-law'],
    must: ['mock-trial', 'model-united-nations'], never: [] },
  { name: 'career: journalism', careers: ['c-media'],
    must: ['trojan-tribune-journalism-club'], never: [] },
  { name: 'career: business', careers: ['c-business'],
    must: ['deca'], never: [] },
  { name: 'career: teaching', careers: ['c-teach'],
    must: ['educators-rising'], never: [] },

  // ---- combinations, which is how the quiz is actually used ----
  { name: 'business + competitive', chips: ['business'], style: { competitiveness: 5 },
    must: ['deca', 'business-professionals-of-america'], never: [] },
  { name: 'debate + law career', chips: ['debate'], careers: ['c-law'],
    must: ['debate', 'mock-trial'], never: [] },
  { name: 'service + low time', chips: ['help'], style: { time_commitment: 1 },
    must: [], never: ['robotics', 'deca'] },
  { name: 'arts + writing', chips: ['visual', 'write'],
    must: ['creative-writing-club'], never: [] },
  { name: 'STEM + healthcare', chips: ['science', 'health'],
    must: ['biology-club'], never: [] },
  { name: 'culture + service', chips: ['culture', 'help'],
    must: [], never: ['robotics', 'math-team'] },

  // ---- free text, the case local scoring handles worst ----
  { name: 'text: "I want to be a nurse"', text: 'I want to be a nurse',
    must: ['nurses-of-tomorrow'], never: [] },
  { name: 'text: "I love singing"', text: 'I love singing',
    must: ['choirs'], never: [] },
  { name: 'text: "I play violin"', text: 'I play violin',
    must: ['orchestras'], never: [] },
  // Wayako Yearbook was the photography answer until it was removed from the
  // table. Sports Promotional Team is the shoot-and-edit club that remains.
  { name: 'text: "photography"', text: 'photography',
    must: ['sports-promotional-team'], never: [] },
  { name: 'text: "I like chess"', text: 'I like chess',
    must: ['chess-club'], never: [] },
  { name: 'text: "dancer"', text: 'dancer',
    must: ['dance-club'], never: [] },
  { name: 'text: "I want to start a business"', text: 'I want to start a business',
    must: ['deca', 'the-bizmark-exchange'], never: [] },
  { name: 'text: "video games"', text: 'video games',
    must: ['esports'], never: [] },
  { name: 'text: "crochet and knitting"', text: 'crochet and knitting',
    must: ['crochet-group'], never: [] },
  { name: 'text: "I want to help kids read"', text: 'I want to help kids read',
    must: [], never: ['robotics'] },

  // ---- realistic full submissions ----
  { name: 'full: pre-med sophomore', chips: ['health', 'science'], careers: ['c-health'],
    style: { competitiveness: 3, time_commitment: 3, team_vs_individual: 4 },
    text: 'I want to go into medicine and volunteer at a hospital',
    must: ['hosa-future-health-professionals'], never: [] },
  { name: 'full: engineering freshman', chips: ['build', 'tech'], careers: ['c-eng'],
    style: { competitiveness: 4, time_commitment: 4, team_vs_individual: 5 },
    text: 'I like building things and coding',
    must: ['robotics'], never: [] },
  { name: 'full: artist, low pressure', chips: ['visual'], careers: ['c-arts'],
    style: { competitiveness: 1, time_commitment: 2, team_vs_individual: 2 },
    text: 'drawing and painting',
    must: ['art-club'], never: [] },
  { name: 'full: future lawyer', chips: ['debate', 'lead'], careers: ['c-law'],
    style: { competitiveness: 5, public_speaking_emphasis: 5 },
    text: 'I want to be a lawyer and argue cases',
    must: ['mock-trial', 'debate'], never: [] },
  { name: 'full: musician', chips: ['perform'], careers: ['c-arts'],
    text: 'I play trumpet in band and want to keep performing',
    must: ['band'], never: [] },
  { name: 'full: shy volunteer', chips: ['help'],
    style: { public_speaking_emphasis: 1, competitiveness: 1, team_vs_individual: 2 },
    text: 'I want to give back but I am quiet',
    must: [], never: ['debate', 'speech'] },

  // ---- regressions for the two weak spots documented on 2026-08-11 ----
  // "letters" used to read as journalism, burying the club called Letters of
  // Love at rank 19 behind the newspaper and the literary magazine.
  { name: 'regress: letters to hospitals', text: 'writing letters to people in hospitals',
    must: ['letters-of-love'], never: [] },
  { name: 'regress: cards for kids in hospital', text: 'cards for kids in the hospital',
    must: ['letters-of-love'], never: [] },
  { name: 'regress: make cards for sick children', text: 'I want to make cards for sick children',
    must: ['letters-of-love'], never: [] },
  // One arts dimension made these two chips synonyms, so each returned the
  // other's clubs. They must now be disjoint at the top.
  { name: 'regress: visual chip excludes performers', chips: ['visual'],
    must: ['art-club'], never: ['band', 'choirs', 'orchestras', 'the-elite-pressure-line'] },
  { name: 'regress: perform chip excludes visual', chips: ['perform'],
    must: ['drama-club-and-theatre'], never: ['art-club', 'crochet-group', 'beads-of-serenity'] },
  // These three are separated only by the instrument words in `interests`.
  // If someone strips those, these three fail and the reason is in the README.
  { name: 'regress: violin -> orchestras', text: 'I play violin',
    must: ['orchestras'], never: [] },
  { name: 'regress: trumpet -> band', text: 'I play trumpet',
    must: ['band'], never: [] },
  { name: 'regress: singing -> choirs', text: 'I love singing',
    must: ['choirs'], never: [] },

  // Words students type that used to return an empty page or the wrong club.
  // Found by probing the live table rather than by writing cases first, so they
  // sit in the tuning set: the keyword weights were chosen against them.
  // reach.js covers the name search for all 87 clubs and is the stronger guard.
  { name: 'vocab: "chorus" reaches Choirs', text: 'chorus',
    must: ['choirs'], never: [] },
  { name: 'vocab: "religion" reaches the faith groups', text: 'religion',
    must: ['we-have-spirit-bible-study'], never: [] },
  { name: 'vocab: "mental health" is not read as pre-med', text: 'mental health',
    must: ['stress-management'], never: [] },
  { name: 'vocab: "wellness" reaches Stress Management', text: 'wellness',
    must: ['stress-management'], never: [] },
  { name: 'vocab: "poems" reaches the literary magazine', text: 'writing poems',
    must: ['creative-writing-club'], never: [] },
  // Typing a club's name is a request for that club, not a topic hint.
  { name: 'name: "Band" outranks the other arts clubs', text: 'Band',
    must: ['band'], never: [] },
  { name: 'name: dotted acronym still tokenises', text: 'R.I.S.E',
    must: ['r-i-s-e-group'], never: [] },
  // Dance Club was renamed Showstoppers on 2026-08-20, which is what the group
  // is actually called. The row id is still dance-club. The name no longer
  // contains the word "dance", so these two cases guard both routes to it: the
  // new name, and the word a student is far more likely to type.
  { name: 'name: "Showstoppers" reaches the dance group', text: 'Showstoppers',
    must: ['dance-club'], never: [] },
  { name: 'vocab: "dance" still reaches it after the rename', text: 'dance',
    must: ['dance-club'], never: [] }
];
