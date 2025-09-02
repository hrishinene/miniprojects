import express from 'express';
import dotenv from 'dotenv';
import userRoutes from './routes/userRoutes';
import finstrumentRoutes from './routes/finstrumentRoutes';
import finstitutionRoutes from './routes/finstitutionRoutes';
import subscriptionRoutes from './routes/subscriptionRoutes';
import billingRoutes from './routes/billingRoutes';
import auditRoutes from './routes/auditRoutes';
import tenantRoutes from './routes/tenantRoutes';
import roleRoutes from './routes/roleRoutes';
// import { logger } from './middlewares/logger';
import { profilePoint } from './middlewares/profilepoint';
import { setupSwagger } from './swagger';
import { basicAuth } from './middlewares/basicAuth';


dotenv.config();
const app = express();

// const PORT = 3000;


app.use(express.json());
// app.use(logger);
app.use(profilePoint);

app.use('/api/users', basicAuth, userRoutes);
app.use('/api/finstruments', finstrumentRoutes);
app.use('/api/finstitutions', finstitutionRoutes);
app.use('/api/subscriptions', subscriptionRoutes);
app.use('/api/billing', billingRoutes);
app.use('/api/audit', auditRoutes);
app.use('/api/tenants', tenantRoutes);
app.use('/api/roles', roleRoutes);

// Swagger docs
setupSwagger(app);

// app.listen(PORT, () => {
//   console.log(`Server running on http://localhost:${PORT}`);
//   console.log(`Swagger docs at http://localhost:${PORT}/api-docs`);
// });

export default app;
