import { User } from "../models/User";

export const enlist = async (): Promise<User[]> => {
  return [{
    id: "123", username: 'Alice',
    password_hash: "",
    email: "",
    roles: [],
    isActive: false,
    createdAt: new Date(),
    updatedAt: new Date()
  }];
};
