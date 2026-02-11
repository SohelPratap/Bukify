import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import authRoutes from './routes/auth.routes.js';
import workerRoutes from './routes/worker.routes.js';
import customerRoutes from './routes/customer.routes.js';





const app = express();
app.use(express.json());

app.get('/health', (_, res) => res.json({ ok: true }));

app.use('/auth', authRoutes);
app.use('/api/worker', workerRoutes);
app.use('/api/customer', customerRoutes);



app.listen(5050, '0.0.0.0', () => {
  console.log('Server running on port 5050');
});
