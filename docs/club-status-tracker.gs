/**
 * TrojanMatch club information tracker
 *
 * Builds a triage sheet covering every club on the site: whether we have an
 * accurate description, where that description came from, what still needs
 * chasing, and who to chase. Reads the live database, so re-running it after
 * you update a club refreshes the picture.
 *
 * SETUP (once)
 *  1. Make a NEW blank spreadsheet (this must not be the bug reports one).
 *  2. Extensions -> Apps Script. Delete Code.gs and paste this whole file in.
 *  3. Run -> select `rebuild` -> Run. Approve the permissions prompt.
 *  4. Reload the spreadsheet. A "TrojanMatch" menu appears with Refresh in it.
 *
 * REFRESHING
 *  TrojanMatch -> Refresh from site. Your own edits in the Decision, Action and
 *  Notes columns are preserved -- they are matched back on club name, so only
 *  the site-derived columns are overwritten.
 */

var SHEET_NAME = 'Club status';
var SUPABASE = 'https://pqfchywvjinosvvphshy.supabase.co/rest/v1/clubs'
  + '?select=name,category,is_student_led,description,detailed_description,advisor,email,'
  + 'instagram,photos,meeting_days,meeting_time,meeting_location&order=name.asc';
// Public read-only key. Safe here: row level security limits it to SELECT.
var SUPABASE_KEY = 'sb_publishable_Y8thf68mra-7AjwmWDUOsw_E0668SW2';

/**
 * Who has come back to us, and what they actually said. Names are the club's
 * name on the SITE, which is not always what they typed on the form.
 *   'described'  - wrote a full description, now live on the site
 *   'approved'   - looked at it and said the existing description is fine
 *   'tweaked'    - asked for one specific change rather than a rewrite
 */
var FORM_RESPONSES = {
  'Club Utsaav': 'described',
  'SPEC: Student Political Engagement Center': 'described',
  'Wayzata Inventors Group': 'described',
  'Women In Government': 'described',
  'Forget Me Not Organization': 'described',
  'Wayzata Investment Competition (WIC)': 'described',
  'Our Right to Learn': 'described',
  'The BizMark Exchange': 'described',
  'WAVE: Wayzata Actively Valuing Empathy': 'described',
  'Aerospace and Aeronautical Group': 'described',
  'Paws for a Cause': 'described',
  'Quiz Bowl': 'described',
  'Chess Club': 'described',
  'Club Unified Students': 'described',
  'Future Problem-Solvers': 'described',
  'AHA: American Heart Association': 'described',
  'Educators Rising': 'described',
  'Mock Trial': 'approved',
  'Speech': 'approved',
  'Science Bowl': 'tweaked'
};

var HEADERS = [
  'Club', 'Type', 'Category',
  'Heard from them?', 'Description came from', 'Accurate?',
  'Decision', 'Action needed',
  'Meeting info', 'Email', 'Instagram', 'Photos', 'Complete',
  'Advisor / supervisor', 'Contact email', 'Notes'
];
// columns the user owns; never overwritten by a refresh
var MANUAL = { 7: true, 8: true, 16: true };   // Decision, Action needed, Notes

function onOpen() {
  SpreadsheetApp.getUi().createMenu('TrojanMatch')
    .addItem('Refresh from site', 'rebuild').addToUi();
}

function rebuild() {
  var ss = SpreadsheetApp.getActive();
  var sheet = ss.getSheetByName(SHEET_NAME) || ss.insertSheet(SHEET_NAME);

  var kept = _existingManualEdits(sheet);
  var clubs = JSON.parse(UrlFetchApp.fetch(SUPABASE, {
    headers: { apikey: SUPABASE_KEY }, muteHttpExceptions: false
  }).getContentText());

  var rows = clubs.map(function (c) {
    var reply = FORM_RESPONSES[c.name] || '';
    var ownWords = String(c.description || '').trim() === String(c.detailed_description || '').trim()
                   && String(c.description || '').trim() !== '';

    var heard = reply ? 'Yes' : 'No';
    var source = reply === 'described' ? "Club's own words"
               : reply === 'tweaked'   ? "Club's own words"
               : reply === 'approved'  ? 'Our draft, club approved it'
               : ownWords              ? "Club's own words"
                                       : 'Our draft, unconfirmed';
    var accurate = reply ? 'Confirmed by club' : 'Not confirmed';

    // seed the two decision columns; the user can override and keep their value
    var decision = reply ? 'Keep' : 'Needs review';
    var action   = reply ? '' : 'Ask club to confirm or rewrite';

    var has = function (v) { return v ? 'Yes' : '-'; };
    var meeting = (c.meeting_days || c.meeting_time || c.meeting_location) ? 'Yes' : '-';
    var filled = [meeting, has(c.email), has(c.instagram), has(c.photos && c.photos.length)]
                   .filter(function (x) { return x === 'Yes'; }).length;

    var prior = kept[c.name] || {};
    return [
      c.name,
      c.is_student_led ? 'Student group' : 'Official club',
      c.category,
      heard,
      source,
      accurate,
      prior.decision || decision,
      prior.action !== undefined ? prior.action : action,
      meeting, has(c.email), has(c.instagram), has(c.photos && c.photos.length),
      filled / 4,
      c.advisor || '',
      c.email || '',
      prior.notes || ''
    ];
  });

  sheet.clear();
  sheet.getRange(1, 1, 1, HEADERS.length).setValues([HEADERS]);
  if (rows.length) sheet.getRange(2, 1, rows.length, HEADERS.length).setValues(rows);
  _format(sheet, rows.length);
  _summary(sheet, rows);
  ss.toast(rows.length + ' clubs refreshed.');
}

