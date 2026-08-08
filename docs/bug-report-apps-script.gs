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
 *
 * Re-deploying after an edit: Deploy -> Manage deployments -> edit -> New
 * version. The /exec URL stays the same, so the site keeps working.
 */

var SHEET_NAME = 'Bug reports';

// The Drive folder attachments are filed into, taken from its URL:
//   drive.google.com/drive/folders/<THIS PART>
// Looked up by id rather than by name so renaming the folder in Drive cannot
// make the script quietly start creating a duplicate somewhere else.
var DRIVE_FOLDER_ID = '1T0HD52feuS6Naj1uIGamROPJZq4FZc15';

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
    return _json({ ok: true });
  } catch (err) {
    return _json({ ok: false, error: String(err) });
  }
}

/** Lets you confirm the deployment works by opening the /exec URL in a tab. */
function doGet() {
  return _json({ ok: true, message: 'TrojanMatch bug reporter is live. POST reports here.' });
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
