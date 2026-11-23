function getRegistrations() {
  const spreadsheet = SpreadsheetApp.openById(
    REGISTRATION_SPREADSHEET_ID
  );

  const sheet = spreadsheet.getSheetByName('Form Responses 1');

  if (!sheet) {
    throw new Error('Central Registration sheet not found.');
  }

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


function initialiseEnrolment(
  rowNumber,
  registrationMode = 'Flexible',
  batchId = ''
) {
  const lock = LockService.getScriptLock();

  lock.waitLock(30000);

  try {
    const spreadsheet = SpreadsheetApp.openById(
      REGISTRATION_SPREADSHEET_ID
    );

    const sheet = spreadsheet.getSheetByName('Form Responses 1');

    if (!sheet) {
      throw new Error('Central Registration sheet not found.');
    }

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
      RegistrationMode: registrationMode,
      BatchID: batchId,
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

  const sheetName = e.range.getSheet().getName();
  const rowNumber = e.range.getRow();

  let registration;

  // Route Flexible and Group registrations.
  if (sheetName === 'Form Responses 1') {

    const enrolmentId = initialiseEnrolment(rowNumber);

    registration = {
      enrolmentId: enrolmentId,
      rowNumber: rowNumber
    };

  } else {

    registration = processGroupRegistrationSubmission(e);

    // Submission was already processed.
    if (!registration) {
      return;
    }
  }

  Logger.log(
    'Enrolment initialised: ' + registration.enrolmentId
  );

  // Send the verification email.
  try {
    const result = sendVerificationEmail(
      registration.rowNumber
    );

    Logger.log(
      'Verification email result: ' + result.status
    );

  } catch (error) {
    // Registration remains recorded even if email delivery fails.
    Logger.log(
      'VERIFICATION EMAIL FAILED for ' +
      registration.enrolmentId + ': ' + error.message
    );
  }
}

function processGroupRegistrationSubmission(e) {
  if (!e || !e.range) {
    throw new Error('Invalid form submission event.');
  }

  const sourceSheet = e.range.getSheet();
  const sourceSheetName = sourceSheet.getName();
  const sourceRow = e.range.getRow();

  // Find the Processed column.
  const sourceHeaders = sourceSheet
    .getRange(1, 1, 1, sourceSheet.getLastColumn())
    .getValues()[0];

  const sourceColumns = {};
  sourceHeaders.forEach((header, index) => {
    sourceColumns[header] = index + 1;
  });

  if (!sourceColumns['Processed']) {
    throw new Error('Processed column not found.');
  }

  // Prevent duplicate processing.
  const processedCell = sourceSheet.getRange(
    sourceRow,
    sourceColumns['Processed']
  );

  if (processedCell.getValue() === true) {
    Logger.log('Group submission already processed: ' + sourceRow);
    return null;
  }

  // Find the group configuration.
  const spreadsheet = SpreadsheetApp.openById(
    REGISTRATION_SPREADSHEET_ID
  );

  const configSheet = spreadsheet.getSheetByName(
    'Group Configuration'
  );

  if (!configSheet) {
    throw new Error('Group Configuration sheet not found.');
  }

  const configData = configSheet.getDataRange().getValues();
  const configHeaders = configData[0];

  const configColumns = {};
  configHeaders.forEach((header, index) => {
    configColumns[header] = index;
  });

  const group = configData.slice(1).find(row =>
    row[configColumns['Response Sheet Name']] === sourceSheetName
  );

  if (!group) {
    throw new Error(
      'No group configuration found for: ' + sourceSheetName
    );
  }

  if (group[configColumns['Status']] !== 'Open') {
    throw new Error('Group registration is not open.');
  }

  const batchId = group[configColumns['BatchID']];
  const courseStartDate = group[configColumns['Course Start Date']];

  // Read the participant's submitted information.
  const sourceRowValues = sourceSheet
    .getRange(sourceRow, 1, 1, sourceHeaders.length)
    .getValues()[0];

  const sourceRecord = {};
  sourceHeaders.forEach((header, index) => {
    sourceRecord[header] = sourceRowValues[index];
  });

  // Find the central Registration sheet.
  const centralSheet = spreadsheet.getSheetByName(
    'Form Responses 1'
  );

  if (!centralSheet) {
    throw new Error('Central Registration sheet not found.');
  }

  const centralHeaders = centralSheet
    .getRange(1, 1, 1, centralSheet.getLastColumn())
    .getValues()[0];

  const centralRow = centralHeaders.map(header => {
    switch (header) {
      case 'Timestamp':
        return sourceRecord['Timestamp'];

      case 'नाव (Full Name)':
        return sourceRecord['नाव (Full Name)'];

      case 'मोबाईल क्रमांक (Mobile Number)':
        return sourceRecord['मोबाईल क्रमांक (Mobile Number)'];

      case 'Email Address':
        return sourceRecord['Email Address'];

      case 'फी भरल्याचा संदर्भ (Payment Screenshot)':
        return sourceRecord['फी भरल्याचा संदर्भ (Payment Screenshot)'];

      case 'अभ्यासक्रम सुरू करण्याची तारीख (Course Start Date)':
        return courseStartDate;

      default:
        return '';
    }
  });

  // Append the registration to the central sheet.
  const targetRow = centralSheet.getLastRow() + 1;

  centralSheet
    .getRange(targetRow, 1, 1, centralRow.length)
    .setValues([centralRow]);

  // Initialise the enrolment as a Group registration.
  const enrolmentId = initialiseEnrolment(
    targetRow,
    'Group',
    batchId
  );

  // Mark the source submission as successfully transferred.
  processedCell.setValue(true);

  SpreadsheetApp.flush();

  Logger.log(
    'Group registration transferred: ' +
    enrolmentId + ', Batch: ' + batchId
  );

  return {
    enrolmentId: enrolmentId,
    rowNumber: targetRow,
    batchId: batchId
  };
}


function synchronisePaymentStatus() {
  const spreadsheet = SpreadsheetApp.openById(
    REGISTRATION_SPREADSHEET_ID
  );

  const sheet = spreadsheet.getSheetByName('Form Responses 1');

  if (!sheet) {
    throw new Error('Central Registration sheet not found.');
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0];

  const paymentColumn = headers.indexOf('PaymentVerified');
  const emailColumn = headers.indexOf('EmailVerified');
  const statusColumn = headers.indexOf('EnrolmentStatus');
  const processedColumn = headers.indexOf('LastProcessed');

  let updated = 0;

  for (let i = 1; i < data.length; i++) {
    const row = data[i];

    if (!row[0]) continue;

    let expectedStatus;

    if (row[emailColumn] !== true) {
      expectedStatus = 'PENDING_VERIFICATION';
    } else if (row[paymentColumn] === true) {
      expectedStatus = 'PAYMENT_VERIFIED';
    } else if (row[paymentColumn] === false) {
      expectedStatus = 'PAYMENT_REJECTED';
    } else {
      expectedStatus = 'PENDING_PAYMENT';
    }

    if (row[statusColumn] !== expectedStatus) {
      sheet.getRange(i + 1, statusColumn + 1)
        .setValue(expectedStatus);

      sheet.getRange(i + 1, processedColumn + 1)
        .setValue(new Date());

      updated++;
    }
  }

  Logger.log('Payment statuses synchronised: ' + updated);

  return updated;
}

