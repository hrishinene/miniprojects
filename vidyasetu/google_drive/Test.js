function testGetRegistrations() {
  const registrations = getRegistrations();

  Logger.log('Registration count: ' + registrations.length);
  Logger.log(JSON.stringify(registrations, null, 2));

  Logger.log('Registration reader test PASSED.');
}

function testCourseConfiguration() {
  const settings = getCourseConfiguration();

  Logger.log('Course Configuration:');
  Logger.log(JSON.stringify(settings, null, 2));
  Logger.log('Configuration test PASSED.');
}


function testRegistrationSpreadsheet() {
  const spreadsheet = SpreadsheetApp.openById(
    REGISTRATION_SPREADSHEET_ID
  );

  // Use the first sheet; we will verify its name and structure.
  const sheet = spreadsheet.getSheets()[0];

  const lastRow = sheet.getLastRow();
  const lastColumn = sheet.getLastColumn();

  const headers = sheet
    .getRange(1, 1, 1, lastColumn)
    .getDisplayValues()[0];

  Logger.log('Spreadsheet: ' + spreadsheet.getName());
  Logger.log('Sheet: ' + sheet.getName());
  Logger.log('Last row: ' + lastRow);
  Logger.log('Number of columns: ' + lastColumn);
  Logger.log('Headers:');
  Logger.log(JSON.stringify(headers, null, 2));

  const expectedHeaders = [
    'Timestamp',
    'नाव (Full Name)',
    'मोबाईल क्रमांक (Mobile Number)',
    'Email Address',
    'फी भरल्याचा संदर्भ (Payment Screenshot)',
    'अभ्यासक्रम सुरू करण्याची तारीख (Course Start Date)',
    'EnrolmentID',
    'RegistrationMode',
    'BatchID',
    'EmailVerified',
    'VerificationTokenHash',
    'VerificationExpiry',
    'PaymentVerified',
    'AccessEnabled',
    'EnrolmentStatus',
    'LastProcessed',
    'CertificateID',
    'CertificateURL'
  ];

  const missingHeaders = expectedHeaders.filter(
    header => !headers.includes(header)
  );

  if (missingHeaders.length > 0) {
    throw new Error(
      'Missing headers: ' + missingHeaders.join(', ')
    );
  }

  Logger.log('Registration spreadsheet test PASSED.');
}

function inspectReleaseTime() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet()
    .getSheetByName('Settings');

  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][0]).trim() === 'First Video Release Time') {
      const cell = sheet.getRange(i + 1, 2);

      Logger.log('Raw value: ' + data[i][1]);
      Logger.log('Value type: ' + typeof data[i][1]);
      Logger.log('Is Date: ' + (data[i][1] instanceof Date));
      Logger.log('Displayed value: ' + cell.getDisplayValue());
      Logger.log('Number format: ' + cell.getNumberFormat());
    }
  }
}

function testInitialiseEnrolment() {
  const enrolmentId = initialiseEnrolment(2);

  Logger.log('Generated Enrolment ID: ' + enrolmentId);

  const registrations = getRegistrations();

  Logger.log(JSON.stringify(registrations[0], null, 2));
}

function testEnrolmentIdImmutability() {
  const firstId = initialiseEnrolment(2);
  const secondId = initialiseEnrolment(2);

  Logger.log('First call: ' + firstId);
  Logger.log('Second call: ' + secondId);

  if (firstId !== secondId) {
    throw new Error('FAIL: Enrolment ID changed!');
  }

  Logger.log('Enrolment ID immutability test PASSED.');
}

function inspectInstalledTriggers() {
  const triggers = ScriptApp.getProjectTriggers();

  triggers.forEach(trigger => {
    Logger.log('Function: ' + trigger.getHandlerFunction());
    Logger.log('Event type: ' + trigger.getEventType());
    Logger.log('Source: ' + trigger.getTriggerSource());

    if (trigger.getTriggerSourceId) {
      Logger.log('Source ID: ' + trigger.getTriggerSourceId());
    }
  });
}

