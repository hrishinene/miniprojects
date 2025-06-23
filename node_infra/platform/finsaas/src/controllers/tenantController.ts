import { Request, Response } from 'express';
import * as TenantModel from '../models/tenant';

export const getAll = async (_req: Request, res: Response) => {
  // print a message to the console
  console.log('Fetching all tenants'); 
  const tenants = await TenantModel.getAllTenants();
  res.json(tenants);
};

export const getById = async (req: Request, res: Response) => {
  const tenant = await TenantModel.getTenantById(req.params.id);
  if (!tenant) return res.status(404).send('Tenant not found');
  res.json(tenant);
};

export const create = async (req: Request, res: Response) => {
  const tenant = await TenantModel.createTenant(req.body);
  res.status(201).json(tenant);
};

export const update = async (req: Request, res: Response) => {
  const tenant = await TenantModel.updateTenant(req.params.id, req.body);
  if (!tenant) return res.status(404).send('Tenant not found');
  res.json(tenant);
};

export const remove = async (req: Request, res: Response) => {
  const success = await TenantModel.deleteTenant(req.params.id);
  if (!success) return res.status(404).send('Tenant not found');
  res.status(204).send();
};
