const router = require('express').Router();
const { requireUser, requireRole } = require('../middleware/auth');
const jobs = require('../services/jobService');
const cvSvc = require('../services/cvService');

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
router.use(requireUser);

// GET /api/jobs?q=&location=          -> all active jobs
router.get('/', wrap(async (req, res) => {
  res.json({ jobs: await jobs.listJobs({ q: req.query.q, location: req.query.location }) });
}));

// GET /api/jobs/matched?cvId=          -> jobs ranked by match with the CV (defaults to latest CV)
router.get('/matched', wrap(async (req, res) => {
  const cv = await cvSvc.getCv(req.userId, req.query.cvId);
  if (!cv) return res.status(404).json({ error: 'No CV found. Upload one first.' });
  res.json({ cvId: cv.id, jobs: await cvSvc.matchedJobsFor(cv) });
}));

router.get('/:id', wrap(async (req, res) => {
  const job = await jobs.getJob(req.params.id);
  if (!job) return res.status(404).json({ error: 'Job not found' });
  res.json({ job });
}));

// POST/PUT/DELETE: employers and admins only
router.post('/', requireRole('admin', 'employer'), wrap(async (req, res) => {
  const { title, company } = req.body;
  if (!title || !company) return res.status(400).json({ error: 'title and company are required' });
  res.status(201).json({ job: await jobs.createJob(req.userId, req.body) });
}));

async function ownerOrAdmin(req, res, next) {
  try {
    const job = await jobs.getJob(req.params.id);
    if (!job) return res.status(404).json({ error: 'Job not found' });
    if (req.userRole !== 'admin' && job.postedBy !== req.userId)
      return res.status(403).json({ error: 'You can only modify your own job posts' });
    next();
  } catch (e) { next(e); }
}

router.put('/:id', requireRole('admin', 'employer'), ownerOrAdmin, wrap(async (req, res) => {
  res.json({ job: await jobs.updateJob(req.params.id, req.body) });
}));

router.delete('/:id', requireRole('admin', 'employer'), ownerOrAdmin, wrap(async (req, res) => {
  await jobs.deleteJob(req.params.id);
  res.json({ deleted: true });
}));

module.exports = router;
