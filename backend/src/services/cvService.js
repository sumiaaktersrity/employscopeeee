const path = require('path');
const { supabase, BUCKET } = require('../config/supabase');
const { extractText, parseCV } = require('./parserService');
const { analyze } = require('./analysisService');
const { rankJobs } = require('./matchingService');
const jobSvc = require('./jobService');

const publicCv = (r) => ({
  id: r.id,
  fileName: r.fileName,
  fileType: r.fileType,
  uploadedAt: r.uploaded_at,
});

/** Store file in Supabase Storage, parse it, persist CV + skills. */
async function uploadAndParse(userId, file) {
  const ext = path.extname(file.originalname).toLowerCase();
  const text = await extractText(file.buffer, ext);
  if (text.length < 50)
    throw Object.assign(
      new Error('Could not read text from this file. If it is a scanned image, upload a text-based PDF or DOCX.'),
      { status: 422 }
    );

  const parsed = parseCV(text);
  const safe = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
  const filePath = `${userId}/${Date.now()}_${safe}`;

  const { error: upErr } = await supabase.storage.from(BUCKET).upload(filePath, file.buffer, {
    contentType: file.mimetype || 'application/octet-stream',
    upsert: false,
  });
  if (upErr) throw upErr;

  const { data: cv, error } = await supabase.from('CV').insert({
    userId, fileUrl: `${BUCKET}/${filePath}`, filePath, fileType: ext.slice(1),
    fileName: file.originalname, rawText: text, parsed,
  }).select().single();
  if (error) {
    await supabase.storage.from(BUCKET).remove([filePath]); // don't orphan the file
    throw error;
  }

  if (parsed.skills.length) {
    const { error: sErr } = await supabase.from('UserSkill').insert(
      parsed.skills.map((s) => ({ userid: userId, cvid: cv.id, skillname: s, source: 'cv' }))
    );
    if (sErr) throw sErr;
  }
  return { cv: publicCv(cv), parsed };
}

/** A specific CV (must belong to user) or the user's latest. */
async function getCv(userId, cvId) {
  let q = supabase.from('CV').select('*').eq('userId', userId);
  q = cvId ? q.eq('id', cvId) : q.order('uploaded_at', { ascending: false }).limit(1);
  const { data, error } = await q;
  if (error) throw error;
  return data?.[0] || null;
}

async function matchedJobsFor(cv) {
  const jobs = await jobSvc.listJobs();
  return rankJobs(cv.parsed?.skills || [], jobs);
}

/** Run analysis, save it, return analysis + matched jobs. */
async function analyzeCv(cv) {
  const jobs = await jobSvc.listJobs();
  const parsed = cv.parsed;
  const analysis = analyze(parsed, jobs);

  const { error } = await supabase.from('CVAnalysis').upsert({
    cvId: cv.id, userId: cv.userId, score: analysis.score,
    matchedSkills: analysis.matchedSkills, missingSkills: analysis.missingSkills,
    suggestedSkills: analysis.suggestedSkills, suggestions: analysis.suggestions,
    totalYears: analysis.totalYears,
  }, { onConflict: 'cvId' });
  if (error) throw error;

  return {
    analysis: { ...analysis, education: parsed.education, experience: parsed.experience.entries, skills: parsed.skills },
    matchedJobs: rankJobs(parsed.skills, jobs),
  };
}

/** Saved analysis (if any) for a CV, in the same shape as analyzeCv. */
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

module.exports = { uploadAndParse, getCv, analyzeCv, savedResult, matchedJobsFor, publicCv };
