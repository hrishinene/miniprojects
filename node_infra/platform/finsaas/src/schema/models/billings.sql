-- Billings table - to be used for authentication
CREATE TABLE IF NOT EXISTS Billings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  finstitutionId UUID NOT NULL,
  month INT NOT NULL,
  year INT NOT NULL,
  creditsConsumed INT NOT NULL DEFAULT 0,
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (finstitutionId, month, year),
  FOREIGN KEY (finstitutionId) REFERENCES Finstitutions(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_billings_finstitutionId ON Billings(finstitutionId);
CREATE INDEX IF NOT EXISTS idx_billings_month_year ON Billings(month, year);