
function generateVerificationToken_() {
  const token = [
    Utilities.getUuid(),
    Utilities.getUuid()
  ].join('');

  const tokenHash = Utilities.computeDigest(
    Utilities.DigestAlgorithm.SHA_256,
    token,
    Utilities.Charset.UTF_8
  );

  const hashHex = tokenHash
    .map(byte => ('0' + ((byte + 256) % 256).toString(16)).slice(-2))
    .join('');

  return {
    token: token,
    tokenHash: hashHex
  };
}

function hashVerificationToken_(token) {
  const digest = Utilities.computeDigest(
    Utilities.DigestAlgorithm.SHA_256,
    token,
    Utilities.Charset.UTF_8
  );

  return digest
    .map(byte => ('0' + ((byte + 256) % 256).toString(16)).slice(-2))
    .join('');
}

function verifyTokenHash_(token, storedHash) {
  if (!token || !storedHash) {
    return false;
  }

  return hashVerificationToken_(token) === storedHash;
}


function prepareVerificationRequest(rowNumber) {
  const lock = LockService.getScriptLock();
  lock.waitLock(30000);

  try {
    const settings = getCourseConfiguration();

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

    const getValue = name =>
      sheet.getRange(rowNumber, column[name]).getValue();

    if (getValue('EmailVerified') === true) {
      throw new Error('Email is already verified.');
    }

    const attempts = Number(getValue('VerificationAttempts') || 0);

    if (attempts >= settings['Maximum Verification Attempts']) {
      throw new Error('Maximum verification attempts reached.');
    }

    const lastSentAt = getValue('VerificationSentAt');

    if (lastSentAt instanceof Date && !isNaN(lastSentAt.getTime())) {
      const cooldownMs =
        settings['Verification Resend Cooldown (Minutes)'] * 60 * 1000;

      const elapsedMs = Date.now() - lastSentAt.getTime();

      if (elapsedMs < cooldownMs) {
        throw new Error('Verification resend cooldown is active.');
      }
    }

    const tokenData = generateVerificationToken_();
    const now = new Date();

    const expiry = new Date(
      now.getTime() +
      settings['Email Verification Validity (Hours)'] * 60 * 60 * 1000
    );

    sheet.getRange(rowNumber, column['VerificationTokenHash'])
      .setValue(tokenData.tokenHash);

    sheet.getRange(rowNumber, column['VerificationExpiry'])
      .setValue(expiry);

    SpreadsheetApp.flush();

    return {
      token: tokenData.token,
      expiry: expiry
    };

  } finally {
    lock.releaseLock();
  }
}


function recordVerificationEmailSent(rowNumber, tokenHash) {
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

    const currentHash = sheet
      .getRange(rowNumber, column['VerificationTokenHash'])
      .getValue();

    if (currentHash !== tokenHash) {
      throw new Error('Verification token has changed. Cannot record delivery.');
    }

    const attemptsCell = sheet.getRange(
      rowNumber,
      column['VerificationAttempts']
    );

    const attempts = Number(attemptsCell.getValue() || 0);

    sheet.getRange(rowNumber, column['VerificationSentAt'])
      .setValue(new Date());

    attemptsCell.setValue(attempts + 1);

    SpreadsheetApp.flush();

    Logger.log('Verification email delivery recorded for row: ' + rowNumber);

  } finally {
    lock.releaseLock();
  }
}


