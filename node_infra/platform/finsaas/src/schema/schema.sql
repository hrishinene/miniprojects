-- Run pre-process script
\i 'preProcess.sql'

-- Run sql files from model directory
\i 'models/tenants.sql'
\i 'models/users.sql'

-- Run post-process script
\i 'postProcess.sql'