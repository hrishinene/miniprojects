function getCourseConfiguration() {
  const spreadsheet = SpreadsheetApp.openById(
    COURSE_SETTINGS_SPREADSHEET_ID
  );
  const settingsSheet = spreadsheet.getSheetByName('Settings');

  if (!settingsSheet) {
    throw new Error('Settings sheet not found.');
  }

  const values = settingsSheet.getDataRange().getValues();
  const settings = {};

  for (let i = 1; i < values.length; i++) {
    const key = values[i][0];
    let value = values[i][1];

    if (!key) continue;

    const settingName = String(key).trim();

    if (settingName === 'First Video Release Time') {
      value = settingsSheet.getRange(i + 1, 2).getDisplayValue();
    }

    settings[settingName] = value;
  }

  const requiredSettings = [
    'Organisation Name',
    'Course Name',
    'Course Status',
    'Time Zone',
    'Registration Mode',
    'Viewing Duration (Hours)',
    'Video Release Interval (Hours)',
    'First Video Release Time',
    'Email Verification Validity (Hours)',
    'Verification Resend Cooldown (Minutes)',
    'Maximum Verification Attempts'
  ];

  const missing = requiredSettings.filter(key => !settings[key]);

  if (missing.length) {
    throw new Error('Missing settings: ' + missing.join(', '));
  }

  if (settings['Email Verification Validity (Hours)'] <= 0) {
    throw new Error('Email verification validity must be greater than zero.');
  }

  if (settings['Verification Resend Cooldown (Minutes)'] < 0) {
    throw new Error('Verification resend cooldown cannot be negative.');
  }

  if (settings['Maximum Verification Attempts'] < 1) {
    throw new Error('Maximum verification attempts must be at least 1.');
  }

  if (!VERIFICATION_WEB_APP_URL) {
    throw new Error('Verification Web App URL is missing from InstallationConfig.gs.');
  }

  const verificationUrl = normalizeWebAppUrl_(
    VERIFICATION_WEB_APP_URL
  );
  settings['Verification Web App URL'] = verificationUrl;
  return settings;
}


function normalizeWebAppUrl_(value) {
  const text = String(value || '').trim();

  // Extract URL from Markdown link syntax, if present.
  const markdownMatch = text.match(
    /^\[https?:\/\/[^\]]+\]\((https?:\/\/[^)]+)\)$/
  );

  const url = markdownMatch ? markdownMatch[1] : text;

  // Validate the URL format.
  if (!/^https:\/\/script\.google\.com\/macros\/s\/[^/]+\/exec$/.test(url)) {
    throw new Error(
      'Invalid Verification Web App URL in Course Settings.'
    );
  }

  return url;
}

