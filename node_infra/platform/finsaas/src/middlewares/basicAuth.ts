/**
 * Middleware for Basic Authentication
 * This middleware checks for the presence of a Basic Authorization header,
 * decodes it, and verifies the username and password against the database.
 * If authentication is successful, it attaches the user information to the request object.
 */
import { Response, NextFunction } from 'express';
import bcrypt from 'bcrypt';
import {pool} from '../db';
import { AuthRequest } from '../types/authRequest';

export const basicAuth = async (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Basic ')) {
    res.set('WWW-Authenticate', 'Basic realm="Access to API"');
    return res.status(401).json({ message: 'Missing Authorization Header' });
  }

  const base64Credentials = authHeader.split(' ')[1];
  const credentials = Buffer.from(base64Credentials, 'base64').toString('utf-8');
  const [username, password] = credentials.split(':');
  // print username and password to console
  // console.log(`Username: ${username}, Password: ${password}`);

  const result = await pool.query('SELECT * FROM users WHERE username = $1', [username]);
  const user = result.rows[0];
    // print user to console
  // console.log(`User: ${JSON.stringify(user)}`);

  if (!user || !(await bcrypt.compare(password, user.password_hash))) {
    return res.status(401).json({ message: 'Invalid username or password' });
  }

  req.user = { id: user.id, username: user.username };
  next();
};

