/**
 * Prepares the Registration spreadsheet structure for course automation.
 *
 * The Registration spreadsheet and its Flexible Registration Form must
 * already exist and be linked before this function is run.
 */
function initialiseCourse() {
  const lock = LockService.getScriptLock();
  lock.waitLock(30000);

  try {
    const spreadsheet = SpreadsheetApp.openById(
      REGISTRATION_SPREADSHEET_ID
    );
    const registrationSheet = spreadsheet.getSheetByName(
      'Form Responses 1'
    );

    if (!registrationSheet) {
      throw new Error(
        'Form Responses 1 sheet not found. Create the Registration spreadsheet and link the Flexible Registration Form first.'
      );
    }

    const formResponseHeaders = [
      'Timestamp',
      'नाव (Full Name)',
      'मोबाईल क्रमांक (Mobile Number)',
      'Email Address',
      'फी भरल्याचा संदर्भ (Payment Screenshot)',
      'अभ्यासक्रम सुरू करण्याची तारीख (Course Start Date)'
    ];
    const systemHeaders = [
      'EnrolmentID',
      'RegistrationMode',
      'BatchID',
      'EmailVerified',
      'VerificationTokenHash',
      'VerificationExpiry',
      'VerificationSentAt',
      'VerificationAttempts',
      'PaymentVerified',
      'EnrolmentStatus',
      'LastProcessed',
      'CertificateID',
      'CertificateURL'
    ];
    const groupConfigurationHeaders = [
      'BatchID',
      'FormID',
      'Course Start Date',
      'Status',
      'Response Sheet Name'
    ];
    const videoAccessLogHeaders = [
      'EnrolmentID',
      'VideoNumber',
      'VideoFileID',
      'ScheduledReleaseAt',
      'ScheduledExpiryAt',
      'PermissionGrantedAt',
      'PermissionRevokedAt',
      'AccessStatus',
      'NotificationStatus',
      'NotificationSentAt',
      'LastProcessedAt',
      'ErrorDetails'
    ];

    const registrationHeaders = getInitialisationHeaders_(
      registrationSheet
    );
    const missingFormHeaders = formResponseHeaders.filter(
      header => registrationHeaders.indexOf(header) === -1
    );

    if (missingFormHeaders.length) {
      throw new Error(
        'Form Responses 1 is missing required form-response headers: ' +
        missingFormHeaders.join(', ')
      );
    }

    appendInitialisationHeaders_(registrationSheet, systemHeaders);

    let groupConfigurationSheet = spreadsheet.getSheetByName(
      'Group Configuration'
    );
    if (!groupConfigurationSheet) {
      groupConfigurationSheet = spreadsheet.insertSheet(
        'Group Configuration'
      );
    }
    appendInitialisationHeaders_(
      groupConfigurationSheet,
      groupConfigurationHeaders
    );

    const groupHeaders = getInitialisationHeaders_(
      groupConfigurationSheet
    );
    const responseSheetNameColumn = groupHeaders.indexOf(
      'Response Sheet Name'
    );
    const lastGroupRow = groupConfigurationSheet.getLastRow();

    if (lastGroupRow > 1) {
      const responseSheetNames = groupConfigurationSheet
        .getRange(2, responseSheetNameColumn + 1, lastGroupRow - 1, 1)
        .getValues();
      const processedSheets = {};

      responseSheetNames.forEach(row => {
        const responseSheetName = String(row[0] || '').trim();
        if (!responseSheetName || processedSheets[responseSheetName]) {
          return;
        }

        const reservedSheetNames = [
          'Form Responses 1',
          'Group Configuration',
          'Video Access Log'
        ];
        if (reservedSheetNames.indexOf(responseSheetName) !== -1) {
          throw new Error(
            'Configured group response sheet name is reserved: ' +
            responseSheetName
          );
        }

        const responseSheet = spreadsheet.getSheetByName(
          responseSheetName
        );
        if (!responseSheet) {
          throw new Error(
            'Configured group response sheet not found: ' +
            responseSheetName
          );
        }

        appendInitialisationHeaders_(responseSheet, ['Processed']);
        processedSheets[responseSheetName] = true;
      });
    }

    let videoAccessLogSheet = spreadsheet.getSheetByName(
      'Video Access Log'
    );
    if (!videoAccessLogSheet) {
      videoAccessLogSheet = spreadsheet.insertSheet('Video Access Log');
    }
    appendInitialisationHeaders_(
      videoAccessLogSheet,
      videoAccessLogHeaders
    );

    SpreadsheetApp.flush();

    return {
      success: true,
      registrationHeadersAdded: systemHeaders.filter(
        header => registrationHeaders.indexOf(header) === -1
      ),
      groupConfigurationReady: true,
      videoAccessLogReady: true
    };
  } finally {
    lock.releaseLock();
  }
}

/**
 * Reads the first row without requesting a zero-width range.
 */
function getInitialisationHeaders_(sheet) {
  const lastColumn = sheet.getLastColumn();

  if (lastColumn < 1) {
    return [];
  }

  return sheet.getRange(1, 1, 1, lastColumn).getValues()[0];
}

/**
 * Adds missing structural headers to the end of a sheet's first row.
 * Existing header cells and all data rows are left untouched.
 */
function appendInitialisationHeaders_(sheet, requiredHeaders) {
  const headers = getInitialisationHeaders_(sheet);
  const missingHeaders = requiredHeaders.filter(
    header => headers.indexOf(header) === -1
  );

  if (!missingHeaders.length) {
    return;
  }

  const startColumn = Math.max(1, sheet.getLastColumn() + 1);
  sheet.getRange(1, startColumn, 1, missingHeaders.length)
    .setValues([missingHeaders]);
}
