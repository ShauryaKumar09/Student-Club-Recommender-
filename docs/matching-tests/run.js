const { rank, clubs } = require('./harness.js');
const suites = { 'tuning set': require('./cases.js'), 'held-out set': require('./cases2.js') };
const nameOf = Object.fromEntries(clubs.map(c => [c.id, c.name]));
const TOP = 5;
const appear = {};
let allCases = 0, allPass = 0;

for (const [label, cases] of Object.entries(suites)) {
  let pass = 0; const fails = [];
  for (const t of cases) {
    const r = rank(t);
    const top = r.ids.slice(0, TOP);
    top.forEach(id => appear[id] = (appear[id] || 0) + 1);
    const missing = (t.must || []).filter(id => !top.includes(id));
    const intruders = (t.never || []).filter(id => top.includes(id));
    if (!missing.length && !intruders.length) pass++;
    else fails.push({ t, r, top, missing, intruders });
  }
  allCases += cases.length; allPass += pass;
  console.log(`${label}: ${pass}/${cases.length}`);
  for (const f of fails) {
    console.log('  FAIL ' + f.t.name);
    console.log('       top5: ' + f.top.map(i => nameOf[i]).join(' | '));
    if (f.missing.length) console.log('       missing: ' + f.missing.map(id =>
      nameOf[id] + ' [rank ' + (f.r.ids.indexOf(id) + 1 || '-') + ']').join(', '));
    if (f.intruders.length) console.log('       intruder: ' + f.intruders.map(i => nameOf[i]).join(', '));
  }
  console.log('');
}
console.log(`TOTAL ${allPass}/${allCases}\n`);

const total = Object.values(suites).reduce((a, s) => a + s.length, 0);
const hogs = Object.entries(appear).sort((a, b) => b[1] - a[1]).slice(0, 6);
console.log('most frequent top-5 occupants (of ' + total + ' cases):');
hogs.forEach(([id, n]) => console.log('   ' + (n + '  ').slice(0, 4) + nameOf[id]));
console.log('distinct clubs reaching a top 5: ' + Object.keys(appear).length + ' of ' + clubs.length);
