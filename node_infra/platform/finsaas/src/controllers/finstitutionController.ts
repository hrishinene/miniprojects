import { Request, Response } from 'express';
import * as service from '../services/finstitutionService';

export const enlist = async (req: Request, res: Response) => {
  try {
    const finstitutions = await service.enlist();
    res.status(200).json(finstitutions);
  } catch (error) {
    console.error('Error fetching finstitutions:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
};

export const create = async (req: Request, res: Response) => {
  try {
    const newFinstitution = req.body;
    const finstitution = await service.create(newFinstitution);
    res.status(201).json(finstitution);
  } catch (error) {
    console.error('Error fetching finstitutions:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
}
