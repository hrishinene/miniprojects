import { Request, Response } from 'express';
import * as service from '../services/auditService';

export const enlist = async (req: Request, res: Response) => {
  try {
    const audits = await service.enlist();
    res.status(200).json(audits);
  } catch (error) {
    console.error('Error fetching audits:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
};

export const create = async (req: Request, res: Response) => {
  try {
    const newAudit = req.body;
    const audit = await service.create(newAudit);
    res.status(201).json(audit);
  } catch (error) {
    console.error('Error fetching audits:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
}
