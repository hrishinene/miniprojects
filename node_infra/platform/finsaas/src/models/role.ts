// A class called Role that represents a user role in the system.
// Contains name and description fields
// This is not a Database model. Set of roles are hardcoded in codebase
export class Role {
    name: string;
    description: string;
    constructor(name: string, description: string) {
        this.name = name;
        this.description = description;
    }
    static getAllRoles() {
        return [
            new Role('CreditOS.Root', 'Root Admin with full access'),
            new Role('CreditOS.FinAdmin', 'Admin of a Finstitution with full access'),
            new Role('CreditOS.FinUser', 'User of a Finstitution with limited access'),
            // Each finstrument adds more roles which can be added to user
        ];
    }
    static getRoleByName(name: string) {
        return this.getAllRoles().find(role => role.name === name);
    }
}

// Example usage
// const roles = Role.getAllRoles();
// console.log(roles);
// const adminRole = Role.getRoleByName('Admin');
// console.log(adminRole);

// Exporting the Role class for use in other modules
export default Role;
