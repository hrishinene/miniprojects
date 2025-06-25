import * as service from '../services/roleService';
import { Request, Response } from 'express';
import { Role } from '../models/role';

export const enlist = async (req: Request, res: Response) => {
    try {
        const roles: Role[] = await service.enlist();
        res.status(200).json(roles);
    } catch (error) {
        console.error('Error fetching roles:', error);
        res.status(500).json({ message: 'Internal Server Error' });
    }
}