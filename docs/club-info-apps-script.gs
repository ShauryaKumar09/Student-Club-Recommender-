/**
 * TrojanMatch club info submissions -> Google Sheet
 *
 * Receives submissions from the "Add or update a club" form on
 * trojanmatch.vercel.app, appends them to this spreadsheet, and keeps the
 * sheet formatted so it stays readable as rows pile up. Any club photo is
 * saved to Drive and linked.
 *
 * This is a separate deployment from the bug reporter (docs/bug-report-apps-script.gs)
 * -- use its own spreadsheet, its own Drive folder, and its own /exec URL.
 *
 * SETUP (once)
 *  1. Create a new Google Sheet (or open the one you want submissions in).
 *  2. Extensions -> Apps Script.
 *  3. Delete whatever is in Code.gs and paste this whole file in. Save.
 *  4. In Drive, create a new folder for club photos, open it, and copy the id
 *     out of its URL (drive.google.com/drive/folders/<THIS PART>). Paste that
 *     id into DRIVE_FOLDER_ID below.
 *  5. Run -> select `setupSheet` -> Run. Approve the permissions prompt (it
 *     needs to write to this sheet and create files in the Drive folder).
 *  6. Deploy -> New deployment -> type: Web app.
 *       Execute as:        Me
 *       Who has access:    Anyone
 *     Deploy, approve again, then copy the /exec URL.
 *  7. Paste that URL into the CLUB_INFO_URL constant in index.html.
 *  8. Run -> select `sendTestNotification` -> Run. Approve the extra mail
 *     permission when it asks, then check the inboxes in NOTIFY_TO.
 *
 * Re-deploying after an edit: Deploy -> Manage deployments -> edit -> New
 * version. The /exec URL stays the same, so the site keeps working. Saving the
 * code alone changes nothing that is live until you publish a new version.
 */

var SHEET_NAME = 'Club info submissions';

// The Drive folder club photos are filed into, taken from its URL:
//   drive.google.com/drive/folders/<THIS PART>
// Looked up by id rather than by name so renaming the folder in Drive cannot
// make the script quietly start creating a duplicate somewhere else.
var DRIVE_FOLDER_ID = 'PASTE_YOUR_DRIVE_FOLDER_ID_HERE';

// Who gets told when a submission lands. Remove an address to stop mailing
// it, or set NOTIFY_ENABLED to false to stop all of them without losing the
// list.
var NOTIFY_ENABLED = true;
var NOTIFY_TO = [
  'nayan.menon@wayzataschools.org',
  'nayan.vijai@gmail.com',
  'kumarsha003@isd284.com',
  'soodabh000@isd284.com',
  'shaurya.kumar.mn@gmail.com'
];

// The form is public and unauthenticated, so anyone who finds it can make
// five inboxes ring as fast as they can click. Past this many notifications
// in a rolling hour the mail pauses, and the next one that goes out says how
// many were held back. Submissions are never dropped: everything reaches the
// sheet whether it was mailed or not.
var MAX_EMAILS_PER_HOUR = 12;

var HEADERS = [
  'Submitted',
  'Status',
  'New club or update?',
  'Club name',
  'Category',
  'Student-led / staff-run',
  'Advisor',
  'Club contact email',
  'Club contact phone',
  'Short description',
  'Longer description',
  'Who should join',
  'Meeting location',
  'Meeting days',
  'Meeting time',
  'Instagram',
  'Website',
  'Notes',
  'Photo',
  'Submitted by',
  'Submitter email',
  'Page',
  'Device / browser'
];

/** Creates the tab if needed and applies all formatting. Safe to re-run. */
function setupSheet() {
  var sheet = _sheet();
  sheet.getRange(1, 1, 1, HEADERS.length).setValues([HEADERS]);
  _format(sheet);
  SpreadsheetApp.getActive().toast('Sheet is ready. Now deploy as a web app.');
}

