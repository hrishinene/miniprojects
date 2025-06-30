-- Finstitutions table - to be used for authentication
CREATE TABLE finstitutions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  finstitutionname TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  roles TEXT[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
