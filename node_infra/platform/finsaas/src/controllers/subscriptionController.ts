import { Request, Response } from 'express';
import * as service from '../services/subscriptionService';

export const enlist = async (req: Request, res: Response) => {
  try {
    const subscriptions = await service.enlist();
    res.status(200).json(subscriptions);
  } catch (error) {
    console.error('Error fetching subscriptions:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
};

export const create = async (req: Request, res: Response) => {
  try {
    const newSubscription = req.body;
    const subscription = await service.create(newSubscription);
    res.status(201).json(subscription);
  } catch (error) {
    console.error('Error fetching subscriptions:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
}
