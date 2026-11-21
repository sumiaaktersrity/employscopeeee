/**
 * joboperation.js — ALL CV + job endpoints and their logic in ONE file.
 * Replaces: routes/cv.routes.js, routes/jobs.routes.js,
 *           services/cvService.js, services/jobService.js
 *
 * server.js mounts it like this:
 *   const ops = require('./routes/joboperation');
 *   app.use('/api/cv', ops.cv);
 *   app.use('/api/jobs', ops.jobs);
 *
 * Job flow:
 *   POST /api/cv/upload            -> parse + store the CV
 *   POST /api/cv/:id/analyze       -> JSearch is called with the CV's skills, ONLY jobs that
 *                                     match those skills are saved to JobPost/JobSkill,
 *                                     then everything is read back from the DB and ranked
 *   GET  /api/jobs, /matched, ...  -> read the DB only (active jobs), never the external API
 *   POST /api/jobs/:id/report      -> a user reports a job (JobReport row, status Pending)
 */
const path = require('path');
const express = require('express');
const { supabase, BUCKET } = require('../config/supabase');
const { requireUser } = require('../middleware/auth');
const { uploadCv } = require('../middleware/upload');
const { extractText, parseCV } = require('../services/parserService');
const { analyze, skillGap, recommendSkills } = require('../services/analysisService');
const { formatJob, rankJobs } = require('../services/matchingService');
const { findSkills } = require('../services/skillsDictionary');

const cvRouter = express.Router();
const jobsRouter = express.Router();
cvRouter.use(requireUser);
jobsRouter.use(requireUser);

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
const SELECT = '*, JobSkill(*)';
const fmt = (row) => ({ ...formatJob(row), url: row.url || null, source: row.source || null });
const idParam = (req) => {
  const n = Number(req.params.id);
  return Number.isInteger(n) && n > 0 ? n : null;
};
const clean = (s) => String(s).replace(/[,%()]/g, ' ');

/* ================================================================== *
 * Shared helpers (used by more than one endpoint)                     *
 * ================================================================== */

const publicCv = (r) => ({
  id: r.id,
  fileName: r.fileName,
  fileType: r.fileType,
  uploadedAt: r.uploaded_at,
});

/** A specific CV (must belong to the user) or the user's latest. */
async function getCv(userId, cvId) {
  let q = supabase.from('CV').select('*').eq('userId', userId);
  q = cvId ? q.eq('id', cvId) : q.order('uploaded_at', { ascending: false }).limit(1);
  const { data, error } = await q;
  if (error) throw error;
  return data?.[0] || null;
}

/** Active jobs only, straight from the DB. Everything the app shows goes through here. */
async function listJobs({ q, location } = {}) {
  let query = supabase.from('JobPost').select(SELECT)
    .eq('isActive', true).order('created_at', { ascending: false });
  if (q) query = query.or(`title.ilike.%${clean(q)}%,company.ilike.%${clean(q)}%`);
  if (location) query = query.ilike('location', `%${clean(location)}%`);
  const { data, error } = await query;
  if (error) throw error;
  return data.map(fmt);
}

async function matchedJobsFor(cv) {
  return rankJobs(cv.parsed?.skills || [], await listJobs());
}

/** Saved analysis (if any) for a CV, in the same shape the analyze endpoint returns. */
async function savedResult(cv) {
  const { data, error } = await supabase.from('CVAnalysis').select('*').eq('cvId', cv.id).maybeSingle();
  if (error) throw error;
  if (!data) return null;
  return {
    analysis: {
      score: data.score, matchedSkills: data.matchedSkills, missingSkills: data.missingSkills,
      suggestedSkills: data.suggestedSkills, suggestions: data.suggestions, totalYears: Number(data.totalYears),
      education: cv.parsed?.education || [], experience: cv.parsed?.experience?.entries || [],
      skills: cv.parsed?.skills || [],
    },
    matchedJobs: await matchedJobsFor(cv),
  };
}

/* ---------------- external jobs (JSearch) ---------------- */

const JSEARCH_HOST = 'jsearch.p.rapidapi.com';
const CACHE_MS = 24 * 60 * 60 * 1000;
const fetchedAt = new Map(); // "query|country" -> timestamp (in memory; resets on restart)

