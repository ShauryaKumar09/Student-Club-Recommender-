// Reads trimForModel out of the live file so the measurement uses the shipped
// code path rather than a copy of it.
const fs = require('fs');
const path = require('path');
const A = require('./harness_ab.js');
const cases = require('./cases.js').concat(require('./cases2.js'));
const c0 = A.makeComponent();
const byId = Object.fromEntries(A.clubs.map(c => [c.id, c]));

// The candidate counts are read out of index.html rather than repeated here.
// They were hardcoded, so changing the shipped slice left this measuring a
// payload the site no longer sends and reporting no change in cost.
const src = fs.readFileSync(path.join('C:\\Users\\sonam\\wayzata-club-finder\\frontend', 'index.html'), 'utf8');
const slice = src.match(/localScored\.slice\(0,\s*hasText\s*\?\s*(\d+)\s*:\s*(\d+)\)/);
if (!slice) throw new Error('could not find the candidate slice in index.html');
const [WITH_TEXT, NO_TEXT] = [Number(slice[1]), Number(slice[2])];

let sum = 0, max = 0, trimmed = 0, total = 0;
for (const t of cases) {
  const r = A.rank(t);
  const n = (t.text || '').trim().length > 0 ? WITH_TEXT : NO_TEXT;
  const clubs = r.ids.slice(0, n).map(id => {
    const d = c0.trimForModel(byId[id].description);
    total++; if (d !== (byId[id].description || '')) trimmed++;
    return { id, name: byId[id].name, description: d };
  });
  const len = JSON.stringify({ interests: [], careerGoals: [], styleAnswers: t.style || {},
    customText: t.text || '', clubs }).length;
  sum += len; if (len > max) max = len;
}
console.log('candidates  :', WITH_TEXT, 'with text,', NO_TEXT, 'without');
console.log('mean tokens :', Math.round(sum / cases.length / 4), '  (baseline 608, was 579 before the name test)');
console.log('max tokens  :', Math.round(max / 4), '  (baseline 1074, was 790 before the name test)');
console.log('candidates trimmed:', trimmed, 'of', total, '(' + Math.round(trimmed / total * 100) + '%)');
