-- Finstitutions table - to be used for authentication
CREATE TABLE Finstitutions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  finstitutionname VARCHAR(255) NOT NULL,
  finstitutiontype VARCHAR(255) NOT NULL,
  finstitutioncode VARCHAR(255) NOT NULL,
  finstitutionurl VARCHAR(255) NOT NULL,
  finstitutionlogo VARCHAR(255) NOT NULL,
  finstitutionstatus VARCHAR(50) NOT NULL,
  finstitutionlanguage VARCHAR(50) NOT NULL,
  finstitutionproducts TEXT[] NOT NULL,
  onBoardedOn TIMESTAMP NOT NULL,
  isActive BOOLEAN NOT NULL DEFAULT true,
  createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