function doPost(e) {
  try {
    var body = JSON.parse((e && e.postData && e.postData.contents) || '{}');

    var name = String(body.name || '').trim();
    var description = String(body.description || '').trim();
    var submitterEmail = String(body.submitterEmail || '').trim();
    if (!name || !description || !submitterEmail) {
      return _json({ ok: false, error: 'missing required field' });
    }

    var sheet = _sheet();
    if (sheet.getLastRow() === 0) setupSheet();

    var link = '';
    if (body.fileData && body.fileName) {
      link = _saveAttachment(body.fileData, body.fileName, body.fileType);
    }

    var kindLabel = body.kind === 'update' ? 'Update to existing listing' : 'New club';
    var ledLabel = { student: 'Student-led', staff: 'Staff-run', curricular: 'Curricular' }[body.led] || 'Not sure';

    sheet.appendRow([
      new Date(),
      'New',
      kindLabel,
      name,
      String(body.category || ''),
      ledLabel,
      String(body.advisor || ''),
      String(body.contactEmail || ''),
      String(body.contactPhone || ''),
      description,
      String(body.detailedDescription || ''),
      String(body.audience || ''),
      String(body.location || ''),
      String(body.days || ''),
      String(body.time || ''),
      String(body.instagram || ''),
      String(body.website || ''),
      String(body.notes || ''),
      link,
      String(body.submitterName || ''),
      submitterEmail,
      String(body.page || ''),
      String(body.agent || '').slice(0, 300)
    ]);

    _format(sheet);

    // Deliberately after the row is safely written, and inside its own
    // try/catch: a mail failure, an exhausted quota or one bad address must
    // never cost us the submission or show the student an error for
    // something that is our problem rather than theirs.
    try {
      _notify({
        kindLabel: kindLabel,
        name: name,
        description: description,
        submitterName: String(body.submitterName || ''),
        submitterEmail: submitterEmail,
        page: String(body.page || ''),
        link: link,
        row: sheet.getLastRow()
      });
    } catch (mailErr) {
      Logger.log('notification failed, submission still logged: ' + mailErr);
    }

    return _json({ ok: true });
  } catch (err) {
    return _json({ ok: false, error: String(err) });
  }
}

/** Lets you confirm the deployment works by opening the /exec URL in a tab. */
function doGet() {
  return _json({ ok: true, message: 'TrojanMatch club info intake is live. POST submissions here.' });
}

/**
 * Emails the team that a submission came in.
 *
 * Reply-to is set to the submitter, so answering them is a reply rather than
 * a copy-paste out of the sheet. It is validated first: that field is free
 * text on a public form, and a malformed value makes the whole send throw,
 * which would cost the notification.
 */
function _notify(r) {
  if (!NOTIFY_ENABLED || !NOTIFY_TO.length) return;

  var held = _throttle();
  if (held === null) return;  // over the hourly cap; the sheet still has it

  // MailApp bills per recipient, not per message.
  if (MailApp.getRemainingDailyQuota() < NOTIFY_TO.length) {
    Logger.log('mail quota exhausted, submission still logged');
    return;
  }

  var sheet = _sheet();
  var sheetUrl = SpreadsheetApp.getActive().getUrl() + '#gid=' + sheet.getSheetId();
  var subject = 'TrojanMatch: ' + r.kindLabel + ' -- ' + r.name;
  if (held > 0) subject = '[' + held + ' more held back] ' + subject;

  var when = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'EEE d MMM, h:mm a');
  var rows = [
    ['When', when],
    ['Type', r.kindLabel],
    ['Club', r.name],
    ['Submitted by', r.submitterName || 'not given'],
    ['Reply to', r.submitterEmail]
  ];

  var html = '<div style="font-family:Arial,Helvetica,sans-serif;max-width:620px">'
    + '<p style="margin:0;font-size:13px;color:#5a6570">Someone filled out the club info form.</p>'
    + '<div style="border-left:4px solid #f0b323;background:#f7f9fb;padding:14px 16px;margin:14px 0">'
    + '<div style="font-size:15px;line-height:1.55;color:#1f2a33;white-space:pre-wrap">'
    + _esc(r.description) + '</div></div>'
    + '<table style="font-size:13px;color:#3b4a54;border-collapse:collapse">';
  for (var i = 0; i < rows.length; i++) {
    html += '<tr><td style="padding:3px 14px 3px 0;color:#8a97a1">' + rows[i][0] + '</td>'
         +  '<td style="padding:3px 0">' + _esc(rows[i][1]) + '</td></tr>';
  }
  html += '</table>';
  if (r.link) {
    html += '<p style="margin:14px 0 0;font-size:13px"><a href="' + _esc(r.link) + '">Photo</a></p>';
  }
  html += '<p style="margin:16px 0 0;font-size:13px"><a href="' + sheetUrl
       +  '">Open row ' + r.row + ' in the sheet</a></p>';
  if (held > 0) {
    html += '<p style="margin:16px 0 0;font-size:12px;color:#8a97a1">' + held
         +  ' further submission(s) arrived within the hour and were not mailed, to stop a flood'
         +  ' of notifications. All of them are in the sheet.</p>';
  }
  html += '</div>';

  var lines = [];
  for (var j = 0; j < rows.length; j++) lines.push(rows[j][0] + ': ' + rows[j][1]);
  var plain = 'Someone filled out the club info form.\n\n' + r.description + '\n\n' + lines.join('\n')
    + (r.link ? '\nPhoto: ' + r.link : '') + '\n\nSheet: ' + sheetUrl;

  var options = { name: 'TrojanMatch', htmlBody: html };
  if (/^[^@\s]+@[^@\s.]+\.[^@\s]+$/.test(r.submitterEmail)) options.replyTo = r.submitterEmail;

  MailApp.sendEmail(NOTIFY_TO.join(','), subject, plain, options);
}

