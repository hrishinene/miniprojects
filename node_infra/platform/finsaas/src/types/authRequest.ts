import { Request } from 'express';

export interface AuthenticatedUser {
  id: string;
  username: string;
}

export interface AuthRequest extends Request {
  user?: AuthenticatedUser;
}
