import { Pool } from 'pg';

export const pool = new Pool({
    user: 'hvn',
    host: 'localhost',
    database: 'finsaas_root1',
    password: 'unplugged',
    port: 5432,
});
