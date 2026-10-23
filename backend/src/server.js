require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { supabase,BUCKET} = require('./config/supabase');

const app = express();
app.use((req, res, next) => {
  console.log(new Date().toISOString(), req.method, req.url);
  next();
});
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use((req, res, next) => {
  console.log(req.method, req.url, 'x-user-id:', req.headers['x-user-id']);
  next();
});
app.get('/api/health', (_req, res) => res.json({ ok: true }));
app.use('/api/cv', require('./routes/cv.routes'));
app.use('/api/jobs', require('./routes/jobs.routes'));
app.use('/api/templates', require('./routes/templates'));
   const jobRequirements = require('./createcv');
   app.use('/api/job', jobRequirements);

app.use((_req, res) => res.status(404).json({ error: 'Route not found' }));

// Central error handler (multer errors, thrown errors, etc.)
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error(err);
  if (err.code === 'LIMIT_FILE_SIZE')
    return res.status(413).json({ error: 'File too large (max 5MB).' });
  res.status(err.status || 500).json({ error: err.message || 'Server error' });
});

const port = process.env.PORT || 3000;
app.listen(port, '0.0.0.0', async () => {
  console.log(`EmployScope API on http://localhost:${port}`);
  // Make sure the storage bucket exists (no-op if it already does).
  const { error } = await supabase.storage.createBucket(BUCKET, { public: false });
  if (error && !/already exists/i.test(error.message)) console.warn('Bucket check:', error.message);
});
