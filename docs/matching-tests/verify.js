// Reads trimForModel out of the live file so the measurement uses the shipped
// code path rather than a copy of it.
const A = require('./harness_ab.js');
const cases = require('./cases.js').concat(require('./cases2.js'));
const c0 = A.makeComponent();
const byId = Object.fromEntries(A.clubs.map(c => [c.id, c]));
let sum = 0, max = 0, trimmed = 0, total = 0;
for (const t of cases) {
  const r = A.rank(t);
  const n = (t.text || '').trim().length > 0 ? 10 : 8;
  const clubs = r.ids.slice(0, n).map(id => {
    const d = c0.trimForModel(byId[id].description);
    total++; if (d !== (byId[id].description || '')) trimmed++;
    return { id, name: byId[id].name, description: d };
  });
  const len = JSON.stringify({ interests: [], careerGoals: [], styleAnswers: t.style || {},
    customText: t.text || '', clubs }).length;
  sum += len; if (len > max) max = len;
}
console.log('mean tokens :', Math.round(sum / cases.length / 4), '  (baseline 608)');
console.log('max tokens  :', Math.round(max / 4), '  (baseline 1074)');
console.log('candidates trimmed:', trimmed, 'of', total, '(' + Math.round(trimmed / total * 100) + '%)');
