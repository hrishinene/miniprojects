import { Request, Response } from 'express';
import * as service from '../services/finstrumentService';

export const enlist = async (req: Request, res: Response) => {
  try {
    const finstruments = await service.enlist();
    res.status(200).json(finstruments);
  } catch (error) {
    console.error('Error fetching finstruments:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
};

export const create = async (req: Request, res: Response) => {
  try {
    const newFinstrument = req.body;
    const finstrument = await service.create(newFinstrument);
    res.status(201).json(finstrument);
  } catch (error) {
    console.error('Error fetching finstruments:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
}