function installRegistrationTrigger() {
  // Remove existing triggers for this handler only.
  const triggers = ScriptApp.getProjectTriggers();

  triggers.forEach(trigger => {
    if (
      trigger.getHandlerFunction() ===
      'handleRegistrationSubmission'
    ) {
      ScriptApp.deleteTrigger(trigger);
      Logger.log('Removed existing registration trigger.');
    }
  });

  // Install trigger on the actual registration spreadsheet.
  const trigger = ScriptApp.newTrigger(
    'handleRegistrationSubmission'
  )
    .forSpreadsheet(REGISTRATION_SPREADSHEET_ID)
    .onFormSubmit()
    .create();

  Logger.log('Registration trigger installed.');
  Logger.log('Source ID: ' + trigger.getTriggerSourceId());
}

function testVerificationToken() {
  const generated = generateVerificationToken_();

  Logger.log('Token generated: ' + Boolean(generated.token));
  Logger.log('Token hash: ' + generated.tokenHash);
  Logger.log('Hash length: ' + generated.tokenHash.length);

  const valid = verifyTokenHash_(
    generated.token,
    generated.tokenHash
  );

  const invalid = verifyTokenHash_(
    'incorrect-token',
    generated.tokenHash
  );

  Logger.log('Valid token accepted: ' + valid);
  Logger.log('Incorrect token rejected: ' + !invalid);

  if (!valid || invalid || generated.tokenHash.length !== 64) {
    throw new Error('Verification token test FAILED.');
  }

  Logger.log('Verification token test PASSED.');
}

function testPrepareVerificationRequest() {
  const result = prepareVerificationRequest(3);

  Logger.log('Verification request prepared.');
  Logger.log('Token generated: ' + Boolean(result.token));
  Logger.log('Expiry: ' + result.expiry);

  const sheet = SpreadsheetApp.openById(
    REGISTRATION_SPREADSHEET_ID
  ).getSheets()[0];

  const headers = sheet
    .getRange(1, 1, 1, sheet.getLastColumn())
    .getValues()[0];

  const column = {};
  headers.forEach((header, index) => {
    column[header] = index + 1;
  });

  Logger.log(
    'VerificationSentAt: ' +
    sheet.getRange(3, column['VerificationSentAt']).getValue()
  );

  Logger.log(
    'VerificationAttempts: ' +
    sheet.getRange(3, column['VerificationAttempts']).getValue()
  );

  Logger.log('Preparation test PASSED.');
}


function testValidEmailVerification() {
  const rowNumber = 3;

  // Generate and prepare a fresh token.
  const request = prepareVerificationRequest(rowNumber);

  // Read the enrolment ID from the registration sheet.
  const spreadsheet = SpreadsheetApp.openById(
    REGISTRATION_SPREADSHEET_ID
  );
  const sheet = spreadsheet.getSheets()[0];

  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn())
    .getValues()[0];

  const enrolmentIdColumn = headers.indexOf('EnrolmentID') + 1;
  const enrolmentId = sheet.getRange(rowNumber, enrolmentIdColumn)
    .getValue();

  // Verify using the generated token.
  const result = verifyEnrolmentEmail(enrolmentId, request.token);
  Logger.log('First verification: ' + result.status);

  // Try using the same token again.
  const secondResult = verifyEnrolmentEmail(enrolmentId, request.token);
  Logger.log('Second verification: ' + secondResult.status);

  if (
    result.status !== 'VERIFIED' ||
    secondResult.status !== 'ALREADY_VERIFIED'
  ) {
    throw new Error('Valid verification test FAILED.');
  }

  Logger.log('Valid verification test PASSED.');
}


