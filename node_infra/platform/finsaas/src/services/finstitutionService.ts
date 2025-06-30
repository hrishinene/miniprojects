import { pool } from "../db";
import { Finstitution } from "../models/Finstitution";

export const enlist = async (): Promise<Finstitution[]> => {
  // Fetch the finstitution from DB
  const result = await pool.query("SELECT * FROM finstitutions");
  return result.rows;
};

// Function to create a new finstitution
// This function should be implemented to handle finstitution creation logic, such as saving to a database.
export const create = async (newFinstitution: Finstitution): Promise<Finstitution> => {
  // Save to database
   const result = await pool.query(
    `INSERT INTO finstitutions (finstitutionname, password_hash, email, roles, is_active)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [newFinstitution.finstitutionname, newFinstitution.password_hash, newFinstitution.email, newFinstitution.roles || [], newFinstitution.isActive || true]
  );
  return result.rows[0];
}

