import { Pool } from 'pg';
import { config } from '../config/config';

export const db = new Pool({
  host: config.db.host,
  user: config.db.user,
  password: config.db.password,
  database: config.db.database
});
