/**
 * TrojanMatch bug reporter -> Google Sheet
 *
 * Receives submissions from the Report a bug form on trojanmatch.vercel.app,
 * appends them to this spreadsheet, and keeps the sheet formatted so it stays
 * readable as rows pile up. Any screenshot is saved to Drive and linked.
 *
 * SETUP (once)
 *  1. Open the spreadsheet -> Extensions -> Apps Script.
 *  2. Delete whatever is in Code.gs and paste this whole file in. Save.
 *  3. Run -> select `setupSheet` -> Run. Approve the permissions prompt
 *     (it needs to write to this sheet and create a Drive folder).
 *  4. Deploy -> New deployment -> type: Web app.
 *       Execute as:        Me
 *       Who has access:    Anyone
 *     Deploy, approve again, then copy the /exec URL.
 *  5. Send that URL back and it gets wired into the site.
 *  6. Run -> select `sendTestNotification` -> Run. Approve the extra mail
 *     permission when it asks, then check the inboxes in NOTIFY_TO.
 *
 * Re-deploying after an edit: Deploy -> Manage deployments -> edit -> New
 * version. The /exec URL stays the same, so the site keeps working. Saving the
 * code alone changes nothing that is live until you publish a new version.
 */

var SHEET_NAME = 'Bug reports';

// The Drive folder attachments are filed into, taken from its URL:
//   drive.google.com/drive/folders/<THIS PART>
// Looked up by id rather than by name so renaming the folder in Drive cannot
// make the script quietly start creating a duplicate somewhere else.
var DRIVE_FOLDER_ID = '1T0HD52feuS6Naj1uIGamROPJZq4FZc15';

// Who gets told when a report lands. Remove an address to stop mailing it, or
// set NOTIFY_ENABLED to false to stop all of them without losing the list.
var NOTIFY_ENABLED = true;
var NOTIFY_TO = [
  'nayan.menon@wayzataschools.org',
  'nayan.vijai@gmail.com',
  'kumarsha003@isd284.com',
  'soodabh000@isd284.com',
  'shaurya.kumar.mn@gmail.com'
];

// The form is public and unauthenticated, so anyone who finds it can make five
// inboxes ring as fast as they can click. Past this many notifications in a
// rolling hour the mail pauses, and the next one that goes out says how many
// were held back. Reports are never dropped: everything reaches the sheet
// whether it was mailed or not.
var MAX_EMAILS_PER_HOUR = 12;

var HEADERS = [
  'Submitted',
  'Status',
  'What happened',
  'Reporter email',
  'Attachment',
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

    var text = String(body.text || '').trim();
    if (!text) return _json({ ok: false, error: 'empty report' });

    var sheet = _sheet();
    if (sheet.getLastRow() === 0) setupSheet();

    var link = '';
    if (body.fileData && body.fileName) {
      link = _saveAttachment(body.fileData, body.fileName, body.fileType);
    }

    sheet.appendRow([
      new Date(),
      'New',
      text,
      String(body.email || '').trim(),
      link,
      String(body.page || ''),
      String(body.agent || '').slice(0, 300)
    ]);

    _format(sheet);

    // Deliberately after the row is safely written, and inside its own
    // try/catch: a mail failure, an exhausted quota or one bad address must
    // never cost us the report or show the student an error for something that
    // is our problem rather than theirs.
    try {
      _notify({
        text: text,
        email: String(body.email || '').trim(),
        page: String(body.page || ''),
        agent: String(body.agent || ''),
        link: link,
        row: sheet.getLastRow()
      });
    } catch (mailErr) {
      Logger.log('notification failed, report still logged: ' + mailErr);
    }

    return _json({ ok: true });
  } catch (err) {
    return _json({ ok: false, error: String(err) });
  }
}

/** Lets you confirm the deployment works by opening the /exec URL in a tab. */
function doGet() {
  return _json({ ok: true, message: 'TrojanMatch bug reporter is live. POST reports here.' });
}

/**
 * Emails the team that a report came in.
 *
 * Reply-to is set to the reporter when they left an address, so answering a
 * student is a reply rather than a copy-paste out of the sheet. It is
 * validated first: that field is free text on a public form, and a malformed
 * value makes the whole send throw, which would cost the notification.
 */
