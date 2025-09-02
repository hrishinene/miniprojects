-- Subscriptions table - to be used for authentication
CREATE TABLE Subscription (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  finstitutionId UUID NOT NULL,
  finstrumentId UUID NOT NULL,
  subscriptionDate TIMESTAMP NOT NULL,
  expirationDate TIMESTAMP NOT NULL,
  status VARCHAR(20) CHECK (status IN ('active', 'expired', 'cancelled')) NOT NULL,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (finstitutionId) REFERENCES Finstitutions(id),
  FOREIGN KEY (finstrumentId) REFERENCES Finstruments(id)
);

