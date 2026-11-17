/**
 * Records a successful video permission grant.
 *
 * One log record represents one enrolment and one video.
 */
function recordVideoAccessGranted_(
  enrolmentId,
  videoNumber,
  videoFileId
) {
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
    'VideoFileID',
    'PermissionGrantedAt',
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

  if (!enrolmentId || !videoNumber || !videoFileId) {
    throw new Error('Enrolment ID, video number and file ID are required.');
  }

  const lastRow = sheet.getLastRow();
  let targetRow = null;

  if (lastRow >= 2) {
    const records = sheet
      .getRange(2, 1, lastRow - 1, lastColumn)
      .getValues();

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
  }

  if (!targetRow) {
    targetRow = lastRow + 1;
  }

  const now = new Date();

  const values = {
    EnrolmentID: enrolmentId,
    VideoNumber: Number(videoNumber),
    VideoFileID: videoFileId,
    PermissionGrantedAt: now,
    AccessStatus: 'ACTIVE',
    NotificationStatus: 'PENDING',
    LastProcessedAt: now
  };

  Object.keys(values).forEach(header => {
    const column = columnMap[header];

    if (column) {
      const cell = sheet.getRange(targetRow, column);

      // Preserve the original successful grant timestamp.
      if (
        header === 'PermissionGrantedAt' &&
        cell.getValue()
      ) {
        return;
      }

      cell.setValue(values[header]);
    }
  });

  Logger.log(
    'Video access recorded: ' +
    enrolmentId +
    ', Video ' +
    videoNumber +
    ', Row ' +
    targetRow
  );

  return targetRow;
}

/**
 * Records successful removal of video access.
 */
function recordVideoAccessRevoked_(
  enrolmentId,
  videoNumber
) {
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

  const lastRow = sheet.getLastRow();

  if (lastRow < 2) {
    throw new Error('No video access log records found.');
  }

  const records = sheet
    .getRange(2, 1, lastRow - 1, lastColumn)
    .getValues();

  for (let i = 0; i < records.length; i++) {
    const existingEnrolmentId =
      records[i][columnMap.EnrolmentID - 1];

    const existingVideoNumber =
      Number(records[i][columnMap.VideoNumber - 1]);

    if (
      existingEnrolmentId === enrolmentId &&
      existingVideoNumber === Number(videoNumber)
    ) {
      const row = i + 2;
      const now = new Date();

      sheet.getRange(row, columnMap.PermissionRevokedAt)
        .setValue(now);

      sheet.getRange(row, columnMap.AccessStatus)
        .setValue('EXPIRED');

      sheet.getRange(row, columnMap.LastProcessedAt)
        .setValue(now);

      Logger.log(
        'Video access revocation recorded: ' +
        enrolmentId +
        ', Video ' +
        videoNumber
      );

      return row;
    }
  }

  throw new Error(
    'Video access log record not found for ' +
    enrolmentId +
    ', Video ' +
    videoNumber
  );
}

/**
 * Updates the notification status for an enrolment/video.
 *
 * Supported statuses: PENDING, SENT, ERROR
 */
function recordVideoNotificationStatus_(
  enrolmentId,
  videoNumber,
  status,
  errorDetails
) {
  const allowedStatuses = ['PENDING', 'SENT', 'ERROR'];

  if (!allowedStatuses.includes(status)) {
    throw new Error('Invalid notification status: ' + status);
  }

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
    'NotificationStatus',
    'NotificationSentAt',
    'LastProcessedAt',
    'ErrorDetails'
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

  for (let i = 0; i < records.length; i++) {
    const existingEnrolmentId =
      records[i][columnMap.EnrolmentID - 1];

    const existingVideoNumber =
      Number(records[i][columnMap.VideoNumber - 1]);

    if (
      existingEnrolmentId === enrolmentId &&
      existingVideoNumber === Number(videoNumber)
    ) {
      const row = i + 2;
      const now = new Date();

      sheet.getRange(row, columnMap.NotificationStatus)
        .setValue(status);

      sheet.getRange(row, columnMap.LastProcessedAt)
        .setValue(now);

      if (status === 'SENT') {
        sheet.getRange(row, columnMap.NotificationSentAt)
          .setValue(now);

        sheet.getRange(row, columnMap.ErrorDetails)
          .clearContent();

      } else if (status === 'ERROR') {
        sheet.getRange(row, columnMap.ErrorDetails)
          .setValue(errorDetails || 'Unknown email sending error.');
      }

      Logger.log(
        'Video notification status updated: ' +
        enrolmentId + ', Video ' + videoNumber +
        ', Status: ' + status
      );

      return row;
    }
  }

  throw new Error(
    'Video access log record not found for ' +
    enrolmentId + ', Video ' + videoNumber
  );
}