function _notify(r) {
  if (!NOTIFY_ENABLED || !NOTIFY_TO.length) return;

  var held = _throttle();
  if (held === null) return;  // over the hourly cap; the sheet still has it

  // MailApp bills per recipient, not per message.
  if (MailApp.getRemainingDailyQuota() < NOTIFY_TO.length) {
    Logger.log('mail quota exhausted, report still logged');
    return;
  }

  var sheet = _sheet();
  var sheetUrl = SpreadsheetApp.getActive().getUrl() + '#gid=' + sheet.getSheetId();
  var summary = r.text.length > 60 ? r.text.slice(0, 60).replace(/\s+\S*$/, '') + '...' : r.text;
  var subject = 'TrojanMatch bug report: ' + summary;
  if (held > 0) subject = '[' + held + ' more held back] ' + subject;

  var when = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'EEE d MMM, h:mm a');
  var rows = [
    ['When', when],
    ['Reporter', r.email || 'not given'],
    ['Page', r.page || 'not recorded'],
    ['Device', r.agent ? r.agent.slice(0, 160) : 'not recorded']
  ];

  var html = '<div style="font-family:Arial,Helvetica,sans-serif;max-width:620px">'
    + '<p style="margin:0;font-size:13px;color:#5a6570">Someone filled out the bug reporter.</p>'
    + '<div style="border-left:4px solid #f0b323;background:#f7f9fb;padding:14px 16px;margin:14px 0">'
    + '<div style="font-size:15px;line-height:1.55;color:#1f2a33;white-space:pre-wrap">'
    + _esc(r.text) + '</div></div>'
    + '<table style="font-size:13px;color:#3b4a54;border-collapse:collapse">';
  for (var i = 0; i < rows.length; i++) {
    html += '<tr><td style="padding:3px 14px 3px 0;color:#8a97a1">' + rows[i][0] + '</td>'
         +  '<td style="padding:3px 0">' + _esc(rows[i][1]) + '</td></tr>';
  }
  html += '</table>';
  if (r.link) {
    html += '<p style="margin:14px 0 0;font-size:13px"><a href="' + _esc(r.link) + '">Screenshot</a></p>';
  }
  html += '<p style="margin:16px 0 0;font-size:13px"><a href="' + sheetUrl
       +  '">Open row ' + r.row + ' in the sheet</a></p>';
  if (held > 0) {
    html += '<p style="margin:16px 0 0;font-size:12px;color:#8a97a1">' + held
         +  ' further report(s) arrived within the hour and were not mailed, to stop a flood'
         +  ' of notifications. All of them are in the sheet.</p>';
  }
  html += '</div>';

  var lines = [];
  for (var j = 0; j < rows.length; j++) lines.push(rows[j][0] + ': ' + rows[j][1]);
  var plain = 'Someone filled out the bug reporter.\n\n' + r.text + '\n\n' + lines.join('\n')
    + (r.link ? '\nScreenshot: ' + r.link : '') + '\n\nSheet: ' + sheetUrl;

  var options = { name: 'TrojanMatch', htmlBody: html };
  if (/^[^@\s]+@[^@\s.]+\.[^@\s]+$/.test(r.email)) options.replyTo = r.email;

  MailApp.sendEmail(NOTIFY_TO.join(','), subject, plain, options);
}

/**
 * Rolling hourly cap. Returns how many reports were held back since the last
 * mail went out, or null when this one should be held back too.
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
    text: 'Test of the bug reporter notification. If you can read this, the alerts work, '
        + 'and nobody had to find a real bug for you to find out.',
    email: '',
    page: 'https://trojanmatch.vercel.app/',
    agent: 'Apps Script test run',
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
 * Sharing is deliberately NOT widened to anyone-with-the-link: a student can
 * easily attach a screenshot with their name, timetable or messages visible,
 * and a public link would stay openable by anyone who ever saw it. The file
 * inherits the folder's permissions instead, so whoever you have shared that
 * folder with can open it. If a teammate reports a dead link, share the folder
 * with them rather than loosening this.
 *
 * The filename is prefixed with a timestamp so two students sending
 * "screenshot.png" do not end up indistinguishable in the folder.
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
 * new row never arrives unstyled and column widths stay correct as the longest
 * report grows.
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

  sheet.setColumnWidth(1, 150);  // submitted
  sheet.setColumnWidth(2, 90);   // status
  sheet.setColumnWidth(3, 520);  // what happened
  sheet.setColumnWidth(4, 210);  // email
  sheet.setColumnWidth(5, 190);  // attachment
  sheet.setColumnWidth(6, 230);  // page
  sheet.setColumnWidth(7, 260);  // device

  if (rows > 1) {
    var data = sheet.getRange(2, 1, rows - 1, cols);
    data.setVerticalAlignment('top').setFontSize(10);
    sheet.getRange(2, 1, rows - 1, 1).setNumberFormat('ddd d mmm yyyy, h:mm am/pm');
    // only the long free-text column wraps; the rest stay on one line so the
    // grid does not turn into a wall of tall rows
    sheet.getRange(2, 3, rows - 1, 1).setWrap(true);
    sheet.getRange(2, 1, rows - 1, 2).setHorizontalAlignment('left');
  }

  // Status dropdown so triage is click-not-type, with colour coding
  if (rows > 1) {
    var statusRange = sheet.getRange(2, 2, rows - 1, 1);
    statusRange.setDataValidation(
      SpreadsheetApp.newDataValidation()
        .requireValueInList(['New', 'Looking into it', 'Fixed', 'Not a bug'], true)
        .setAllowInvalid(false).build()
    );
    var rules = [];
    [['New', '#fdf0d5', '#7a5e15'],
     ['Looking into it', '#e2edf6', '#00457c'],
     ['Fixed', '#e4f7ec', '#0a7a3d'],
     ['Not a bug', '#eef2f6', '#6b7a85']].forEach(function (r) {
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
