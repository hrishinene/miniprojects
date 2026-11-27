
/**
 * Grant viewer access to one video for an enrolment.
 * Uses Advanced Drive API to suppress Google's notification email.
 *
 * @param {string} enrolmentId
 * @param {number} videoNumber
 */
function grantVideoAccess(enrolmentId, videoNumber) {
  const enrolments = getRegistrations();

  const enrolment = enrolments.find(
    item => item.enrolmentId === enrolmentId
  );

  if (!enrolment) {
    throw new Error('Enrolment not found: ' + enrolmentId);
  }

  if (!enrolment.email) {
    throw new Error('Enrolment email is missing.');
  }

  if (!isEnrolmentEligibleForVideoAccess_(enrolment)) {
    throw new Error('Enrolment is not eligible for video access.');
  }

  // Locate the course folder.
  const settingsFile = DriveApp.getFileById(
    COURSE_SETTINGS_SPREADSHEET_ID
  );

  const parents = settingsFile.getParents();

  if (!parents.hasNext()) {
    throw new Error('Course folder not found.');
  }

  const courseFolder = parents.next();

  // Locate the Videos folder.
  const videoFolders = courseFolder.getFoldersByName('Videos');

  if (!videoFolders.hasNext()) {
    throw new Error('Videos folder not found.');
  }

  const videosFolder = videoFolders.next();

  // Locate the requested video using its numeric prefix.
  const prefix = videoNumber + '-';
  const files = videosFolder.getFiles();

  let videoFile = null;
  let matchCount = 0;

  while (files.hasNext()) {
    const file = files.next();

    if (file.getName().startsWith(prefix)) {
      videoFile = file;
      matchCount++;
    }
  }

  if (matchCount === 0) {
    throw new Error('Video not found: ' + videoNumber);
  }

  if (matchCount > 1) {
    throw new Error(
      'Multiple videos found with prefix: ' + prefix
    );
  }

  // Grant viewer permission without Google's notification email.
  const permission = Drive.Permissions.create(
    {
      type: 'user',
      role: 'reader',
      emailAddress: enrolment.email
    },
    videoFile.getId(),
    {
      sendNotificationEmail: false
    }
  );

  // // Record the successful permission grant.
  // recordVideoAccessGranted_(
  //   enrolmentId,
  //   videoNumber,
  //   videoFile.getId()
  // );

  Logger.log(
    'Viewer access granted without Google notification: ' +
    enrolment.email + ' -> ' + videoFile.getName()
  );

  return {
    status: 'GRANTED',
    enrolmentId: enrolmentId,
    email: enrolment.email,
    videoName: videoFile.getName(),
    videoId: videoFile.getId(),
    permissionId: permission.id,
    videoUrl: videoFile.getUrl()
  };
}

/**
 * Remove viewer access to one video for an enrolment.
 * Uses Advanced Drive API.
 *
 * @param {string} enrolmentId
 * @param {number} videoNumber
 */
function revokeVideoAccess(enrolmentId, videoNumber) {
  if (!enrolmentId) {
    throw new Error('Enrolment ID is required.');
  }

  if (!Number.isInteger(videoNumber) || videoNumber < 1) {
    throw new Error('A valid video number is required.');
  }

  const registrations = getRegistrations();

  const enrolment = registrations.find(
    registration => registration.enrolmentId === enrolmentId
  );

  if (!enrolment) {
    throw new Error('Enrolment not found: ' + enrolmentId);
  }

  if (!enrolment.email) {
    throw new Error('Enrolment email is missing.');
  }

  // Locate the course folder.
  const settingsFile = DriveApp.getFileById(
    COURSE_SETTINGS_SPREADSHEET_ID
  );

  const parents = settingsFile.getParents();

  if (!parents.hasNext()) {
    throw new Error('Course folder not found.');
  }

  const courseFolder = parents.next();

  // Locate the Videos folder.
  const videosFolders = courseFolder.getFoldersByName('Videos');

  if (!videosFolders.hasNext()) {
    throw new Error('Videos folder not found.');
  }

  const folder = videosFolders.next();
  const prefix = videoNumber + '-';

  // Locate the requested video.
  const files = folder.getFiles();
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

  // Find the participant's existing permission.
  const permissions = Drive.Permissions.list(
    videoFile.getId(),
    {
      fields: 'permissions(id,emailAddress,role,type)'
    }
  );

  const permission = (permissions.permissions || []).find(
    item =>
      item.type === 'user' &&
      item.emailAddress &&
      item.emailAddress.toLowerCase() === enrolment.email.toLowerCase()
  );

  if (permission) {
    // Remove the permission.
    Drive.Permissions.remove(
      videoFile.getId(),
      permission.id
    );
  }

  // Record the revocation.
  recordVideoAccessRevoked_(
    enrolmentId,
    videoNumber
  );

  Logger.log(
    'Viewer access removed: ' +
    enrolment.email +
    ' -> ' +
    videoFile.getName()
  );

  return {
    status: 'REVOKED',
    enrolmentId: enrolmentId,
    email: enrolment.email,
    videoName: videoFile.getName(),
    videoId: videoFile.getId()
  };
}

