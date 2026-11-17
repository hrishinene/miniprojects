/**
 * Prepares and renders a video availability email.
 * Does not send the email.
 *
 * @param {string} enrolmentId
 * @param {number} videoNumber
 */
function prepareVideoNotificationEmail_(enrolmentId, videoNumber) {
  // Find the enrolment.
  const enrolments = getRegistrations();

  const enrolment = enrolments.find(
    item => item.enrolmentId === enrolmentId
  );

  if (!enrolment) {
    throw new Error('Enrolment not found: ' + enrolmentId);
  }

  // Load course settings.
  const settings = getCourseConfiguration();

  // Find the requested video file.
  const settingsFile = DriveApp.getFileById(
    COURSE_SETTINGS_SPREADSHEET_ID
  );

  const parents = settingsFile.getParents();

  if (!parents.hasNext()) {
    throw new Error('Course folder not found.');
  }

  const courseFolder = parents.next();
  const folders = courseFolder.getFoldersByName('Videos');

  if (!folders.hasNext()) {
    throw new Error('Videos folder not found.');
  }

  const videosFolder = folders.next();
  const files = videosFolder.getFiles();
  const prefix = videoNumber + '-';

  let videoFile = null;

  while (files.hasNext()) {
    const file = files.next();

    if (file.getName().startsWith(prefix)) {
      if (videoFile) {
        throw new Error(
          'Multiple videos found for video number ' + videoNumber
        );
      }

      videoFile = file;
    }
  }

  if (!videoFile) {
    throw new Error('Video ' + videoNumber + ' not found.');
  }

  // Calculate the video schedule.
  const schedule = calculateVideoSchedule(
    enrolment.courseStartDate,
    videoNumber,
    settings
  );

  // Format expiry in the course timezone.
  const expiryDateTime = Utilities.formatDate(
    schedule.expiryAt,
    settings['Time Zone'],
    'dd MMMM yyyy, hh:mm a z'
  );

  // Prepare the HTML template.
  const template = HtmlService.createTemplateFromFile(
    'VideoNotificationEmail'
  );

  template.organisationName =
    settings['Organisation Name'];

  template.logoUrl =
    settings['Organisation Logo URL'] || '';

  template.participantName =
    enrolment.name;

  template.courseName =
    settings['Course Name'];

  template.videoNumber =
    videoNumber;

  template.videoName =
    videoFile.getName().substring(prefix.length);

  template.videoUrl =
    videoFile.getUrl();

  template.expiryDateTime =
    expiryDateTime;

  template.supportEmail =
    settings['Support Email'] || '';

  template.supportContact =
    settings['Support Contact'] || '';

  // Render the HTML without sending it.
  const htmlBody = template.evaluate().getContent();

  return {
    recipient: enrolment.email,
    subject: 'Your course video is now available - ' +
      settings['Course Name'],
    htmlBody: htmlBody
  };
}

/**
 * Sends a video availability notification.
 *
 * Only sends when video access is ACTIVE.
 * Skips notifications already marked SENT.
 * Failed notifications can be retried.
 */
function sendVideoAvailabilityNotification_(
  enrolmentId,
  videoNumber
) {
  const lock = LockService.getScriptLock();

  if (!lock.tryLock(30000)) {
    throw new Error('Could not acquire notification lock.');
  }

  try {
    // Read the corresponding access log record.
    const spreadsheet = SpreadsheetApp.openById(
      REGISTRATION_SPREADSHEET_ID
    );

    const sheet = spreadsheet.getSheetByName('Video Access Log');

    if (!sheet) {
      throw new Error('Video Access Log sheet not found.');
    }

    const lastColumn = sheet.getLastColumn();

    const headers = sheet
      .getRange(1, 1, 1, lastColumn)
      .getValues()[0];

    const columnMap = {};

    headers.forEach((header, index) => {
      if (header) {
        columnMap[String(header).trim()] = index + 1;
      }
    });

    const requiredHeaders = [
      'EnrolmentID',
      'VideoNumber',
      'AccessStatus',
      'NotificationStatus',
      'LastProcessedAt'
    ];

    requiredHeaders.forEach(header => {
      if (!columnMap[header]) {
        throw new Error(
          'Missing Video Access Log column: ' + header
        );
      }
    });

    const lastRow = sheet.getLastRow();

    if (lastRow < 2) {
      throw new Error('No video access log records found.');
    }

    const records = sheet
      .getRange(2, 1, lastRow - 1, lastColumn)
      .getValues();

    let targetRow = null;

    for (let i = 0; i < records.length; i++) {
      const existingEnrolmentId =
        records[i][columnMap.EnrolmentID - 1];

      const existingVideoNumber =
        Number(records[i][columnMap.VideoNumber - 1]);

      if (
        existingEnrolmentId === enrolmentId &&
        existingVideoNumber === Number(videoNumber)
      ) {
        targetRow = i + 2;
        break;
      }
    }

    if (!targetRow) {
      throw new Error('Video access log record not found.');
    }

    const accessStatus = sheet
      .getRange(targetRow, columnMap.AccessStatus)
      .getValue();

    const notificationStatus = sheet
      .getRange(targetRow, columnMap.NotificationStatus)
      .getValue();

    // Never send an availability email without active access.
    if (accessStatus !== 'ACTIVE') {
      return {
        status: 'SKIPPED',
        reason: 'ACCESS_NOT_ACTIVE'
      };
    }

    // Never send a duplicate successful notification.
    if (notificationStatus === 'SENT') {
      return {
        status: 'SKIPPED',
        reason: 'ALREADY_SENT'
      };
    }


    // Apply retry cooldown for previously failed notifications.
    if (notificationStatus === 'ERROR') {
      const settings = getCourseConfiguration();

      const retryMinutes = Number(
        settings['Notification Retry Interval (Minutes)'] || 30
      );

      if (!Number.isFinite(retryMinutes) || retryMinutes <= 0) {
        throw new Error(
          'Notification Retry Interval must be a positive number.'
        );
      }

      const lastProcessedAt = sheet
        .getRange(targetRow, columnMap.LastProcessedAt)
        .getValue();

      if (lastProcessedAt instanceof Date) {
        const elapsedMinutes =
          (Date.now() - lastProcessedAt.getTime()) / 60000;

        if (elapsedMinutes < retryMinutes) {
          return {
            status: 'SKIPPED',
            reason: 'RETRY_COOLDOWN',
            retryAfterMinutes: Math.ceil(
              retryMinutes - elapsedMinutes
            )
          };
        }
      }
    }


    if (!['PENDING', 'ERROR'].includes(notificationStatus)) {
      throw new Error(
        'Unexpected notification status: ' + notificationStatus
      );
    }

    try {
      // Prepare the branded email.
      const email = prepareVideoNotificationEmail_(
        enrolmentId,
        videoNumber
      );

      // Send the email.
      MailApp.sendEmail({
        to: email.recipient,
        subject: email.subject,
        body: 'Your course video is now available. ' +
          'Please view this email in HTML format.',
        htmlBody: email.htmlBody
      });

      // Record successful notification.
      recordVideoNotificationStatus_(
        enrolmentId,
        videoNumber,
        'SENT'
      );

      return {
        status: 'SENT',
        recipient: email.recipient
      };

    } catch (error) {
      // Record the failure for a future retry.
      recordVideoNotificationStatus_(
        enrolmentId,
        videoNumber,
        'ERROR',
        error.message
      );

      Logger.log(
        'Video notification failed: ' + error.message
      );

      return {
        status: 'ERROR',
        error: error.message
      };
    }

  } finally {
    lock.releaseLock();
  }
}
