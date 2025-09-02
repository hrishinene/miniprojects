import { Request, Response } from 'express';
import * as service from '../services/billingService';

export const enlist = async (req: Request, res: Response) => {
  try {
    const billings = await service.enlist();
    res.status(200).json(billings);
  } catch (error) {
    console.error('Error fetching billings:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
};

export const create = async (req: Request, res: Response) => {
  try {
    const newBilling = req.body;
    const billing = await service.create(newBilling);
    res.status(201).json(billing);
  } catch (error) {
    console.error('Error fetching billings:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
}
