export interface Finstrument {
    id: string // Unique identifier for the Finstrument
    name: string; // Name of the financial instrument
    description: string;
    type: string; // Type of the financial instrument (e.g., stock, bond, etc.)
    logoUrl: string; // URL to the logo of the financial instrument
    homepageUrl: string; // URL to the homepage of the financial instrument
    healthUrl: string; // URL to the health information of the financial instrument
    secretKey: string; // Secret key for accessing the financial instrument
    configUrl: string; // URL for configuration settings of the financial instrument
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
}
