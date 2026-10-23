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


// ============================================================
// PROFILE (Pre Saved Information) - paste into server.js
// Place this whole block ABOVE the "Route not found" 404 handler.
// ============================================================

// Adjust these two paths to wherever auth.js and upload.js really live
// (auth.js requires '../config/supabase', so it sits one folder below src).
const { requireUser } = require('./middleware/auth');
const { uploadTemplate: uploadPhoto } = require('./middleware/upload'); // single 'file', images only, 5MB

const MIME_BY_EXT = { png: 'image/png', jpg: 'image/jpeg', webp: 'image/webp' };

// ---------- sanitizers ----------
const str = (v, max) => (typeof v === 'string' ? v.trim().slice(0, max) : '');

const cleanTexts = (arr) =>
  arr.map((x) => str(x, 2000)).filter(Boolean).slice(0, 50);

const cleanContacts = (arr) =>
  arr
    .map((c) => ({ label: str(c?.label, 60), value: str(c?.value, 300) }))
    .filter((c) => c.value)
    .slice(0, 30);

const cleanEducation = (arr) =>
  arr
    .map((e) => ({
      degree: str(e?.degree, 200),
      institution: str(e?.institution, 200),
      start: str(e?.start, 30),
      end: str(e?.end, 30),
      gpa: str(e?.gpa, 20),
    }))
    .filter((e) => Object.values(e).some(Boolean))
    .slice(0, 20);

const cleanSkills = (arr) => {
  const seen = new Set();
  const out = [];
  for (const s of arr) {
    const name = str(s, 80);
    const key = name.toLowerCase();
    if (name && !seen.has(key)) {
      seen.add(key);
      out.push(name);
    }
  }
  return out.slice(0, 100);
};

const LIST_FIELDS = {
  contacts: cleanContacts,
  education: cleanEducation,
  experiences: cleanTexts,
  participations: cleanTexts,
};

async function signedPhoto(path) {
  if (!path) return null;
  const { data } = await supabase.storage.from(BUCKET).createSignedUrl(path, 3600);
  return data?.signedUrl || null;
}

// ---------- GET /api/profile ----------
app.get('/api/profile', requireUser, async (req, res, next) => {
  try {
    const [infoRes, skillsRes] = await Promise.all([
      supabase.from('UserInfo').select('*').eq('id', req.userId).maybeSingle(),
      supabase
        .from('UserSkill')
        .select('skillname')
        .eq('userid', req.userId)
        .eq('source', 'manual')
        .order('id'),
    ]);
    if (infoRes.error) return next(infoRes.error);
    if (skillsRes.error) return next(skillsRes.error);

    const info = infoRes.data || {};

    // No name yet: take the one given at signup (stored as auth metadata).
    let name = info.name || '';
    if (!name) {
      const token = (req.header('authorization') || '').slice(7).trim();
      const { data } = await supabase.auth.getUser(token);
      name = str(data?.user?.user_metadata?.name, 200);
      if (name) {
        await supabase.from('UserInfo').upsert({ id: req.userId, name }, { onConflict: 'id' });
      }
    }

    res.json({
      name,
      email: req.user.email,
      bio: info.bio || '',
      address: info.address || '',
      photoUrl: await signedPhoto(info.photourl),
      contacts: info.contacts || [],
      education: info.education || [],
      experiences: info.experiences || [],
      participations: info.participations || [],
      skills: skillsRes.data.map((r) => r.skillname),
    });
  } catch (err) {
    next(err);
  }
});

// ---------- PUT /api/profile ----------
// Only fields present in the body are changed.
app.put('/api/profile', requireUser, async (req, res, next) => {
  try {
    const b = req.body || {};
    const update = {};

    if ('bio' in b) update.bio = str(b.bio, 2000);
    if ('address' in b) update.address = str(b.address, 500);

    for (const [key, clean] of Object.entries(LIST_FIELDS)) {
      if (key in b) {
        if (!Array.isArray(b[key])) {
          return res.status(400).json({ error: `${key} must be a list` });
        }
        update[key] = clean(b[key]);
      }
    }

    let skills = null;
    if ('skills' in b) {
      if (!Array.isArray(b.skills)) {
        return res.status(400).json({ error: 'skills must be a list' });
      }
      skills = cleanSkills(b.skills);
    }

    if (b.removePhoto === true) {
      const { data: cur } = await supabase
        .from('UserInfo').select('photourl').eq('id', req.userId).maybeSingle();
      if (cur?.photourl) await supabase.storage.from(BUCKET).remove([cur.photourl]);
      update.photourl = null;
    }

    const { error: upErr } = await supabase
      .from('UserInfo')
      .upsert({ id: req.userId, ...update }, { onConflict: 'id' });
    if (upErr) return next(upErr);

    // Skills: insert the new manual rows first, then delete the old ones,
    // so a failed insert never wipes the user's existing skills.
    if (skills) {
      const { data: old, error: oldErr } = await supabase
        .from('UserSkill')
        .select('id')
        .eq('userid', req.userId)
        .eq('source', 'manual');
      if (oldErr) return next(oldErr);

      if (skills.length) {
        const { error: insErr } = await supabase
          .from('UserSkill')
          .insert(skills.map((skillname) => ({ userid: req.userId, skillname, source: 'manual' })));
        if (insErr) return next(insErr);
      }

      const oldIds = old.map((r) => r.id);
      if (oldIds.length) {
        const { error: delErr } = await supabase.from('UserSkill').delete().in('id', oldIds);
        if (delErr) return next(delErr);
      }
    }

    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ---------- POST /api/profile/photo ----------
// multipart, field name: "file". Image only (png/jpg/webp), 5MB.
app.post('/api/profile/photo', requireUser, uploadPhoto, async (req, res, next) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No photo uploaded' });

    let ext = (req.file.originalname.split('.').pop() || '').toLowerCase();
    if (ext === 'jpeg') ext = 'jpg';
    const contentType = MIME_BY_EXT[ext];
    if (!contentType) return res.status(400).json({ error: 'Only PNG, JPG or WEBP images are allowed.' });

    const path = `profile/${req.userId}/avatar.${ext}`;

    const { data: cur } = await supabase
      .from('UserInfo').select('photourl').eq('id', req.userId).maybeSingle();

    const { error: upErr } = await supabase.storage
      .from(BUCKET)
      .upload(path, req.file.buffer, { contentType, upsert: true });
    if (upErr) return next(upErr);

    // If the old photo had a different extension, remove it.
    if (cur?.photourl && cur.photourl !== path) {
      await supabase.storage.from(BUCKET).remove([cur.photourl]);
    }

    const { error: dbErr } = await supabase
      .from('UserInfo')
      .upsert({ id: req.userId, photourl: path }, { onConflict: 'id' });
    if (dbErr) return next(dbErr);

    res.json({ photoUrl: await signedPhoto(path) });
  } catch (err) {
    next(err);
  }
});

app.use((_req, res) => res.status(404).json({ error: 'Route not found' }));

// Central error handler (multer errors, thrown errors, etc.)


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