/** Reads back the columns the user maintains so a refresh does not wipe them. */
function _existingManualEdits(sheet) {
  var out = {};
  if (sheet.getLastRow() < 2) return out;
  var vals = sheet.getRange(2, 1, sheet.getLastRow() - 1, HEADERS.length).getValues();
  vals.forEach(function (r) {
    if (r[0]) out[r[0]] = { decision: r[6], action: r[7], notes: r[15] };
  });
  return out;
}

function _format(sheet, n) {
  var cols = HEADERS.length;
  sheet.getRange(1, 1, 1, cols)
    .setBackground('#00457c').setFontColor('#ffffff').setFontWeight('bold')
    .setFontSize(10).setVerticalAlignment('middle').setWrap(true)
    .setBorder(null, null, true, null, null, null, '#f0b323', SpreadsheetApp.BorderStyle.SOLID_THICK);
  sheet.setRowHeight(1, 42);
  sheet.setFrozenRows(1);
  sheet.setFrozenColumns(1);

  var widths = [230, 110, 150, 115, 175, 130, 120, 210, 100, 70, 90, 70, 85, 165, 230, 260];
  widths.forEach(function (w, i) { sheet.setColumnWidth(i + 1, w); });
  if (!n) return;

  var body = sheet.getRange(2, 1, n, cols);
  body.setFontSize(10).setVerticalAlignment('middle');
  sheet.getRange(2, 13, n, 1).setNumberFormat('0%');
  sheet.getRange(2, 4, n, 9).setHorizontalAlignment('center');
  sheet.getRange(2, 16, n, 1).setWrap(true);

  // dropdowns on the two columns that get worked
  sheet.getRange(2, 7, n, 1).setDataValidation(SpreadsheetApp.newDataValidation()
    .requireValueInList(['Keep', 'Needs review', 'Rewrite', 'Chasing club'], true)
    .setAllowInvalid(false).build());

  var rules = [];
  function rule(range, text, bg, fg) {
    rules.push(SpreadsheetApp.newConditionalFormatRule()
      .whenTextEqualTo(text).setBackground(bg).setFontColor(fg)
      .setRanges([range]).build());
  }
  var heard = sheet.getRange(2, 4, n, 1);
  rule(heard, 'Yes', '#e4f7ec', '#0a7a3d');
  rule(heard, 'No', '#fbeeea', '#a4442f');

  var acc = sheet.getRange(2, 6, n, 1);
  rule(acc, 'Confirmed by club', '#e4f7ec', '#0a7a3d');
  rule(acc, 'Not confirmed', '#fdf0d5', '#7a5e15');

  var dec = sheet.getRange(2, 7, n, 1);
  rule(dec, 'Keep', '#e4f7ec', '#0a7a3d');
  rule(dec, 'Needs review', '#fdf0d5', '#7a5e15');
  rule(dec, 'Rewrite', '#fbeeea', '#a4442f');
  rule(dec, 'Chasing club', '#e2edf6', '#00457c');

  // the four have-we-got-it columns read at a glance as green ticks / grey gaps
  var flags = sheet.getRange(2, 9, n, 4);
  rule(flags, 'Yes', '#e4f7ec', '#0a7a3d');
  rule(flags, '-', '#f6f8fa', '#9aa6b0');

  rules.push(SpreadsheetApp.newConditionalFormatRule()
    .setGradientMaxpoint('#b7e4c7').setGradientMinpoint('#f9d7cf')
    .setRanges([sheet.getRange(2, 13, n, 1)]).build());

  sheet.setConditionalFormatRules(rules);
  sheet.getRange(1, 1, n + 1, cols).createFilter();
}

/** A small at-a-glance block above the data is what makes this a tracker. */
function _summary(sheet, rows) {
  var total = rows.length;
  var heard = rows.filter(function (r) { return r[3] === 'Yes'; }).length;
  var confirmed = rows.filter(function (r) { return r[5] === 'Confirmed by club'; }).length;
  var complete = rows.filter(function (r) { return r[12] === 1; }).length;

  sheet.insertRowsBefore(1, 3);
  sheet.getRange('A1').setValue('TrojanMatch - club information status')
    .setFontSize(14).setFontWeight('bold').setFontColor('#00457c');
  sheet.getRange('A2').setValue(
    'Heard from ' + heard + ' of ' + total + ' clubs   |   ' +
    confirmed + ' descriptions confirmed by the club   |   ' +
    (total - confirmed) + ' still our own draft   |   ' +
    complete + ' clubs with meeting time, email, Instagram and photos all present'
  ).setFontSize(10).setFontColor('#4a5862');
  sheet.getRange('A3').setValue('Last refreshed ' + Utilities.formatDate(
    new Date(), Session.getScriptTimeZone(), 'EEEE d MMMM yyyy, h:mm a'))
    .setFontSize(9).setFontColor('#8a97a1');
  sheet.setFrozenRows(4);
}
