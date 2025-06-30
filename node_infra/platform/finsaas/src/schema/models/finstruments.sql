CREATE TABLE IF NOT EXISTS finstruments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL,
    logoUrl TEXT,
    homepageUrl TEXT,
    healthUrl TEXT,
    secretKey TEXT NOT NULL,
    configUrl TEXT,
    isActive BOOLEAN NOT NULL DEFAULT true,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (name, type)
);