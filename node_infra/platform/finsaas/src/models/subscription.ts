
export interface Subscription {
  id: string;
  finstitutionId: string;
  finstrumentId: string;
  subscriptionDate: Date;
  expirationDate: Date;
  status: 'active' | 'expired' | 'cancelled';
  createdAt: Date;
  updatedAt: Date;
}