function verifyEnrolmentEmail(enrolmentId, token) {
  if (!enrolmentId || !token) {
    return { status: 'INVALID' };
  }

  const lock = LockService.getScriptLock();
  lock.waitLock(30000);

  try {
    const spreadsheet = SpreadsheetApp.openById(
      REGISTRATION_SPREADSHEET_ID
    );
    const sheet = spreadsheet.getSheets()[0];

    const values = sheet.getDataRange().getValues();
    const headers = values[0];

    const columns = {};
    headers.forEach((header, index) => {
      columns[header] = index;
    });

    const requiredHeaders = [
      'EnrolmentID',
      'EmailVerified',
      'VerificationTokenHash',
      'VerificationExpiry',
      'EnrolmentStatus',
      'LastProcessed'
    ];

    requiredHeaders.forEach(header => {
      if (columns[header] === undefined) {
        throw new Error('Missing column: ' + header);
      }
    });

    // Locate the enrolment.
    let rowNumber = -1;

    for (let i = 1; i < values.length; i++) {
      if (String(values[i][columns.EnrolmentID]) === String(enrolmentId)) {
        rowNumber = i + 1;
        break;
      }
    }

    if (rowNumber === -1) {
      return { status: 'INVALID' };
    }

    const row = sheet.getRange(rowNumber, 1, 1, headers.length)
      .getValues()[0];

    if (toNullableBoolean_(row[columns.EmailVerified]) === true) {
      return { status: 'ALREADY_VERIFIED' };
    }

    const storedHash = row[columns.VerificationTokenHash];
    const expiry = row[columns.VerificationExpiry];

    if (!storedHash || !(expiry instanceof Date)) {
      return { status: 'INVALID' };
    }

    if (new Date() > expiry) {
      return { status: 'EXPIRED' };
    }

    if (!verifyTokenHash_(token, storedHash)) {
      return { status: 'INVALID' };
    }

    // Successful verification.
    sheet.getRange(rowNumber, columns.EmailVerified + 1).setValue(true);
    sheet.getRange(rowNumber, columns.VerificationTokenHash + 1).clearContent();
    sheet.getRange(rowNumber, columns.VerificationExpiry + 1).clearContent();
    sheet.getRange(rowNumber, columns.EnrolmentStatus + 1)
      .setValue('PENDING_PAYMENT');
    sheet.getRange(rowNumber, columns.LastProcessed + 1)
      .setValue(new Date());

    SpreadsheetApp.flush();

    return { status: 'VERIFIED' };

  } finally {
    lock.releaseLock();
  }
}


function sendVerificationEmail(rowNumber) {
  const settings = getCourseConfiguration();

  const spreadsheet = SpreadsheetApp.openById(
    REGISTRATION_SPREADSHEET_ID
  );
  const sheet = spreadsheet.getSheets()[0];

  const headers = sheet.getRange(
    1, 1, 1, sheet.getLastColumn()
  ).getValues()[0];

  const columns = {};
  headers.forEach((header, index) => {
    columns[header] = index;
  });

  const row = sheet.getRange(
    rowNumber, 1, 1, headers.length
  ).getValues()[0];

  const participantName = row[columns['नाव (Full Name)']];
  const email = String(row[columns['Email Address']] || '').trim();

  if (!participantName || !email) {
    throw new Error('Participant name or email address is missing.');
  }

  // Prepare a fresh verification token.
  const request = prepareVerificationRequest(rowNumber);

  const verificationUrl =
    settings['Verification Web App URL'] +
    '?id=' + encodeURIComponent(row[columns.EnrolmentID]) +
    '&token=' + encodeURIComponent(request.token);

  // Populate the email template.
  const template = HtmlService.createTemplateFromFile(
    'VerificationEmail'
  );

  template.organisationName = settings['Organisation Name'];
  template.courseName = settings['Course Name'];
  template.participantName = participantName;
  template.verificationUrl = verificationUrl;
  template.validityHours =
    settings['Email Verification Validity (Hours)'];
  template.supportEmail = settings['Support Email'];
  template.supportContact = settings['Support Contact'];

  const htmlBody = template.evaluate().getContent();

  const subject =
    'Verify your email – ' + settings['Course Name'];

  const body =
    'Hello ' + participantName + ',\n\n' +
    'Thank you for registering for ' +
    settings['Course Name'] + '.\n\n' +
    'Please verify your email address using this link:\n\n' +
    verificationUrl + '\n\n' +
    'This link is valid for ' +
    settings['Email Verification Validity (Hours)'] +
    ' hours.\n\n' +
    settings['Organisation Name'];

  // Send the email.
  MailApp.sendEmail({
    to: email,
    subject: subject,
    body: body,
    htmlBody: htmlBody,
    name: settings['Organisation Name']
  });

  // Record delivery only after MailApp.sendEmail succeeds.
  recordVerificationEmailSent(
    rowNumber,
    hashVerificationToken_(request.token)
  );

  Logger.log(
    'Verification email sent successfully for enrolment: ' +
    row[columns.EnrolmentID]
  );

  return { status: 'SENT' };
}