/** Search JSearch and normalize results. Returns [] when no API key is configured. */
async function fetchExternalJobs(query) {
  const key = process.env.JSEARCH_API_KEY;
  if (!key) return [];
  const country = (process.env.JOB_FETCH_COUNTRY || 'us').toLowerCase();
 const url = `https://${JSEARCH_HOST}/search-v2?` +
    new URLSearchParams({ query, page: '1', num_pages: '1', country });
  const resp = await fetch(url, {
    headers: { 'X-RapidAPI-Key': key, 'X-RapidAPI-Host': JSEARCH_HOST },
    signal: AbortSignal.timeout(10000),
  });
  if (!resp.ok) throw new Error(`JSearch responded ${resp.status}`);
  const body = await resp.json();
 const list = Array.isArray(body.data) ? body.data : (body.data?.jobs || []);
return list.map((j) => ({
  source: 'jsearch',
  externalId: j.job_id,
  title: j.job_title,
  company: j.employer_name,
  location: j.job_location || [j.job_city, j.job_state, j.job_country].filter(Boolean).join(', ') || null,
  description: j.job_description || null,
  url: j.job_apply_link || j.job_google_link || null,
}));
}

/**
 * Save ONLY the jobs that match this CV (at least one CV skill appears in the job text).
 * Already-saved jobs (same source + externalId) are skipped, so a job an admin
 * deactivated is never re-added or re-activated.
 */
async function importJobs(found, cvSkills) {
  const have = new Set(cvSkills.map((s) => s.toLowerCase()));
  const seen = new Set();
  const rows = [];
  const skillsByExt = new Map();
  for (const j of found) {
    if (!j.externalId || !j.title || !j.company || seen.has(j.externalId)) continue;
    seen.add(j.externalId);
    const all = findSkills(`${j.title} ${j.description || ''}`);
    if (!all.some((s) => have.has(s.toLowerCase()))) continue; // not a match for this CV -> not stored
    // keep the CV-matching skills first, cap at 15
    const skills = [
      ...all.filter((s) => have.has(s.toLowerCase())),
      ...all.filter((s) => !have.has(s.toLowerCase())),
    ].slice(0, 15);
    skillsByExt.set(j.externalId, skills);
    rows.push({
      title: j.title, company: j.company, location: j.location,
      description: j.description, source: j.source, externalId: j.externalId, url: j.url,
    });
  }
  if (!rows.length) return 0;

  // ignoreDuplicates => ON CONFLICT DO NOTHING; only newly inserted rows come back
  const { data: inserted, error } = await supabase.from('JobPost')
    .upsert(rows, { onConflict: 'source,externalId', ignoreDuplicates: true })
    .select('id, externalId');
  if (error) throw error;

  const skillRows = (inserted || []).flatMap((r) =>
    (skillsByExt.get(r.externalId) || []).map((name) => ({ jobId: r.id, skillname: name, isRequired: true })));
  if (skillRows.length) {
    const { error: sErr } = await supabase.from('JobSkill').insert(skillRows);
    if (sErr) throw sErr;
  }
  return (inserted || []).length;
}

/**
 * Fetch from JSearch for this CV and save the matches. Never throws: if the API
 * fails or the quota is used up, analysis still runs on the jobs already in the DB.
 */
async function refreshJobsFor(cvSkills) {
  try {
    if (!process.env.JSEARCH_API_KEY || !cvSkills?.length) return 0;
    const query = `${cvSkills.slice(0, 3).join(' ')} jobs`;
    const cacheKey = `${query}|${process.env.JOB_FETCH_COUNTRY || 'us'}`;
    const last = fetchedAt.get(cacheKey);
    if (last && Date.now() - last < CACHE_MS) return 0;
    const found = await fetchExternalJobs(query);
    fetchedAt.set(cacheKey, Date.now()); // only after a successful call
    return await importJobs(found, cvSkills);
  } catch (e) {
    console.error('refreshJobsFor failed:', e.message || e);
    return 0;
  }
}

/* ================================================================== *
 * /api/cv                                                             *
 * ================================================================== */

