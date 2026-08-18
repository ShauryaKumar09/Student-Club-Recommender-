// Grid over the scoring constants. Reports tuning and held-out separately so a
// setting that only helps by memorising the tuning cases is visible as a
// held-out drop rather than as an improvement.
const A = require('./harness_ab.js');
const cases1 = require('./cases.js'), cases2 = require('./cases2.js');
function score(overrides) {
  const run = set => set.reduce((acc, t) => {
    const c = A.makeComponent();
    Object.assign(c, overrides);
    const s = Object.assign({}, c.state, { clubs: A.clubs, selected: t.chips || [],
      selectedCareers: t.careers || [], styleAnswers: t.style || {}, custom: t.text || '' });
    const ids = c.scoreClubs(s).scored.slice(0, 5).map(r => r.c.id);
    const ok = (t.must || []).every(m => ids.includes(m)) && !(t.never || []).some(n => ids.includes(n));
    return acc + (ok ? 1 : 0);
  }, 0);
  return { tune: run(cases1), held: run(cases2) };
}
const base = score({});
console.log('baseline  tuning %d/%d  held-out %d/%d\n', base.tune, cases1.length, base.held, cases2.length);
const rows = [];
for (const damp of [0.10, 0.15, 0.20, 0.25, 0.30, 0.40])
  for (const aff of [0.08, 0.10, 0.12, 0.15, 0.18])
    for (const nmw of [0.5, 0.6, 0.7]) {
      const r = score({ offTopicDamping: damp, affinityWeight: aff, nameMatchWeight: nmw });
      rows.push({ damp, aff, nmw, ...r, total: r.tune + r.held });
    }
rows.sort((a, b) => b.held - a.held || b.total - a.total);
console.log('damping  affinity  nameW   tuning  held-out  total');
rows.slice(0, 12).forEach(r => console.log(
  `  ${r.damp.toFixed(2)}     ${r.aff.toFixed(2)}     ${r.nmw.toFixed(2)}    ${r.tune}/${cases1.length}   ${r.held}/${cases2.length}     ${r.total}/${cases1.length + cases2.length}`));
const best = rows[0];
console.log(`\nbest by held-out then total: damping ${best.damp}, affinity ${best.aff}, nameWeight ${best.nmw}`);
