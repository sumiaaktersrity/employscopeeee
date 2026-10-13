const router = require('express').Router();
const { requireUser } = require('../middleware/auth');
const { uploadCv } = require('../middleware/upload');
const cvSvc = require('../services/cvService');

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
router.use(requireUser);

// POST /api/cv/upload   (multipart, field "file")  -> stores + parses CV
router.post('/upload', uploadCv, wrap(async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file uploaded (field name must be "file").' });
  const { cv, parsed } = await cvSvc.uploadAndParse(req.userId, req.file);
  res.status(201).json({
    cv,
    parsed: { skills: parsed.skills, education: parsed.education, experience: parsed.experience },
  });
}));

// GET /api/cv/latest  -> latest CV + saved analysis (if any) + fresh matched jobs
router.get('/latest', wrap(async (req, res) => {
  const cv = await cvSvc.getCv(req.userId);
  if (!cv) return res.json({ cv: null });
  const saved = await cvSvc.savedResult(cv);
  res.json({ cv: cvSvc.publicCv(cv), ...(saved || {}) });
}));

// POST /api/cv/:id/analyze  -> analysis + matched jobs (saved)
router.post('/:id/analyze', wrap(async (req, res) => {
  const cv = await cvSvc.getCv(req.userId, req.params.id);
  if (!cv) return res.status(404).json({ error: 'CV not found' });
  res.json({ cv: cvSvc.publicCv(cv), ...(await cvSvc.analyzeCv(cv)) });
}));

// GET /api/cv/:id/analysis -> last saved analysis
router.get('/:id/analysis', wrap(async (req, res) => {
  const cv = await cvSvc.getCv(req.userId, req.params.id);
  if (!cv) return res.status(404).json({ error: 'CV not found' });
  const saved = await cvSvc.savedResult(cv);
  if (!saved) return res.status(404).json({ error: 'Not analyzed yet' });
  res.json(saved);
}));

module.exports = router;