function isEnrolmentEligibleForVideoAccess_(enrolment) {
  return (
    enrolment.emailVerified === true &&
    enrolment.paymentVerified === true
  );
}


/**
 * Checks whether an enrolment's participant has viewer
 * permission on a specific video.
 *
 * Read-only: does not modify Drive permissions.
 */
function checkVideoAccess(enrolmentId, videoNumber) {
  if (!enrolmentId) {
    throw new Error('Enrolment ID is required.');
  }

  if (!Number.isInteger(videoNumber) || videoNumber < 1) {
    throw new Error('A valid video number is required.');
  }

  const registrations = getRegistrations();

  const enrolment = registrations.find(
    registration => registration.enrolmentId === enrolmentId
  );

  if (!enrolment) {
    throw new Error('Enrolment not found: ' + enrolmentId);
  }

  const courseFolder = DriveApp.getFolderById(
    DriveApp.getFileById(COURSE_SETTINGS_SPREADSHEET_ID)
      .getParents()
      .next()
      .getId()
  );

  const folders = courseFolder.getFoldersByName('Videos');

  if (!folders.hasNext()) {
    throw new Error('Videos folder not found.');
  }

  const folder = folders.next();
  const prefix = videoNumber + '-';

  const files = folder.getFiles();
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

  const viewers = videoFile.getViewers();

  const hasViewerAccess = viewers.some(
    viewer =>
      viewer.getEmail().toLowerCase() ===
      enrolment.email.toLowerCase()
  );

  const result = {
    enrolmentId: enrolmentId,
    email: enrolment.email,
    videoName: videoFile.getName(),
    videoId: videoFile.getId(),
    hasViewerAccess: hasViewerAccess
  };

  Logger.log(JSON.stringify(result, null, 2));

  return result;
}

/**
 * Reconciles actual Drive access with the expected access state
 * for one enrolment and one video.
 *
 * expectedAccess must be true or false.
 */

/**
 * Reconciles actual Drive access with the expected access state
 * for one enrolment and one video.
 *
 * expectedAccess must be true or false.
 */
function reconcileVideoAccess(
  enrolmentId,
  videoNumber,
  expectedAccess
) {
  if (typeof expectedAccess !== 'boolean') {
    throw new Error('Expected access must be true or false.');
  }

  const registrations = getRegistrations();

  const enrolment = registrations.find(
    registration => registration.enrolmentId === enrolmentId
  );

  if (!enrolment) {
    throw new Error('Enrolment not found: ' + enrolmentId);
  }

  const eligible =
    isEnrolmentEligibleForVideoAccess_(enrolment);

  if (expectedAccess && !eligible) {
    throw new Error(
      'Cannot grant access: enrolment is not eligible.'
    );
  }

  const actual = checkVideoAccess(
    enrolmentId,
    videoNumber
  ).hasViewerAccess;

  if (actual === expectedAccess) {
    Logger.log('No reconciliation needed.');

    return {
      status: 'NO_CHANGE',
      expectedAccess: expectedAccess,
      actualAccess: actual
    };
  }

  let grantResult = null;

  if (expectedAccess) {
    grantResult = grantVideoAccess(
      enrolmentId,
      videoNumber
    );
  } else {
    revokeVideoAccess(enrolmentId, videoNumber);
  }

  const verified = checkVideoAccess(
    enrolmentId,
    videoNumber
  ).hasViewerAccess;

  if (verified !== expectedAccess) {
    throw new Error(
      'Permission reconciliation failed verification.'
    );
  }

  // Record the grant only after successful verification.
  if (expectedAccess) {
    recordVideoAccessGranted_(
      enrolmentId,
      videoNumber,
      grantResult.videoId
    );
  }

  Logger.log('Permission successfully reconciled.');

  return {
    status: 'RECONCILED',
    expectedAccess: expectedAccess,
    actualAccess: verified
  };
}

function reconcileEnrolmentVideoAccess(enrolmentId, videoNumber, now) {
  // Find the enrolment.
  const enrolments = getRegistrations();

  const enrolment = enrolments.find(
    item => item.enrolmentId === enrolmentId
  );

  if (!enrolment) {
    throw new Error('Enrolment not found: ' + enrolmentId);
  }

  // Calculate whether access should currently be available.
  const decision = shouldVideoBeAccessible(
    enrolment,
    videoNumber,
    now
  );

  // Reconcile actual Google Drive permission with expected access.
  const reconciliation = reconcileVideoAccess(
    enrolmentId,
    videoNumber,
    decision.expectedAccess
  );

  let notification = null;

  // Notify only when access is expected and actually available.
  if (
    decision.expectedAccess === true &&
    reconciliation.actualAccess === true
  ) {
    try {
      notification = sendVideoAvailabilityNotification_(
        enrolmentId,
        videoNumber
      );
    } catch (error) {
      // Notification failure must not undo successful access.
      notification = {
        status: 'ERROR',
        message: error.message
      };

      Logger.log(
        'Video notification failed: ' + error.message
      );
    }
  }

  return {
    enrolmentId: enrolmentId,
    videoNumber: videoNumber,
    expectedAccess: decision.expectedAccess,
    reason: decision.reason,
    reconciliation: reconciliation,
    notification: notification
  };
}


