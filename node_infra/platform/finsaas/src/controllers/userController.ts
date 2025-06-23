import { Request, Response } from 'express';

export const getAllUsers = async (req: Request, res: Response) => {
  res.json([{ id: 1, name: 'Alice' }]);
};
