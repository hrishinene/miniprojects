import Role from "../models/role";

export const enlist = async (): Promise<Role[]> => {
    // Placeholder: Replace with actual logic to fetch roles
    return Role.getAllRoles();
};