-- Run pre-process script
\i 'preProcess.sql'

-- Run sql files from model directory
\i 'models/tenants.sql'
\i 'models/users.sql'
\i 'models/finstruments.sql'
\i 'models/finstitutions.sql'
\i 'models/billings.sql'
\i 'models/audits.sql'
\i 'models/subscriptions.sql'

-- Run post-process script
\i 'postProcess.sql'