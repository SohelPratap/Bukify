import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import authRoutes from './routes/auth.routes.js';
import workerRoutes from './routes/worker.routes.js';
import customerRoutes from './routes/customer.routes.js';
import workerProfileRoutes from './routes/worker_profile.routes.js';
import customerProfileRoutes from './routes/customer_profile.routes.js';
import skillRoutes from "./routes/skills.routes.js";
import locationRoutes from "./routes/location.routes.js";
import jobsRoutes from "./routes/jobs.routes.js";













const app = express();
app.use(express.json());

app.get('/health', (_, res) => res.json({ ok: true }));

app.use('/auth', authRoutes);
app.use('/api/worker', workerRoutes);
app.use('/api/customer', customerRoutes);
app.use('/api/worker', workerProfileRoutes);
app.use('/api/customer', customerProfileRoutes);
app.use("/api/skills", skillRoutes);
app.use("/api/location", locationRoutes);
app.use("/api/jobs", jobsRoutes);



app.listen(5050, '0.0.0.0', () => {
  console.log('Server running on port 5050');
});