// POST /api/cv/upload  (multipart, field "file") -> stores + parses the CV
cvRouter.post('/upload', uploadCv, wrap(async (req, res) => {
  const file = req.file;
  if (!file) return res.status(400).json({ error: 'No file uploaded (field name must be "file").' });

  const ext = path.extname(file.originalname).toLowerCase();
  const text = await extractText(file.buffer, ext);
  if (text.length < 50)
    throw Object.assign(
      new Error('Could not read text from this file. If it is a scanned image, upload a text-based PDF or DOCX.'),
      { status: 422 }
    );

  const parsed = parseCV(text);
  const fileSafe = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
  const filePath = `${req.userId}/${Date.now()}_${fileSafe}`;

  const { error: upErr } = await supabase.storage.from(BUCKET).upload(filePath, file.buffer, {
    contentType: file.mimetype || 'application/octet-stream',
    upsert: false,
  });
  if (upErr) throw upErr;

  const { data: row, error } = await supabase.from('CV').insert({
    userId: req.userId, fileUrl: `${BUCKET}/${filePath}`, filePath, fileType: ext.slice(1),
    fileName: file.originalname, rawText: text, parsed,
  }).select().single();
  if (error) {
    await supabase.storage.from(BUCKET).remove([filePath]); // don't orphan the file
    throw error;
  }

  if (parsed.skills.length) {
    const { error: sErr } = await supabase.from('UserSkill').insert(
      parsed.skills.map((s) => ({ userid: req.userId, cvid: row.id, skillname: s, source: 'cv' }))
    );
    if (sErr) throw sErr;
  }
  res.status(201).json({
    cv: publicCv(row),
    parsed: { skills: parsed.skills, education: parsed.education, experience: parsed.experience },
  });
}));

// GET /api/cv/latest -> latest CV + saved analysis (if any) + matched jobs from the DB
cvRouter.get('/latest', wrap(async (req, res) => {
  const cv = await getCv(req.userId);
  if (!cv) return res.json({ cv: null });
  const saved = await savedResult(cv);
  res.json({ cv: publicCv(cv), ...(saved || {}) });
}));

// POST /api/cv/:id/analyze -> fetch + save matching external jobs, then analysis + matched jobs
cvRouter.post('/:id/analyze', wrap(async (req, res) => {
  const cv = await getCv(req.userId, req.params.id);
  if (!cv) return res.status(404).json({ error: 'CV not found' });
  const parsed = cv.parsed;

  await refreshJobsFor(parsed?.skills || []);   // external API -> DB (CV-matching jobs only)
  const jobs = await listJobs();                // from here on, DB only
  const analysis = analyze(parsed, jobs);

  const { error } = await supabase.from('CVAnalysis').upsert({
    cvId: cv.id, userId: cv.userId, score: analysis.score,
    matchedSkills: analysis.matchedSkills, missingSkills: analysis.missingSkills,
    suggestedSkills: analysis.suggestedSkills, suggestions: analysis.suggestions,
    totalYears: analysis.totalYears,
  }, { onConflict: 'cvId' });
  if (error) throw error;

  res.json({
    cv: publicCv(cv),
    analysis: { ...analysis, education: parsed.education, experience: parsed.experience.entries, skills: parsed.skills },
    matchedJobs: rankJobs(parsed.skills, jobs),
  });
}));

// GET /api/cv/:id/analysis -> last saved analysis
cvRouter.get('/:id/analysis', wrap(async (req, res) => {
  const cv = await getCv(req.userId, req.params.id);
  if (!cv) return res.status(404).json({ error: 'CV not found' });
  const saved = await savedResult(cv);
  if (!saved) return res.status(404).json({ error: 'Not analyzed yet' });
  res.json(saved);
}));

/* ================================================================== *
 * /api/jobs                                                           *
 * ================================================================== */

// GET /api/jobs?q=&location= -> active jobs from the DB
jobsRouter.get('/', wrap(async (req, res) => {
  res.json({ jobs: await listJobs({ q: req.query.q, location: req.query.location }) });
}));

// GET /api/jobs/matched?cvId= -> jobs ranked by match with the CV (defaults to latest CV)
jobsRouter.get('/matched', wrap(async (req, res) => {
  const cv = await getCv(req.userId, req.query.cvId);
  if (!cv) return res.status(404).json({ error: 'No CV found. Upload one first.' });
  res.json({ cvId: cv.id, jobs: await matchedJobsFor(cv) });
}));