function testInvalidEmailVerification() {
  const enrolmentId = 'VS-A1F50428E344';

  // Prepare a genuine token so the enrolment has an active token.
  const request = prepareVerificationRequest(2);

  // Deliberately supply an incorrect token.
  const result = verifyEnrolmentEmail(
    enrolmentId,
    'this-is-not-a-valid-token'
  );

  Logger.log('Invalid token result: ' + result.status);

  if (result.status !== 'INVALID') {
    throw new Error('Invalid verification test FAILED.');
  }

  // Confirm that the enrolment remains unverified.
  const registrations = getRegistrations();
  const registration = registrations.find(
    r => r.enrolmentId === enrolmentId
  );

  if (!registration || registration.emailVerified === true) {
    throw new Error('Enrolment state changed unexpectedly.');
  }

  Logger.log('Invalid verification test PASSED.');
}


function inspectUnverifiedEnrolments() {
  const registrations = getRegistrations();

  registrations.forEach(registration => {
    Logger.log(JSON.stringify({
      enrolmentId: registration.enrolmentId,
      emailVerified: registration.emailVerified,
      enrolmentStatus: registration.enrolmentStatus
    }));
  });
}


function testExpiredEmailVerification() {
  const rowNumber = 2;
  const enrolmentId = 'VS-A1F50428E344';

  // Prepare a fresh token.
  const request = prepareVerificationRequest(rowNumber);

  const spreadsheet = SpreadsheetApp.openById(
    REGISTRATION_SPREADSHEET_ID
  );
  const sheet = spreadsheet.getSheets()[0];

  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn())
    .getValues()[0];

  const expiryColumn = headers.indexOf('VerificationExpiry') + 1;

  // Temporarily make the token expired.
  const pastDate = new Date(Date.now() - 60 * 1000);
  sheet.getRange(rowNumber, expiryColumn).setValue(pastDate);

  // Attempt verification using the genuine token.
  const result = verifyEnrolmentEmail(enrolmentId, request.token);

  Logger.log('Expired token result: ' + result.status);

  if (result.status !== 'EXPIRED') {
    throw new Error('Expired verification test FAILED.');
  }

  Logger.log('Expired verification test PASSED.');
}



function inspectVerificationState() {
  const registrations = getRegistrations();

  const registration = registrations.find(
    r => r.enrolmentId === 'VS-A1F50428E344'
  );

  if (!registration) {
    throw new Error('Test enrolment not found.');
  }

  Logger.log(JSON.stringify({
    enrolmentId: registration.enrolmentId,
    emailVerified: registration.emailVerified,
    enrolmentStatus: registration.enrolmentStatus,
    verificationExpiry: registration.verificationExpiry,
    verificationAttempts: registration.verificationAttempts
  }));
}

function testVerificationPageRendering() {
  const settings = getCourseConfiguration();

  const page = HtmlService.createTemplateFromFile('Verification');

  page.organisationName = settings['Organisation Name'];
  page.courseName = settings['Course Name'];
  page.pageTitle = 'Test Page';
  page.message = 'This is a test of the verification page.';

  const output = page.evaluate();

  Logger.log('Page title: ' + output.getTitle());
  Logger.log('HTML generated: ' + (output.getContent().length > 0));
  Logger.log('Contains organisation name: ' +
    output.getContent().includes(settings['Organisation Name']));
  Logger.log('Contains course name: ' +
    output.getContent().includes(settings['Course Name']));
}


function testDoGetResponse() {
  const response = doGet({
    parameter: {
      id: 'invalid-test-id',
      token: 'invalid-test-token'
    }
  });

  const content = response.getContent();

  Logger.log('Response generated: ' + (content.length > 0));
  Logger.log('Shows invalid link message: ' +
    content.includes('Invalid Link'));
  Logger.log('Shows organisation name: ' +
    content.includes('Yoga Vidya Gurukul'));
  Logger.log('Shows course name: ' +
    content.includes('Sample Course'));
}


