import { pool } from "../db";
import { Billing } from "../models/billing";

export const enlist = async (): Promise<Billing[]> => {
  // Fetch the billing from DB
  const result = await pool.query("SELECT * FROM billings");
  return result.rows;
};


// CREATE TABLE IF NOT EXISTS Billings (
//   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
//   finstitutionId VARCHAR(255) NOT NULL,
//   month INT NOT NULL,
//   year INT NOT NULL,
//   creditsConsumed INT NOT NULL DEFAULT 0,
//   status VARCHAR(20) NOT NULL DEFAULT 'active',
//   createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
//   updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
//   UNIQUE (finstitutionId, month, year),
//   FOREIGN KEY (finstitutionId) REFERENCES Finstitutions(id) ON DELETE CASCADE
// );

// Function to create a new billing
// This function should be implemented to handle billing creation logic, such as saving to a database.
export const create = async (newBilling: Billing): Promise<Billing> => {
  // Save to database
   const result = await pool.query(
    `INSERT INTO billings (finstitutionId, month, year, creditsConsumed, status)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [
      newBilling.finstitutionId,
      newBilling.month,
      newBilling.year,
      newBilling.creditsConsumed,
      newBilling.status
    ]
  );
  return result.rows[0];
}

