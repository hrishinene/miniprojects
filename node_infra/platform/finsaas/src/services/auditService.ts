import { pool } from "../db";
import { Audit } from "../models/audit";

export const enlist = async (): Promise<Audit[]> => {
  // Fetch the audit from DB
  const result = await pool.query("SELECT * FROM audits");
  return result.rows;
};

// CREATE TABLE IF NOT EXISTS Audits (
//   id SERIAL PRIMARY KEY,
//   userId VARCHAR(255) NOT NULL,
//   action VARCHAR(255) NOT NULL,
//   timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
//   details TEXT,
//   FOREIGN KEY (userId) REFERENCES Users(id) ON DELETE CASCADE
// );

// Function to create a new audit
// This function should be implemented to handle audit creation logic, such as saving to a database.
export const create = async (newAudit: Audit): Promise<Audit> => {
  // Save to database
   const result = await pool.query(
    "INSERT INTO audits (userId, action, timestamp, details) VALUES ($1, $2, $3, $4) RETURNING *",
    [newAudit.userId, newAudit.action, newAudit.timestamp, newAudit.details]
  );
  return result.rows[0];
}