function inspectSettingsSpreadsheet() {
  const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = spreadsheet.getSheetByName('Settings');

  Logger.log('Spreadsheet name: ' + spreadsheet.getName());
  Logger.log('Spreadsheet ID: ' + spreadsheet.getId());
  Logger.log('Spreadsheet URL: ' + spreadsheet.getUrl());
  Logger.log('Settings sheet name: ' + sheet.getName());

  const values = sheet.getDataRange().getValues();

  for (let i = 0; i < values.length; i++) {
    if (values[i][0] === 'Verification Web App URL') {
      Logger.log('Setting row: ' + (i + 1));
      Logger.log('Cell address: B' + (i + 1));
      Logger.log('Raw value: ' + values[i][1]);
    }
  }
}


function inspectUrlCellDirectly() {
  const spreadsheet = SpreadsheetApp.openById(
    '1wWr6rE3Tgg5izSGvP_bB0su5nfT8ReZ2LTDTlKp4gNE'
  );

  const sheet = spreadsheet.getSheetByName('Settings');
  const cell = sheet.getRange('B19');

  SpreadsheetApp.flush();

  Logger.log('getValue: ' + cell.getValue());
  Logger.log('getDisplayValue: ' + cell.getDisplayValue());
  Logger.log('getFormula: ' + cell.getFormula());

  const richText = cell.getRichTextValue();
  Logger.log('Rich text value: ' +
    (richText ? richText.getText() : 'null'));
}


function testNormalizeWebAppUrl() {
  const input =
    '[https://script.google.com/macros/s/AKfycbx-UJJ6Bz5TawL69RLyGTz2X046zFOQqnTYRlvNpHWQOYpBwJdeXOoAGjXrKFM9sPTjHg/exec](https://script.google.com/macros/s/AKfycbx-UJJ6Bz5TawL69RLyGTz2X046zFOQqnTYRlvNpHWQOYpBwJdeXOoAGjXrKFM9sPTjHg/exec)';

  const output = normalizeWebAppUrl_(input);

  Logger.log('Input: ' + input);
  Logger.log('Output: ' + output);
  Logger.log('Is plain URL: ' + output.startsWith('https://script.google.com/macros/s/'));
  Logger.log('Contains Markdown: ' + output.includes(']('));
}


function testVerificationUrlConfiguration() {
  const settings = getCourseConfiguration();
  const url = settings['Verification Web App URL'];

  Logger.log('URL length: ' + url.length);
  Logger.log('Starts correctly: ' +
    url.startsWith('https://script.google.com/macros/s/'));
  Logger.log('Ends with /exec: ' + url.endsWith('/exec'));
  Logger.log('Contains Markdown: ' + url.includes(']('));

  if (
    !url.startsWith('https://script.google.com/macros/s/') ||
    !url.endsWith('/exec') ||
    url.includes('](')
  ) {
    throw new Error('Verification URL configuration FAILED.');
  }

  Logger.log('Verification URL configuration PASSED.');
}


function testSendVerificationEmail() {
  const result = sendVerificationEmail(4);

  Logger.log('Email delivery result: ' + result.status);
}

function testConfigurationFromRegistrationContext() {
  const settings = getCourseConfiguration();

  Logger.log('Organisation: ' + settings['Organisation Name']);
  Logger.log('Course: ' + settings['Course Name']);
  Logger.log('Web App URL valid: ' +
    settings['Verification Web App URL'].endsWith('/exec'));

  Logger.log('Configuration context test PASSED.');
}

function inspectEmailSendingQuota() {
  Logger.log(
    'Remaining daily email quota: ' +
    MailApp.getRemainingDailyQuota()
  );
}


function testGrantVideoAccess() {
  const result = grantVideoAccess(
    'VS-35C2D0622A20',
    1
  );

  Logger.log(JSON.stringify(result, null, 2));
}


function testRevokeVideoAccess() {
  const result = revokeVideoAccess(
    'VS-35C2D0622A20',
    1
  );

  Logger.log(JSON.stringify(result, null, 2));
}