/**
 * Rolling hourly cap. Returns how many submissions were held back since the
 * last mail went out, or null when this one should be held back too.
 */
function _throttle() {
  var props = PropertiesService.getScriptProperties();
  var now = Date.now();
  var start = Number(props.getProperty('notifyWindowStart') || 0);
  var sent = Number(props.getProperty('notifySent') || 0);
  var held = Number(props.getProperty('notifyHeld') || 0);

  if (!start || now - start > 3600 * 1000) { start = now; sent = 0; }

  if (sent >= MAX_EMAILS_PER_HOUR) {
    props.setProperties({
      notifyWindowStart: String(start),
      notifySent: String(sent),
      notifyHeld: String(held + 1)
    });
    return null;
  }

  props.setProperties({
    notifyWindowStart: String(start),
    notifySent: String(sent + 1),
    notifyHeld: '0'
  });
  return held;
}

/** Escapes text from a public form before it goes into an HTML email. */
function _esc(v) {
  return String(v == null ? '' : v)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/** Run from the editor to check the addresses work. Sends one real email. */
function sendTestNotification() {
  _notify({
    kindLabel: 'New club',
    name: 'Test Club',
    description: 'Test of the club info notification. If you can read this, the alerts work, '
        + 'and nobody had to submit a real club for you to find out.',
    submitterName: 'Apps Script test run',
    submitterEmail: '',
    page: 'https://trojanmatch.vercel.app/',
    link: '',
    row: _sheet().getLastRow()
  });
  SpreadsheetApp.getActive().toast('Test sent to ' + NOTIFY_TO.length + ' addresses.');
}

/** Clears the hourly counter if testing leaves it stuck. */
function resetNotificationThrottle() {
  PropertiesService.getScriptProperties()
    .deleteProperty('notifyWindowStart');
  PropertiesService.getScriptProperties()
    .deleteProperty('notifySent');
  PropertiesService.getScriptProperties()
    .deleteProperty('notifyHeld');
  SpreadsheetApp.getActive().toast('Notification throttle reset.');
}

function _sheet() {
  var ss = SpreadsheetApp.getActive();
  return ss.getSheetByName(SHEET_NAME) || ss.insertSheet(SHEET_NAME);
}

/**
 * Decodes the base64 payload and files it in the folder above.
 *
 * Sharing is deliberately NOT widened to anyone-with-the-link: a submitted
 * photo could have identifying details in the background, and a public link
 * would stay openable by anyone who ever saw it. The file inherits the
 * folder's permissions instead, so whoever you have shared that folder with
 * can open it. If a teammate reports a dead link, share the folder with them
 * rather than loosening this.
 *
 * The filename is prefixed with a timestamp so two submissions named
 * "photo.jpg" do not end up indistinguishable in the folder.
 */
function _saveAttachment(dataUrl, name, mime) {
  var base64 = String(dataUrl).indexOf(',') > -1 ? String(dataUrl).split(',')[1] : String(dataUrl);
  var stamp = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'yyyy-MM-dd HHmm');
  var safeName = stamp + ' - ' + String(name || 'attachment').replace(/[\\/:*?"<>|]/g, '-');
  var blob = Utilities.newBlob(Utilities.base64Decode(base64), mime || 'application/octet-stream', safeName);

  var folder;
  try {
    folder = DriveApp.getFolderById(DRIVE_FOLDER_ID);
  } catch (e) {
    // Wrong id, folder deleted, or the deploying account lost access. Fall back
    // to the script owner's Drive root so the attachment is never simply lost.
    return DriveApp.createFile(blob).getUrl() + '  (folder unavailable, saved to My Drive)';
  }
  return folder.createFile(blob).getUrl();
}

/**
 * Formatting is reapplied on every submission rather than only at setup, so a
 * new row never arrives unstyled and column widths stay correct as the
 * longest entry grows.
 */
function _format(sheet) {
  var rows = Math.max(sheet.getLastRow(), 1);
  var cols = HEADERS.length;

  // header: navy bar, gold underline, white bold text
  var header = sheet.getRange(1, 1, 1, cols);
  header.setBackground('#00457c')
        .setFontColor('#ffffff')
        .setFontWeight('bold')
        .setFontSize(11)
        .setVerticalAlignment('middle')
        .setBorder(null, null, true, null, null, null, '#f0b323', SpreadsheetApp.BorderStyle.SOLID_THICK);
  sheet.setRowHeight(1, 34);
  sheet.setFrozenRows(1);

  var widths = [150, 90, 160, 200, 160, 140, 160, 200, 140, 320, 320, 220, 140, 160, 200, 150, 200, 260, 190, 160, 200, 230, 260];
  for (var w = 0; w < widths.length && w < cols; w++) sheet.setColumnWidth(w + 1, widths[w]);

  if (rows > 1) {
    var data = sheet.getRange(2, 1, rows - 1, cols);
    data.setVerticalAlignment('top').setFontSize(10);
    sheet.getRange(2, 1, rows - 1, 1).setNumberFormat('ddd d mmm yyyy, h:mm am/pm');
    // only the long free-text columns wrap; the rest stay on one line so the
    // grid does not turn into a wall of tall rows
    sheet.getRange(2, 10, rows - 1, 2).setWrap(true);  // short + longer description
    sheet.getRange(2, 18, rows - 1, 1).setWrap(true);  // notes
    sheet.getRange(2, 1, rows - 1, 2).setHorizontalAlignment('left');
  }

  // Status dropdown so triage is click-not-type, with colour coding
  if (rows > 1) {
    var statusRange = sheet.getRange(2, 2, rows - 1, 1);
    statusRange.setDataValidation(
      SpreadsheetApp.newDataValidation()
        .requireValueInList(['New', 'Looking into it', 'Live', 'Not adding'], true)
        .setAllowInvalid(false).build()
    );
    var rules = [];
    [['New', '#fdf0d5', '#7a5e15'],
     ['Looking into it', '#e2edf6', '#00457c'],
     ['Live', '#e4f7ec', '#0a7a3d'],
     ['Not adding', '#eef2f6', '#6b7a85']].forEach(function (r) {
      rules.push(SpreadsheetApp.newConditionalFormatRule()
        .whenTextEqualTo(r[0]).setBackground(r[1]).setFontColor(r[2])
        .setRanges([statusRange]).build());
    });
    sheet.setConditionalFormatRules(rules);
  }

  var banding = sheet.getBandings();
  if (!banding.length && rows > 1) {
    sheet.getRange(1, 1, rows, cols)
         .applyRowBanding(SpreadsheetApp.BandingTheme.LIGHT_GREY, true, false);
  }
}

function _json(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
