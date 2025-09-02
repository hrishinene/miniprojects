export interface Billing {
  id: string;
  finstitutionId: string;
  month: number;
  year: number;
  creditsConsumed: number;
  status: 'active' | 'paid' | 'cancelled';
  createdAt: Date;
  updatedAt: Date;
}