function testRecordVideoAccessGranted() {
  const row = recordVideoAccessGranted_(
    'VS-35C2D0622A20',
    1,
    '1U93PmUg8ijECBARtn2xH_u196x9rAMtu'
  );

  Logger.log('Video Access Log row: ' + row);
}

function testCheckVideoAccess() {
  const result = checkVideoAccess(
    'VS-35C2D0622A20',
    1
  );

  Logger.log(
    'Participant currently has access: ' +
    result.hasViewerAccess
  );
}

function testReconcileVideoAccess_NoChange() {
  const result = reconcileVideoAccess(
    'VS-35C2D0622A20',
    1,
    true
  );

  Logger.log(JSON.stringify(result, null, 2));
}


function testReconcileVideoAccess_Grant() {
  const result = reconcileVideoAccess(
    'VS-35C2D0622A20',
    1,
    true
  );

  Logger.log(JSON.stringify(result, null, 2));
}

function testReconcileVideoAccess_Revoke() {
  const result = reconcileVideoAccess(
    'VS-35C2D0622A20',
    1,
    false
  );

  Logger.log(JSON.stringify(result, null, 2));
}

function testCalculateVideoSchedule() {
  const settings = getCourseConfiguration();

  // Sample enrolment start date: 20 November 2026
  const courseStartDate = '2026-11-20';

  for (let videoNumber = 1; videoNumber <= 4; videoNumber++) {
    const result = calculateVideoSchedule(
      courseStartDate,
      videoNumber,
      settings
    );

    Logger.log(
      'Video ' + videoNumber +
      ' | Release: ' +
      Utilities.formatDate(
        result.releaseAt,
        settings['Time Zone'],
        'dd MMM yyyy HH:mm'
      ) +
      ' | Expiry: ' +
      Utilities.formatDate(
        result.expiryAt,
        settings['Time Zone'],
        'dd MMM yyyy HH:mm'
      )
    );
  }
}

function testCalculateScheduleFromSheetDate() {
  const settings = getCourseConfiguration();
  const registrations = getRegistrations();

  const enrolment = registrations.find(
    r => r.enrolmentId === 'VS-35C2D0622A20'
  );

  if (!enrolment) {
    throw new Error('Test enrolment not found.');
  }

  Logger.log(
    'Course start date type: ' +
    Object.prototype.toString.call(enrolment.courseStartDate)
  );

  Logger.log(
    'Course start date value: ' +
    enrolment.courseStartDate
  );

  const result = calculateVideoSchedule(
    enrolment.courseStartDate,
    1,
    settings
  );

  Logger.log(
    'Video 1 release: ' +
    Utilities.formatDate(
      result.releaseAt,
      settings['Time Zone'],
      'dd MMM yyyy HH:mm'
    )
  );

  Logger.log(
    'Video 1 expiry: ' +
    Utilities.formatDate(
      result.expiryAt,
      settings['Time Zone'],
      'dd MMM yyyy HH:mm'
    )
  );
}


function testVideoAvailabilityDecision() {
  const registrations = getRegistrations();

  const enrolment = registrations.find(
    r => r.enrolmentId === 'VS-35C2D0622A20'
  );

  if (!enrolment) {
    throw new Error('Test enrolment not found.');
  }

  const settings = getCourseConfiguration();

  const schedule = calculateVideoSchedule(
    enrolment.courseStartDate,
    1,
    settings
  );

  const testCases = [
    {
      label: 'Before release',
      now: new Date(schedule.releaseAt.getTime() - 1000)
    },
    {
      label: 'During viewing window',
      now: new Date(schedule.releaseAt.getTime() + 1000)
    },
    {
      label: 'At expiry',
      now: new Date(schedule.expiryAt)
    }
  ];

  testCases.forEach(testCase => {
    const result = shouldVideoBeAccessible(
      enrolment,
      1,
      testCase.now
    );

    Logger.log(
      testCase.label + ': ' +
      JSON.stringify(result)
    );
  });
}

