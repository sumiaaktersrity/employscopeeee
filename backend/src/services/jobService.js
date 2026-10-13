const { supabase } = require('../config/supabase');
const { canonical } = require('./skillsDictionary');
const { formatJob } = require('./matchingService');

const SELECT = '*, JobSkill(*)';

/** Accepts ["Flutter", ...] or [{name:"Flutter", required:false}, ...]. */
function normalizeSkills(skills) {
  const seen = new Set();
  return (Array.isArray(skills) ? skills : [])
    .map((s) => (typeof s === 'string' ? { name: s, required: true } : { name: s?.name, required: s?.required !== false }))
    .map((s) => ({ name: canonical(s.name), required: s.required }))
    .filter((s) => s.name && !seen.has(s.name.toLowerCase()) && seen.add(s.name.toLowerCase()));
}

async function listJobs({ q, location, includeInactive = false } = {}) {
  let query = supabase.from('JobPost').select(SELECT).order('created_at', { ascending: false });
  if (!includeInactive) query = query.eq('isActive', true);
  if (q) query = query.or(`title.ilike.%${q.replace(/[,%()]/g, ' ')}%,company.ilike.%${q.replace(/[,%()]/g, ' ')}%`);
  if (location) query = query.ilike('location', `%${location.replace(/[,%()]/g, ' ')}%`);
  const { data, error } = await query;
  if (error) throw error;
  return data.map(formatJob);
}

async function getJob(id) {
  const { data, error } = await supabase.from('JobPost').select(SELECT).eq('id', id).maybeSingle();
  if (error) throw error;
  return data ? formatJob(data) : null;
}

async function replaceSkills(jobId, skills) {
  const { error: delErr } = await supabase.from('JobSkill').delete().eq('jobId', jobId);
  if (delErr) throw delErr;
  const rows = normalizeSkills(skills).map((s) => ({ jobId, skillname: s.name, isRequired: s.required }));
  if (rows.length) {
    const { error } = await supabase.from('JobSkill').insert(rows);
    if (error) throw error;
  }
}

async function createJob(userId, body) {
  const { data, error } = await supabase.from('JobPost')
    .insert({ title: body.title, company: body.company, location: body.location || null,
              description: body.description || null, postedBy: userId })
    .select('id').single();
  if (error) throw error;
  await replaceSkills(data.id, body.skills);
  return getJob(data.id);
}

async function updateJob(id, body) {
  const patch = {};
  for (const k of ['title', 'company', 'location', 'description', 'isActive'])
    if (body[k] !== undefined) patch[k] = body[k];
  if (Object.keys(patch).length) {
    const { error } = await supabase.from('JobPost').update(patch).eq('id', id);
    if (error) throw error;
  }
  if (body.skills !== undefined) await replaceSkills(id, body.skills);
  return getJob(id);
}

async function deleteJob(id) {
  const { error } = await supabase.from('JobPost').delete().eq('id', id); // JobSkill cascades
  if (error) throw error;
}

module.exports = { listJobs, getJob, createJob, updateJob, deleteJob };
