// Loads the real Component class out of index.html and runs scoreClubs against
// the real 81 club rows. No stubs of the scoring itself -- the only things
// faked are the browser globals the class touches at construction time.
const fs = require('fs');
const path = require('path');

const ROOT = 'C:\\Users\\sonam\\wayzata-club-finder\\frontend';
const html = fs.readFileSync((process.env.IDX ? path.join(__dirname, process.env.IDX) : path.join(ROOT, 'index.html')), 'utf8');
const m = html.match(/<script type="text\/x-dc" data-dc-script[^>]*>([\s\S]*?)<\/script>/);
if (!m) throw new Error('component script not found');

const noop = () => {};
const stubEl = { focus: noop, click: noop, addEventListener: noop, classList: { contains: () => false } };
global.window = { addEventListener: noop, removeEventListener: noop, location: { hash: '', origin: '', pathname: '', search: '' } };
global.document = {
  addEventListener: noop, removeEventListener: noop, getElementById: () => null,
  querySelectorAll: () => [], createElement: () => stubEl, body: { appendChild: noop, removeChild: noop },
  activeElement: null, contains: () => false, documentElement: {}
};
global.location = global.window.location;
global.history = { pushState: noop, replaceState: noop, back: noop };
global.navigator = { userAgent: 'node', clipboard: null };
global.fetch = () => Promise.reject(new Error('no network in harness'));
global.requestAnimationFrame = noop;
global.gtag = noop;

const src = m[1]
  .replace(/class Component extends DCLogic/, 'class Component extends DCLogic')
  + '\nmodule.exports = Component;\n';

const wrapper = 'class DCLogic { setState(o, cb) { Object.assign(this.state, o); if (cb) cb(); } }\n' + src;
const file = path.join(__dirname, ((process.env.TAG || '') + '_component.js'));
fs.writeFileSync(file, wrapper, 'utf8');
const Component = require(file);

const clubs = JSON.parse(fs.readFileSync((process.env.CLUBS ? path.join(__dirname, process.env.CLUBS) : path.join(ROOT, 'uploads', 'clubs.json')), 'utf8'));

function makeComponent() {
  const c = new Component();
  c.props = {};
  return c;
}

// Runs the real scoreClubs for one student profile and returns ranked club ids.
function rank(profile) {
  const c = makeComponent();
  const s = Object.assign({}, c.state, {
    clubs,
    selected: profile.chips || [],
    selectedCareers: profile.careers || [],
    styleAnswers: profile.style || {},
    custom: profile.text || ''
  });
  const { hasAnyInput, scored } = c.scoreClubs(s);
  return {
    hasAnyInput,
    ids: scored.map(r => r.c.id),
    names: scored.map(r => r.c.name),
    byId: Object.fromEntries(scored.map(r => [r.c.id, r]))
  };
}

module.exports = { rank, clubs, makeComponent, Component };

if (require.main === module) {
  const r = rank({ chips: ['tech'], style: {} });
  console.log('smoke test — "Coding, robotics & tech":');
  console.log('  eligible clubs:', r.ids.length);
  console.log('  top 5:', r.names.slice(0, 5).join(' | '));
}
