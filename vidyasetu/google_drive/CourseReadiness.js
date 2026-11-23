function runCourseReadinessCheck() {
  const results = [];

  function check(name, callback) {
    try {
      const detail = callback();
      results.push({ name, passed: true, detail: detail || 'OK' });
    } catch (error) {
      results.push({
        name,
        passed: false,
        detail: error.message
      });
    }
  }

  Logger.log('====================================');
  Logger.log('VIDYASETU COURSE READINESS CHECK');
  Logger.log('====================================');

  // 1. Installation configuration
  check('Installation IDs', () => {
    if (
      !COURSE_SETTINGS_SPREADSHEET_ID ||
      !REGISTRATION_SPREADSHEET_ID ||
      !VIDEOS_FOLDER_ID ||
      !VERIFICATION_WEB_APP_URL ||
      !FLEXIBLE_REGISTRATION_FORM_ID
    ) {
      throw new Error('One or more installation values are missing.');
    }

    return 'All five installation values are present.';
  });

  // 2. Course settings

  let settings = null;

  check('Course configuration', () => {
    settings = getCourseConfiguration();

    Logger.log('Organisation: ' + settings['Organisation Name']);
    Logger.log('Course: ' + settings['Course Name']);
    Logger.log('Registration Mode: ' + settings['Registration Mode']);
    Logger.log('Time Zone: ' + settings['Time Zone']);
    Logger.log('Verification URL: ' +
      settings['Verification Web App URL']);

    return 'Required settings and verification URL are valid.';
  });

  check('Settings spreadsheet', () => {
    const spreadsheet = SpreadsheetApp.openById(
      COURSE_SETTINGS_SPREADSHEET_ID
    );

    if (!spreadsheet.getSheetByName('Settings')) {
      throw new Error('Settings tab not found.');
    }

    return spreadsheet.getName();
  });

  // 3. Registration spreadsheet

  let registrationSpreadsheet = null;

  check('Registration spreadsheet', () => {
    registrationSpreadsheet = SpreadsheetApp.openById(
      REGISTRATION_SPREADSHEET_ID
    );

    return registrationSpreadsheet.getName();
  });

  const registrationHeaders = [
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
    'VerificationSentAt',
    'VerificationAttempts',
    'PaymentVerified',
    'AccessEnabled',
    'EnrolmentStatus',
    'LastProcessed',
    'CertificateID',
    'CertificateURL'
  ];

  if (registrationSpreadsheet) {
    check('Central registration sheet', () => {
      const sheet = registrationSpreadsheet.getSheetByName(
        'Form Responses 1'
      );

      if (!sheet) {
        throw new Error('Form Responses 1 tab not found.');
      }

      const headers = sheet
        .getRange(1, 1, 1, sheet.getLastColumn())
        .getValues()[0];

      const missing = registrationHeaders.filter(
        header => !headers.includes(header)
      );

      if (missing.length) {
        throw new Error('Missing headers: ' + missing.join(', '));
      }

      return 'All required registration headers are present.';
    });

    // 4. Video Access Log

    check('Video Access Log', () => {
      const sheet = registrationSpreadsheet.getSheetByName(
        'Video Access Log'
      );

      if (!sheet) {
        throw new Error('Video Access Log tab not found.');
      }

      const requiredHeaders = [
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

      const headers = sheet
        .getRange(1, 1, 1, sheet.getLastColumn())
        .getValues()[0];

      const missing = requiredHeaders.filter(
        header => !headers.includes(header)
      );

      if (missing.length) {
        throw new Error('Missing headers: ' + missing.join(', '));
      }

      return 'All required log headers are present.';
    });
  }

  // 5. Videos

  check('Videos folder and files', () => {
    const folder = DriveApp.getFolderById(VIDEOS_FOLDER_ID);
    const files = folder.getFiles();

    const videos = [];
    const invalidFiles = [];

    while (files.hasNext()) {
      const file = files.next();
      const name = file.getName();
      const match = name.match(/^(\d+)-/);

      if (!match) {
        invalidFiles.push(name);
      } else {
        videos.push({
          number: Number(match[1]),
          name: name
        });
      }
    }

    if (invalidFiles.length) {
      throw new Error(
        'Files without numeric prefix: ' + invalidFiles.join(', ')
      );
    }

    if (!videos.length) {
      throw new Error('No videos found.');
    }

    videos.sort((a, b) => a.number - b.number);

    for (let i = 0; i < videos.length; i++) {
      if (videos[i].number !== i + 1) {
        throw new Error(
          'Video numbering must be sequential from 1. Found: ' +
          videos.map(video => video.number).join(', ')
        );
      }
    }

    return videos.length + ' videos found: ' +
      videos.map(video => video.name).join(', ');
  });

  // 6. Flexible registration, when enabled

  if (settings) {
    const mode = String(settings['Registration Mode'])
      .trim()
      .toLowerCase();

    if (mode === 'flexible' || mode === 'both') {
      check('Flexible Registration Form', () => {
        const form = FormApp.openById(
          FLEXIBLE_REGISTRATION_FORM_ID
        );

        if (form.getDestinationId() !== REGISTRATION_SPREADSHEET_ID) {
          throw new Error(
            'Form is not linked to the central Registration spreadsheet.'
          );
        }

        return 'Form exists and is linked to the correct spreadsheet.';
      });
    }
  }
  // 6.1. Group registration, when enabled

  if (settings) {
    const mode = String(settings['Registration Mode'])
      .trim()
      .toLowerCase();

    if (mode === 'group' || mode === 'both') {
      check('Group Configuration', () => {
        const sheet = registrationSpreadsheet.getSheetByName(
          'Group Configuration'
        );

        if (!sheet) {
          throw new Error('Group Configuration tab not found.');
        }

        const data = sheet.getDataRange().getValues();
        const headers = data[0];

        const requiredHeaders = [
          'BatchID',
          'FormID',
          'Course Start Date',
          'Status',
          'Response Sheet Name'
        ];

        const missing = requiredHeaders.filter(
          header => !headers.includes(header)
        );

        if (missing.length) {
          throw new Error('Missing headers: ' + missing.join(', '));
        }

        if (data.length < 2) {
          throw new Error('No group batches configured.');
        }

        const columns = {};
        headers.forEach((header, index) => {
          columns[header] = index;
        });

        const batches = data.slice(1).filter(
          row => row[columns['BatchID']]
        );

        if (!batches.length) {
          throw new Error('No group batches configured.');
        }

        batches.forEach(batch => {
          const batchId = batch[columns['BatchID']];
          const formId = batch[columns['FormID']];
          const responseSheetName =
            batch[columns['Response Sheet Name']];

          if (!formId || !responseSheetName) {
            throw new Error(
              'Incomplete configuration for batch ' + batchId
            );
          }

          const form = DriveApp.getFileById(formId);

          if (form.getMimeType() !== MimeType.GOOGLE_FORMS) {
            throw new Error(
              'Configured Form ID is not a Google Form: ' + batchId
            );
          }

          const responseSheet = registrationSpreadsheet
            .getSheetByName(responseSheetName);

          if (!responseSheet) {
            throw new Error(
              'Response tab not found: ' + responseSheetName
            );
          }

          const responseHeaders = responseSheet
            .getRange(1, 1, 1, responseSheet.getLastColumn())
            .getValues()[0];

          if (!responseHeaders.includes('Processed')) {
            throw new Error(
              'Processed column missing in ' + responseSheetName
            );
          }
        });

        return batches.length + ' group batch(es) validated.';
      });
    } else if (mode !== 'flexible') {
      results.push({
        name: 'Group Configuration',
        passed: false,
        detail: 'Unknown Registration Mode: ' + mode
      });
    } else {
      results.push({
        name: 'Group Configuration',
        passed: true,
        detail: 'Skipped (Flexible registration only).'
      });
    }
  }

  // 7. Installed triggers

  check('Registration trigger', () => {
    const triggers = ScriptApp.getProjectTriggers().filter(
      trigger =>
        trigger.getHandlerFunction() ===
        'handleRegistrationSubmission'
    );

    if (triggers.length !== 1) {
      throw new Error(
        'Expected exactly one registration trigger; found ' +
        triggers.length
      );
    }

    const trigger = triggers[0];

    if (
      trigger.getEventType() !== ScriptApp.EventType.ON_FORM_SUBMIT
    ) {
      throw new Error('Registration trigger is not On Form Submit.');
    }

    if (
      trigger.getTriggerSourceId() !== REGISTRATION_SPREADSHEET_ID
    ) {
      throw new Error('Registration trigger points to the wrong spreadsheet.');
    }

    return 'Installed on the central Registration spreadsheet.';
  });

  check('Video scheduler trigger', () => {
    const triggers = ScriptApp.getProjectTriggers().filter(
      trigger =>
        trigger.getHandlerFunction() === 'runVideoAccessScheduler'
    );

    if (triggers.length !== 1) {
      throw new Error(
        'Expected exactly one scheduler trigger; found ' +
        triggers.length
      );
    }

    if (
      triggers[0].getEventType() !== ScriptApp.EventType.CLOCK
    ) {
      throw new Error('Scheduler trigger is not time-driven.');
    }

    return 'Time-driven scheduler trigger is installed.';
  });

  // Email service authorization

  check('Email authorization', () => {
    const quota = MailApp.getRemainingDailyQuota();

    if (quota <= 0) {
      throw new Error('No email quota remaining today.');
    }

    return 'Email service accessible. Remaining quota: ' + quota;
  });

  // Advanced Drive API authorization

  check('Advanced Drive API', () => {
    const folder = DriveApp.getFolderById(VIDEOS_FOLDER_ID);
    const files = folder.getFiles();

    if (!files.hasNext()) {
      throw new Error('No video files available for permission test.');
    }

    const video = files.next();

    const permissions = Drive.Permissions.list(
      video.getId(),
      {
        fields: 'permissions(id,type,role)'
      }
    );

    return 'Drive API accessible. Read permissions for: ' +
      video.getName();
  });

  // 7.1. Verification Web App
  check('Verification Web App', () => {
    const response = UrlFetchApp.fetch(
      VERIFICATION_WEB_APP_URL,
      {
        muteHttpExceptions: true,
        followRedirects: true
      }
    );

    const status = response.getResponseCode();

    if (status !== 200) {
      throw new Error('Web App returned HTTP ' + status);
    }

    return 'Web App responded successfully (HTTP 200).';
  });

  // 8. Final report

  Logger.log('');
  Logger.log('--------------- RESULTS ---------------');

  let passed = 0;
  let failed = 0;

  results.forEach(result => {
    const status = result.passed ? 'PASS' : 'FAIL';

    if (result.passed) {
      passed++;
    } else {
      failed++;
    }

    Logger.log(
      status + ' | ' + result.name + ' | ' + result.detail
    );
  });

  Logger.log('---------------------------------------');
  Logger.log('Passed: ' + passed);
  Logger.log('Failed: ' + failed);

  Logger.log(
    failed === 0
      ? 'COURSE READY'
      : 'COURSE NOT READY'
  );

  Logger.log('====================================');

  return {
    ready: failed === 0,
    passed: passed,
    failed: failed,
    results: results
  };
}

