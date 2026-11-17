function doGet(e) {
  const settings = getCourseConfiguration();

  let status = 'INVALID';

  const enrolmentId = e && e.parameter
    ? e.parameter.id
    : null;

  const token = e && e.parameter
    ? e.parameter.token
    : null;

  if (enrolmentId && token) {
    try {
      const result = verifyEnrolmentEmail(enrolmentId, token);
      status = result.status;
    } catch (error) {
      Logger.log('Verification error: ' + error.message);
      status = 'ERROR';
    }
  }

  const messages = {
    VERIFIED: {
      title: 'Email Verified',
      message: settings['Verification Success Message']
    },
    ALREADY_VERIFIED: {
      title: 'Already Verified',
      message: 'Your email address has already been verified.'
    },
    EXPIRED: {
      title: 'Link Expired',
      message: 'This verification link has expired. Please request a new verification email.'
    },
    INVALID: {
      title: 'Invalid Link',
      message: 'This verification link is invalid. Please check the link or request a new one.'
    },
    ERROR: {
      title: 'Something Went Wrong',
      message: 'We could not complete your verification. Please try again later or contact support.'
    }
  };

  const page = HtmlService.createTemplateFromFile('Verification');

  page.organisationName = settings['Organisation Name'];
  page.courseName = settings['Course Name'];
  page.pageTitle = messages[status].title;
  page.message = messages[status].message;

  return page.evaluate()
    .setTitle(settings['Organisation Name']);
}
