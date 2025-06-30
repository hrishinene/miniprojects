import { Request, Response } from 'express';
import * as service from '../services/userService';

export const enlist = async (req: Request, res: Response) => {
  try {
    const users = await service.enlist();
    res.status(200).json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
};

export const create = async (req: Request, res: Response) => {
  try {
    const newUser = req.body;
    const user = await service.create(newUser);
    res.status(201).json(user);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
}
