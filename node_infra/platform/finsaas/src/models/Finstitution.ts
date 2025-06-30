export interface Finstitution {
  id: string;
  finstitutionname: string;
  password_hash: string;
  email: string;
  roles: string[];
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