// GET /api/jobs/saved -> the user's saved jobs (inactive ones hidden)
jobsRouter.get('/saved', wrap(async (req, res) => {
  const { data, error } = await supabase.from('SavedJob')
    .select('created_at, JobPost(*, JobSkill(*))')
    .eq('userId', req.userId)
    .order('created_at', { ascending: false });
  if (error) throw error;
  res.json({ jobs: data.filter((r) => r.JobPost && r.JobPost.isActive).map((r) => fmt(r.JobPost)) });
}));

// POST /api/jobs/:id/save
jobsRouter.post('/:id/save', wrap(async (req, res) => {
  const id = idParam(req);
  if (!id) return res.status(400).json({ error: 'Invalid job id' });
  const { data: job, error: jErr } = await supabase.from('JobPost')
    .select('id').eq('id', id).eq('isActive', true).maybeSingle();
  if (jErr) throw jErr;
  if (!job) return res.status(404).json({ error: 'Job not found' });
  const { error } = await supabase.from('SavedJob')
    .upsert({ userId: req.userId, jobId: id }, { onConflict: 'userId,jobId', ignoreDuplicates: true });
  if (error) throw error;
  res.status(201).json({ saved: true, jobId: id });
}));

// DELETE /api/jobs/:id/save
jobsRouter.delete('/:id/save', wrap(async (req, res) => {
  const id = idParam(req);
  if (!id) return res.status(400).json({ error: 'Invalid job id' });
  const { error } = await supabase.from('SavedJob')
    .delete().eq('userId', req.userId).eq('jobId', id);
  if (error) throw error;
  res.json({ saved: false, jobId: id });
}));

// POST /api/jobs/:id/report  body: { reason } -> one report per user per job
jobsRouter.post('/:id/report', wrap(async (req, res) => {
  const id = idParam(req);
  if (!id) return res.status(400).json({ error: 'Invalid job id' });
  const reason = String(req.body?.reason || '').trim().slice(0, 500);
  if (!reason) return res.status(400).json({ error: 'A reason is required' });
  const { data: job, error: jErr } = await supabase.from('JobPost')
    .select('id').eq('id', id).eq('isActive', true).maybeSingle();
  if (jErr) throw jErr;
  if (!job) return res.status(404).json({ error: 'Job not found' });
  const { error } = await supabase.from('JobReport')
    .insert({ jobId: id, reporterId: req.userId, reason });
  if (error) {
    if (error.code === '23505') return res.status(409).json({ error: 'You already reported this job' });
    throw error;
  }
  res.status(201).json({ reported: true, jobId: id });
}));

// GET /api/jobs/:id/skill-gap -> latest CV skills vs this job + learning tips
jobsRouter.get('/:id/skill-gap', wrap(async (req, res) => {
  const id = idParam(req);
  if (!id) return res.status(400).json({ error: 'Invalid job id' });
  const { data: row, error } = await supabase.from('JobPost')
    .select(SELECT).eq('id', id).eq('isActive', true).maybeSingle();
  if (error) throw error;
  if (!row) return res.status(404).json({ error: 'Job not found' });
  const job = fmt(row);
  const cv = await getCv(req.userId);
  if (!cv) return res.status(404).json({ error: 'No CV found. Upload your CV on the dashboard first.' });
  const gap = skillGap(cv.parsed?.skills || [], job);
  const missing = [
    ...gap.missingRequired.map((skill) => ({ skill, required: true })),
    ...gap.missingOptional.map((skill) => ({ skill, required: false })),
  ];
  const { aiGenerated, recommendations } = await recommendSkills(job, missing);
  res.json({ jobId: job.id, title: job.title, company: job.company, ...gap, recommendations, aiGenerated });
}));

// GET /api/jobs/:id -> one active job
jobsRouter.get('/:id', wrap(async (req, res) => {
  const id = idParam(req);
  if (!id) return res.status(400).json({ error: 'Invalid job id' });
  const { data, error } = await supabase.from('JobPost')
    .select(SELECT).eq('id', id).eq('isActive', true).maybeSingle();
  if (error) throw error;
  if (!data) return res.status(404).json({ error: 'Job not found' });
  res.json({ job: fmt(data) });
}));

module.exports = { cv: cvRouter, jobs: jobsRouter };