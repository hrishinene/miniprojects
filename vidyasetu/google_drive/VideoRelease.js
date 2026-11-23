/**
 * Calculates the scheduled release and expiry
 * timestamps for a video.
 *
 * @param {Date|string} courseStartDate
 * @param {number} videoNumber
 * @param {Object} settings Optional configuration.
 */

function calculateVideoSchedule(courseStartDate, videoNumber, settings) {
  // Validate video number.
  if (!Number.isInteger(videoNumber) || videoNumber < 1) {
    throw new Error('Video number must be a positive integer.');
  }

  // Validate course start date.
  if (!courseStartDate) {
    throw new Error('Course start date is required.');
  }

  // Validate settings.
  const timeZone = settings['Time Zone'];
  const firstReleaseTime = settings['First Video Release Time'];
  const intervalHours = Number(settings['Video Release Interval (Hours)']);
  const viewingHours = Number(settings['Viewing Duration (Hours)']);

  if (!timeZone || !firstReleaseTime) {
    throw new Error('Time zone and first video release time are required.');
  }

  if (!Number.isFinite(intervalHours) || intervalHours <= 0) {
    throw new Error('Video release interval must be greater than zero.');
  }

  if (!Number.isFinite(viewingHours) || viewingHours <= 0) {
    throw new Error('Viewing duration must be greater than zero.');
  }

  // Convert the course start date into yyyy-MM-dd.
  let startDateString;

  if (courseStartDate instanceof Date) {
    startDateString = Utilities.formatDate(
      courseStartDate,
      timeZone,
      'yyyy-MM-dd'
    );
  } else {
    startDateString = String(courseStartDate).trim();
  }

  if (!/^\d{4}-\d{2}-\d{2}$/.test(startDateString)) {
    throw new Error('Course start date must be in yyyy-MM-dd format.');
  }

  const [year, month, day] = startDateString.split('-').map(Number);

  // First video is released on the calendar day before the course starts.
  const firstReleaseDate = new Date(
    Date.UTC(year, month - 1, day - 1)
  );

  const firstReleaseDateString = Utilities.formatDate(
    firstReleaseDate,
    'UTC',
    'yyyy-MM-dd'
  );

  // Construct the first release timestamp in the course timezone.
  const firstReleaseDateTimeString =
    firstReleaseDateString + ' ' + firstReleaseTime;

  const firstReleaseAt = Utilities.parseDate(
    firstReleaseDateTimeString,
    timeZone,
    'yyyy-MM-dd HH:mm'
  );

  // Subsequent videos are released at configured elapsed-hour intervals.
  const releaseAt = new Date(
    firstReleaseAt.getTime() +
    (videoNumber - 1) * intervalHours * 60 * 60 * 1000
  );

  // Each video remains available for the configured viewing duration.
  const expiryAt = new Date(
    releaseAt.getTime() + viewingHours * 60 * 60 * 1000
  );

  return {
    videoNumber: videoNumber,
    timeZone: timeZone,
    releaseAt: releaseAt,
    expiryAt: expiryAt
  };
}

/**
 * Determines whether a video should currently be accessible.
 */
function shouldVideoBeAccessible(
  enrolment,
  videoNumber,
  now
) {
  if (!enrolment) {
    throw new Error('Enrolment is required.');
  }

  now = now || new Date();

  const eligible =
    isEnrolmentEligibleForVideoAccess_(enrolment);

  if (!eligible) {
    return {
      expectedAccess: false,
      reason: 'NOT_ELIGIBLE'
    };
  }

  // Load the current course settings.
  const settings = getCourseConfiguration();

  // Calculate the video's release and expiry schedule.
  const schedule = calculateVideoSchedule(
    enrolment.courseStartDate,
    videoNumber,
    settings
  );

  if (now < schedule.releaseAt) {
    return {
      expectedAccess: false,
      reason: 'NOT_YET_RELEASED',
      releaseAt: schedule.releaseAt,
      expiryAt: schedule.expiryAt
    };
  }

  if (now >= schedule.expiryAt) {
    return {
      expectedAccess: false,
      reason: 'EXPIRED',
      releaseAt: schedule.releaseAt,
      expiryAt: schedule.expiryAt
    };
  }

  return {
    expectedAccess: true,
    reason: 'AVAILABLE',
    releaseAt: schedule.releaseAt,
    expiryAt: schedule.expiryAt
  };
}


/**
 * Retrieves course videos in numerical sequence.
 * Video filenames must begin with a number followed by a dash.
 */
function getCourseVideos() {
  const folder = DriveApp.getFolderById(VIDEOS_FOLDER_ID);
  const files = folder.getFiles();

  const videos = [];

  while (files.hasNext()) {
    const file = files.next();
    const name = file.getName();

    const match = name.match(/^(\d+)-/);

    if (match) {
      videos.push({
        videoNumber: Number(match[1]),
        name: name,
        id: file.getId()
      });
    }
  }

  videos.sort((a, b) => a.videoNumber - b.videoNumber);

  // Ensure video numbers are unique.
  for (let i = 1; i < videos.length; i++) {
    if (videos[i].videoNumber === videos[i - 1].videoNumber) {
      throw new Error(
        'Duplicate video number: ' + videos[i].videoNumber
      );
    }
  }

  return videos;
}

