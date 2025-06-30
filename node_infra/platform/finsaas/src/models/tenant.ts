import { pool } from '../db';

// SQL to create the tenants table matching the Tenant interface:
// 
// CREATE TABLE tenants (
//   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
//   name VARCHAR(255) NOT NULL,
//   domain VARCHAR(255) NOT NULL,
//   is_active BOOLEAN NOT NULL DEFAULT TRUE,
//   created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
//   updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
// );

export interface Tenant {
  id: string;
  name: string;
  domain: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export const getAllTenants = async (): Promise<Tenant[]> => {
  const result = await pool.query('SELECT * FROM tenants ORDER BY created_at DESC');
  return result.rows;
};

export const getTenantById = async (id: string): Promise<Tenant | null> => {
  const result = await pool.query('SELECT * FROM tenants WHERE id = $1', [id]);
  return result.rows[0] || null;
};

export const createTenant = async (tenant: Partial<Tenant>): Promise<Tenant> => {
  const result = await pool.query(
    `INSERT INTO tenants (name, domain, is_active)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [tenant.name, tenant.domain, tenant.isActive ?? true]
  );
  return result.rows[0];
};

export const updateTenant = async (
  id: string,
  updates: Partial<Tenant>
): Promise<Tenant | null> => {
  const result = await pool.query(
    `UPDATE tenants SET name = $1, domain = $2, is_active = $3, updated_at = NOW()
     WHERE id = $4 RETURNING *`,
    [updates.name, updates.domain, updates.isActive, id]
  );
  return result.rows[0] || null;
};

export const deleteTenant = async (id: string): Promise<boolean> => {
  const result = await pool.query(`DELETE FROM tenants WHERE id = $1`, [id]);
  return result.rowCount === 1;
};
