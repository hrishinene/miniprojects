import express from 'express';
import dotenv from 'dotenv';
import userRoutes from './routes/userRoutes';
import finstrumentRoutes from './routes/finstrumentRoutes';
import finstitutionRoutes from './routes/finstitutionRoutes';
import tenantRoutes from './routes/tenantRoutes';
import roleRoutes from './routes/roleRoutes';
import { logger } from './middlewares/logger';
import { setupSwagger } from './swagger';


dotenv.config();
const app = express();

// const PORT = 3000;


app.use(express.json());
app.use(logger);
app.use('/api/users', userRoutes);
app.use('/api/finstruments', finstrumentRoutes);
app.use('/api/finstitutions', finstitutionRoutes);
app.use('/api/tenants', tenantRoutes);
app.use('/api/roles', roleRoutes);

// Swagger docs
setupSwagger(app);

// app.listen(PORT, () => {
//   console.log(`Server running on http://localhost:${PORT}`);
//   console.log(`Swagger docs at http://localhost:${PORT}/api-docs`);
// });

export default app;
