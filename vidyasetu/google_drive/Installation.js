// function installPaymentVerificationTrigger() {
//   ScriptApp.newTrigger('handlePaymentVerificationEdit')
//     .forSpreadsheet(REGISTRATION_SPREADSHEET_ID)
//     .onEdit()
//     .create();
// }

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

function installSchedulerTrigger() {
  const handler = 'runVideoAccessScheduler';
  const triggers = ScriptApp.getProjectTriggers().filter(
    trigger => trigger.getHandlerFunction() === handler
  );

  if (
    triggers.length === 1 &&
    triggers[0].getEventType() === ScriptApp.EventType.CLOCK
  ) {
    Logger.log('Scheduler trigger is already installed.');
    return;
  }

  triggers.forEach(trigger => ScriptApp.deleteTrigger(trigger));

  ScriptApp.newTrigger(handler)
    .timeBased()
    .everyMinutes(5)
    .create();

  Logger.log('5-minute scheduler trigger installed.');
}
