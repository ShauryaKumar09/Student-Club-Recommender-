const { clubs, makeComponent } = require('./harness.js');
const c0 = makeComponent();
const DIMS = c0.topicScoreDims;
const P = (label, rows) => { if (rows.length) { console.log('\n' + label + ' (' + rows.length + ')');
  rows.forEach(r => console.log('   ' + r)); } };

P('unreachable: no topic dimension >= 3', clubs.filter(c => !DIMS.some(d => (c.scores||{})[d] >= 3)).map(c => c.name));
P('thin interests (< 4 entries)', clubs.filter(c => (c.interests||[]).length < 4)
  .map(c => c.name + '  [' + (c.interests||[]).length + ']  ' + (c.interests||[]).join(' / ')));
P('no email', clubs.filter(c => !c.email).map(c => c.name));
P('no meeting info at all', clubs.filter(c => !c.meetingDays && !c.meetingTime && !c.meetingLocation).map(c => c.name));
P('advisor TBD or missing', clubs.filter(c => !c.advisor || /tbd/i.test(c.advisor)).map(c => c.name + ' -> ' + c.advisor));
P('description === detailedDescription (no long form)',
  clubs.filter(c => (c.description||'').trim() === (c.detailedDescription||'').trim()).map(c => c.name));
P('very short description (< 60 chars)', clubs.filter(c => (c.description||'').length < 60)
  .map(c => c.name + '  "' + c.description + '"'));
P('curly quotes / odd characters', clubs.filter(c =>
  /[‘’“”–—�]/.test(JSON.stringify(c)))
  .map(c => c.name + '  ' + (JSON.stringify(c).match(/[‘’“”–—�]/g)||[]).join('')));
P('no photos', clubs.filter(c => !(c.photos||[]).length).map(c => c.name).slice(0, 100));
P('scores object missing dimensions', clubs.filter(c =>
  DIMS.some(d => (c.scores||{})[d] === undefined)).map(c => c.name));
const seen = {};
clubs.forEach(c => { const k = (c.description||'').trim().toLowerCase(); if (k) (seen[k] = seen[k]||[]).push(c.name); });
P('duplicate descriptions', Object.values(seen).filter(v => v.length > 1).map(v => v.join('  ==  ')));
console.log('\ntotal clubs: ' + clubs.length);
