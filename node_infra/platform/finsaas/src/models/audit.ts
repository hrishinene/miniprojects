export interface Audit {
  id: string;
  userId: string;
  action: string;
  timestamp: Date;
  details: string;
}
