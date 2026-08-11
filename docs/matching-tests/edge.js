const { rank, clubs } = require('./harness.js');
const nameOf = Object.fromEntries(clubs.map(c => [c.id, c.name]));
const cases = require('./cases.js').concat(require('./cases2.js'));

const seen = new Set();
for (const t of cases) rank(t).ids.slice(0, 5).forEach(i => seen.add(i));
console.log('never reached a top 5 in 85 cases:');
clubs.filter(c => !seen.has(c.id)).forEach(c => console.log('   ' + c.name + '  [' + c.category + ']'));

console.log('\nedge cases:');
const probe = (label, p) => {
  try {
    const r = rank(p);
    console.log('  ' + (label + '                                  ').slice(0, 34) +
      'input=' + r.hasAnyInput + ' eligible=' + (r.ids.length + '   ').slice(0, 3) +
      ' top=' + (r.names[0] || '-'));
  } catch (e) { console.log('  ' + label + '  THREW: ' + e.message); }
};
probe('empty everything', {});
probe('whitespace text', { text: '   ' });
probe('gibberish', { text: 'zzzz qqqq xyzzy' });
probe('punctuation only', { text: '!!! ??? ...' });
probe('style answers only', { style: { competitiveness: 3, time_commitment: 3 } });
probe('every topic chip', { chips: require('./harness.js').makeComponent().topicChips.map(c => c.id) });
probe('every career chip', { careers: require('./harness.js').makeComponent().careerChips.map(c => c.id) });
probe('very long text', { text: 'i want to '.repeat(200) + 'sing' });
probe('emoji', { text: '🎻🎺' });
probe('uppercase', { text: 'VIOLIN AND CELLO' });
probe('one char words', { text: 'a b c' });
