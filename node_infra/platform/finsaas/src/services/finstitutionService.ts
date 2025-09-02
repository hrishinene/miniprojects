import { pool } from "../db";
import { Finstitution } from "../models/Finstitution";

export const enlist = async (): Promise<Finstitution[]> => {
  // Fetch the finstitution from DB
  const result = await pool.query("SELECT * FROM finstitutions");
  return result.rows;
};


// CREATE TABLE Finstitution (
//   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
//   finstitutionname VARCHAR(255) NOT NULL,
//   finstitutiontype VARCHAR(255) NOT NULL,
//   finstitutioncode VARCHAR(255) NOT NULL,
//   finstitutionurl VARCHAR(255) NOT NULL,
//   finstitutionlogo VARCHAR(255) NOT NULL,
//   finstitutionstatus VARCHAR(50) NOT NULL,
//   finstitutionlanguage VARCHAR(50) NOT NULL,
//   finstitutionproducts TEXT[] NOT NULL,
//   onBoardedOn TIMESTAMP NOT NULL,
//   isActive BOOLEAN NOT NULL DEFAULT true,
//   createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
//   updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
// );
// Function to create a new finstitution
// This function should be implemented to handle finstitution creation logic, such as saving to a database.
export const create = async (newFinstitution: Finstitution): Promise<Finstitution> => {
  // Save to database
   const result = await pool.query(
    `INSERT INTO finstitutions (
      finstitutionname, 
      finstitutiontype, 
      finstitutioncode, 
      finstitutionurl, 
      finstitutionlogo, 
      finstitutionstatus, 
      finstitutionlanguage, 
      finstitutionproducts, 
      onBoardedOn, 
      isActive
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING *`,
    [
      newFinstitution.finstitutionname,
      newFinstitution.finstitutiontype,
      newFinstitution.finstitutioncode,
      newFinstitution.finstitutionurl,
      newFinstitution.finstitutionlogo,
      newFinstitution.finstitutionstatus,
      newFinstitution.finstitutionlanguage,
      newFinstitution.finstitutionproducts,
      newFinstitution.onBoardedOn,
      newFinstitution.isActive
    ]
  );
  return result.rows[0];
}

