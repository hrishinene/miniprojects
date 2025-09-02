import { pool } from "../db";
import { Subscription } from "../models/subscription";

export const enlist = async (): Promise<Subscription[]> => {
  // Fetch the subscription from DB
  const result = await pool.query("SELECT * FROM subscriptions");
  return result.rows;
};

// CREATE TABLE Subscription (
//   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
//   finstitutionId UUID NOT NULL,
//   finstrumentId UUID NOT NULL,
//   subscriptionDate TIMESTAMP NOT NULL,
//   expirationDate TIMESTAMP NOT NULL,
//   status VARCHAR(20) CHECK (status IN ('active', 'expired', 'cancelled')) NOT NULL,
//   createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
//   updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
//   FOREIGN KEY (finstitutionId) REFERENCES Finstitution(id),
//   FOREIGN KEY (finstrumentId) REFERENCES Finstrument(id)
// );

// Function to create a new subscription
// This function should be implemented to handle subscription creation logic, such as saving to a database.
export const create = async (newSubscription: Subscription): Promise<Subscription> => {
  // Save to database
   const result = await pool.query(
    `INSERT INTO subscriptions (finstitutionId, finstrumentId, subscriptionDate, expirationDate, status)
     VALUES ($1, $2, $3, $4, $5) RETURNING *`,
    [
      newSubscription.finstitutionId,
      newSubscription.finstrumentId,
      newSubscription.subscriptionDate,
      newSubscription.expirationDate,
      newSubscription.status
    ]
  );
  return result.rows[0];
}

