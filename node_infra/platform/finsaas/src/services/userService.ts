import { pool } from "../db";
import { User } from "../models/User";

export const enlist = async (): Promise<User[]> => {
  // Fetch the user from DB
  const result = await pool.query("SELECT * FROM users");
  return result.rows;
};

// Function to create a new user
// This function should be implemented to handle user creation logic, such as saving to a database.
export const create = async (newUser: User): Promise<User> => {
  // Save to database
   const result = await pool.query(
    `INSERT INTO users (username, password_hash, email, roles, is_active)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [newUser.username, newUser.password_hash, newUser.email, newUser.roles || [], newUser.isActive || true]
  );
  return result.rows[0];
}

