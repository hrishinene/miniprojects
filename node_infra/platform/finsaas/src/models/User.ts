export interface User {
  id: string;
  username: string;
  password_hash: string;
  email: string;
  roles: string[];
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

