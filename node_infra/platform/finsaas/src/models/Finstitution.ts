export interface Finstitution {
  id: string;
  finstitutionname: string;
  finstitutiontype: string;
  finstitutioncode: string;
  finstitutionurl: string;
  finstitutionlogo: string;
  finstitutionstatus: string;
  finstitutionlanguage: string;
  finstitutionproducts: string[];
  onBoardedOn: Date;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}