/**
 * Processes video access for every enrolment and course video.
 */

function runVideoAccessScheduler() {
  initialiseCourse();

  const now = new Date();

  synchronisePaymentStatus();

  const enrolments = getRegistrations();
  const videos = getCourseVideos();

  Logger.log('Video Access Scheduler started');
  Logger.log('Enrolments: ' + enrolments.length);
  Logger.log('Videos: ' + videos.length);

  let processed = 0;
  let failed = 0;

  const permissionsGranted = [];
  const permissionsRevoked = [];

  enrolments.forEach(enrolment => {
    if (!enrolment.enrolmentId) {
      Logger.log('Skipping registration without EnrolmentID');
      return;
    }

    videos.forEach(video => {
      try {
        const result = reconcileEnrolmentVideoAccess(
          enrolment.enrolmentId,
          video.videoNumber,
          now
        );

        processed++;

        if (result.reconciliation.status === 'RECONCILED') {
          const change = {
            enrolmentId: enrolment.enrolmentId,
            name: enrolment.name,
            email: enrolment.email,
            videoName: video.name
          };

          if (result.expectedAccess) {
            permissionsGranted.push(change);
          } else {
            permissionsRevoked.push(change);
          }
        }

        Logger.log(
          enrolment.enrolmentId +
          ' | Video ' + video.videoNumber +
          ' | ' + result.reason +
          ' | ' + result.reconciliation.status +
          ' | Notification: ' +
          (result.notification ? result.notification.status : 'N/A')
        );

      } catch (error) {
        failed++;

        Logger.log(
          'FAILED | ' +
          enrolment.enrolmentId +
          ' | Video ' + video.videoNumber +
          ' | ' + error.message
        );
      }
    });
  });

  Logger.log('------------------------------');
  Logger.log('Video Access Scheduler completed');
  Logger.log('Successfully processed: ' + processed);
  Logger.log('Failed: ' + failed);
  Logger.log('Permissions granted: ' + permissionsGranted.length);
  Logger.log('Permissions revoked: ' + permissionsRevoked.length);

  // Send an admin summary only when permissions changed.
  if (
    permissionsGranted.length > 0 ||
    permissionsRevoked.length > 0
  ) {
    try {
      sendSchedulerSummaryEmail_(
        permissionsGranted,
        permissionsRevoked,
        failed,
        now
      );
    } catch (error) {
      Logger.log(
        'Scheduler summary email failed: ' + error.message
      );
    }
  } else {
    Logger.log('No permission changes. Admin email not sent.');
  }
}



function sendSchedulerSummaryEmail_(
  permissionsGranted,
  permissionsRevoked,
  failed,
  runTime
) {
  const settings = getCourseConfiguration();
  const adminEmail = settings['Support Email'];

  if (!adminEmail) {
    throw new Error('Support Email is not configured.');
  }

  const courseName = settings['Course Name'];

  function formatChanges(changes) {
    if (changes.length === 0) {
      return '<p>None</p>';
    }

    return '<ul>' + changes.map(change =>
      '<li>' +
      '<b>' + change.videoName + '</b><br>' +
      change.name + ' (' + change.email + ')<br>' +
      'Enrolment: ' + change.enrolmentId +
      '</li>'
    ).join('') + '</ul>';
  }

  const timeZone = settings['Time Zone'];
  const formattedTime = Utilities.formatDate(
    runTime,
    timeZone,
    'dd-MMM-yyyy HH:mm:ss'
  );

  const subject =
    'Video Access Update – ' + courseName;

  const htmlBody =
    '<h2>Video Access Scheduler Summary</h2>' +
    '<p><b>Course:</b> ' + courseName + '</p>' +
    '<p><b>Run time:</b> ' + formattedTime + '</p>' +
    '<p><b>Permissions granted:</b> ' +
    permissionsGranted.length + '</p>' +
    formatChanges(permissionsGranted) +
    '<p><b>Permissions revoked:</b> ' +
    permissionsRevoked.length + '</p>' +
    formatChanges(permissionsRevoked) +
    '<p><b>Failed operations:</b> ' + failed + '</p>';

  MailApp.sendEmail({
    to: adminEmail,
    subject: subject,
    htmlBody: htmlBody
  });
}
