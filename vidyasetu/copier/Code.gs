const CONFIG = {
  TEMPLATE_FOLDER_ID: '1WtBhA_qkztw_IHRxj1DyjOHTbP7DjQB',
  COURSES_FOLDER_ID: '1XoAJiXB5Yqnf07nkodbU3vI42giMmxVM',
  COURSE_SETTINGS_ID: '18S1WSWrhNlM7OijWIkZmGNDm6ZqncXBlftoSTHxo2JI',
  FLEXIBLE_FORM_ID: '1dQDdQNFK8-9NLKYZLkZr0eln3Z9LhE8AALyok5RAcFo',
  GROUP_FORM_ID: '1fUk7KW1twEnomW-keXgRLiTohCiLhXNzpAsczSaCmAo'
};

function createCourse(courseName) {
  if (typeof courseName !== 'string' || !courseName.trim()) {
    throw new Error('courseName must be a non-empty string.');
  }

  const coursesFolder = DriveApp.getFolderById(CONFIG.COURSES_FOLDER_ID);
  const existingFolders = coursesFolder.getFoldersByName(courseName);

  if (existingFolders.hasNext()) {
    throw new Error(
      'A course folder named "' + courseName + '" already exists.'
    );
  }

  const courseFolder = coursesFolder.createFolder(courseName);

  try {
    const courseSettings = DriveApp.getFileById(
      CONFIG.COURSE_SETTINGS_ID
    ).makeCopy('Course Settings', courseFolder);
    const flexibleForm = DriveApp.getFileById(
      CONFIG.FLEXIBLE_FORM_ID
    ).makeCopy('Flexible Registration', courseFolder);
    const groupForm = DriveApp.getFileById(
      CONFIG.GROUP_FORM_ID
    ).makeCopy('Group Registration', courseFolder);
    const videosFolder = courseFolder.createFolder('Videos');

    const result = {
      courseFolder: {
        id: courseFolder.getId(),
        url: courseFolder.getUrl()
      },
      assets: {
        courseSettingsSpreadsheet: {
          id: courseSettings.getId(),
          url: courseSettings.getUrl()
        },
        flexibleRegistrationForm: {
          id: flexibleForm.getId(),
          url: flexibleForm.getUrl()
        },
        groupRegistrationForm: {
          id: groupForm.getId(),
          url: groupForm.getUrl()
        },
        videosFolder: {
          id: videosFolder.getId(),
          url: videosFolder.getUrl()
        }
      }
    };

    Logger.log(JSON.stringify(result, null, 2));
    return result;
  } catch (error) {
    const detail = error && error.message
      ? error.message
      : String(error);
    const message =
      'Course creation failed after creating folder ID ' +
      courseFolder.getId() + ': ' + detail;

    Logger.log(message);
    throw new Error(message);
  }
}
