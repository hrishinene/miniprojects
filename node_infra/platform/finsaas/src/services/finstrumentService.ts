import { pool } from "../db";
import { Finstrument } from "../models/finstrument";

export const enlist = async (): Promise<Finstrument[]> => {
  // Fetch the Finstrument from DB
  const result = await pool.query("SELECT * FROM finstruments");
  return result.rows;
};

// Function to create a new finstrument
// This function should be implemented to handle finstrument creation logic, such as saving to a database.
export const create = async (newFinstrument: Finstrument): Promise<Finstrument> => {
  // Save to database name, description, type, homepageUrl, healthUrl, secretKey, configUrl, isActive
  const query = `INSERT INTO finstruments (name, description, type, logoUrl, homepageUrl, healthUrl, secretKey, configUrl, isActive)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                 RETURNING *`;
  const values = [
    newFinstrument.name,
    newFinstrument.description,
    newFinstrument.type,
    newFinstrument.logoUrl,
    newFinstrument.homepageUrl,
    newFinstrument.healthUrl,
    newFinstrument.secretKey,
    newFinstrument.configUrl,
    newFinstrument.isActive,
  ];
  const result = await pool.query(query, values);
  // Return the created finstrument
  return result.rows[0];
}
