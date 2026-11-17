function getRegistrations() {
  const spreadsheet = SpreadsheetApp.openById(
    REGISTRATION_SPREADSHEET_ID
  );

  const sheet = spreadsheet.getSheets()[0];

  const data = sheet.getDataRange().getValues();

  if (data.length < 2) {
    return [];
  }

  const headers = data[0];

  return data.slice(1)
    .filter(row => row[0] !== '')
    .map(row => {
      const record = {};

      headers.forEach((header, index) => {
        record[header] = row[index];
      });

      return {
        enrolmentId: record['EnrolmentID'] || null,
        name: record['नाव (Full Name)'],
        mobile: String(record['मोबाईल क्रमांक (Mobile Number)'] || ''),
        email: record['Email Address'],
        paymentScreenshot: record['फी भरल्याचा संदर्भ (Payment Screenshot)'],
        courseStartDate: record['अभ्यासक्रम सुरू करण्याची तारीख (Course Start Date)'],

        registrationMode: record['RegistrationMode'] || null,
        batchId: record['BatchID'] || null,

        emailVerified: toNullableBoolean_(record['EmailVerified']),
        paymentVerified: toNullableBoolean_(record['PaymentVerified']),
        accessEnabled: toNullableBoolean_(record['AccessEnabled']),

        verificationTokenHash: record['VerificationTokenHash'] || null,
        verificationExpiry: record['VerificationExpiry'] || null,
        enrolmentStatus: record['EnrolmentStatus'] || null,
        lastProcessed: record['LastProcessed'] || null,
        certificateId: record['CertificateID'] || null,
        certificateUrl: record['CertificateURL'] || null
      };
    });
}

function toNullableBoolean_(value) {
  if (value === '' || value === null || value === undefined) {
    return null;
  }

  if (value === true || String(value).toUpperCase() === 'TRUE') {
    return true;
  }

  if (value === false || String(value).toUpperCase() === 'FALSE') {
    return false;
  }

  throw new Error('Invalid Boolean value: ' + value);
}


function initialiseEnrolment(rowNumber) {
  const lock = LockService.getScriptLock();

  lock.waitLock(30000);

  try {
    const spreadsheet = SpreadsheetApp.openById(
      REGISTRATION_SPREADSHEET_ID
    );

    const sheet = spreadsheet.getSheets()[0];

    const headers = sheet
      .getRange(1, 1, 1, sheet.getLastColumn())
      .getValues()[0];

    const column = {};

    headers.forEach((header, index) => {
      column[header] = index + 1;
    });

    if (rowNumber < 2 || rowNumber > sheet.getLastRow()) {
      throw new Error('Invalid registration row: ' + rowNumber);
    }

    const enrolmentIdCell = sheet.getRange(
      rowNumber,
      column['EnrolmentID']
    );

    const existingId = enrolmentIdCell.getValue();

    if (existingId) {
      Logger.log('Enrolment already initialised: ' + existingId);
      return existingId;
    }

    const enrolmentId =
      'VS-' + Utilities.getUuid()
        .replace(/-/g, '')
        .substring(0, 12)
        .toUpperCase();

    const values = {
      EnrolmentID: enrolmentId,
      RegistrationMode: 'Flexible',
      BatchID: '',
      EmailVerified: '',
      VerificationTokenHash: '',
      VerificationExpiry: '',
      PaymentVerified: '',
      AccessEnabled: '',
      EnrolmentStatus: 'PENDING_VERIFICATION',
      LastProcessed: new Date(),
      CertificateID: '',
      CertificateURL: ''
    };

    Object.keys(values).forEach(key => {
      if (!column[key]) {
        throw new Error('Missing column: ' + key);
      }

      sheet.getRange(rowNumber, column[key]).setValue(values[key]);
    });

    SpreadsheetApp.flush();

    Logger.log('Initialised enrolment: ' + enrolmentId);

    return enrolmentId;

  } finally {
    lock.releaseLock();
  }
}


function handleRegistrationSubmission(e) {
  if (!e || !e.range) {
    throw new Error('Invalid form submission event.');
  }

  const rowNumber = e.range.getRow();

  // Step 1: Initialise the enrolment.
  const enrolmentId = initialiseEnrolment(rowNumber);

  Logger.log(
    'Enrolment initialised: ' + enrolmentId
  );

  // Step 2: Send the verification email.
  try {
    const result = sendVerificationEmail(rowNumber);

    Logger.log(
      'Verification email result: ' + result.status
    );

  } catch (error) {
    // Registration must remain recorded even if email delivery fails.
    Logger.log(
      'VERIFICATION EMAIL FAILED for ' +
      enrolmentId + ': ' + error.message
    );
  }
}
