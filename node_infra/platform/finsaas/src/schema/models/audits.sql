-- Audits table - to be used for authentication
CREATE TABLE IF NOT EXISTS Audits (
  id SERIAL PRIMARY KEY,
  userId UUID NOT NULL,
  action VARCHAR(255) NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  details TEXT,
  FOREIGN KEY (userId) REFERENCES Users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_audits_userId ON Audits(userId);
CREATE INDEX IF NOT EXISTS idx_audits_action ON Audits(action);
CREATE INDEX IF NOT EXISTS idx_audits_timestamp ON Audits(timestamp);
