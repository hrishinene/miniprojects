import { Pool } from 'pg';

export const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'DB1',
    password: 'unplugged',
    port: 5432,
});