function testReconcileEnrolmentVideoAccess() {
  const result = reconcileEnrolmentVideoAccess(
    'VS-35C2D0622A20',
    1
  );

  Logger.log(JSON.stringify(result, null, 2));
}

function testVideoAccessAvailable() {
  const enrolmentId = 'VS-35C2D0622A20';
  const videoNumber = 1;

  // Simulate a time when Video 1 should be available.
  const simulatedNow = new Date('2026-11-20T06:00:00Z');
  // 11:30 AM IST, 20 November 2026.

  const enrolments = getRegistrations();
  const enrolment = enrolments.find(
    item => item.enrolmentId === enrolmentId
  );

  if (!enrolment) {
    throw new Error('Test enrolment not found.');
  }

  const decision = shouldVideoBeAccessible(
    enrolment,
    videoNumber,
    simulatedNow
  );

  Logger.log('Decision: ' + JSON.stringify(decision));

  const result = reconcileVideoAccess(
    enrolmentId,
    videoNumber,
    decision.expectedAccess
  );

  Logger.log('Reconciliation: ' + JSON.stringify(result));
}


function testVideoAccessExpired() {
  const enrolmentId = 'VS-35C2D0622A20';
  const videoNumber = 1;

  // Simulate 22 November 2026, 12:00 AM IST.
  const simulatedNow = new Date('2026-11-21T18:30:00Z');

  const enrolments = getRegistrations();
  const enrolment = enrolments.find(
    item => item.enrolmentId === enrolmentId
  );

  if (!enrolment) {
    throw new Error('Test enrolment not found.');
  }

  const decision = shouldVideoBeAccessible(
    enrolment,
    videoNumber,
    simulatedNow
  );

  Logger.log('Decision: ' + JSON.stringify(decision));

  const result = reconcileVideoAccess(
    enrolmentId,
    videoNumber,
    decision.expectedAccess
  );

  Logger.log('Reconciliation: ' + JSON.stringify(result));
}

function testPrepareVideoNotificationEmail() {
  const result = prepareVideoNotificationEmail_(
    'VS-35C2D0622A20',
    1
  );

  Logger.log('Recipient: ' + result.recipient);
  Logger.log('Subject: ' + result.subject);
  Logger.log('HTML Body:\n' + result.htmlBody);
}

function testSendVideoNotificationEmail() {
  const result = prepareVideoNotificationEmail_(
    'VS-35C2D0622A20',
    1
  );

  MailApp.sendEmail({
    to: result.recipient,
    subject: result.subject,
    body: 'Your course video is now available. Please view this email in HTML format.',
    htmlBody: result.htmlBody
  });

  Logger.log('Test email sent to: ' + result.recipient);
}



function testSendVideoAvailabilityNotification() {
  const result = sendVideoAvailabilityNotification_(
    'VS-35C2D0622A20',
    1
  );

  Logger.log(JSON.stringify(result, null, 2));
}


function testIntegratedVideoAccessAndNotification() {
  const result = reconcileEnrolmentVideoAccess(
    'VS-35C2D0622A20',
    2,
    new Date('2026-11-20T18:00:00Z') // 11:30 PM IST
  );

  Logger.log(JSON.stringify(result, null, 2));
}


function testVideo2Schedule() {
  const enrolments = getRegistrations();

  const enrolment = enrolments.find(
    item => item.enrolmentId === 'VS-35C2D0622A20'
  );

  const settings = getCourseConfiguration();

  const schedule = calculateVideoSchedule(
    enrolment.courseStartDate,
    2,
    settings
  );

  Logger.log('Course start date: ' + enrolment.courseStartDate);
  Logger.log('Release time: ' + schedule.releaseAt);
  Logger.log('Expiry time: ' + schedule.expiryAt);
  Logger.log('Simulated time: ' + new Date('2026-11-20T06:30:00Z'));
}

