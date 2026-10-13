const { canonical } = require('./skillsDictionary');

/** DB row (JobPost + embedded JobSkill[]) -> API shape. */
function formatJob(row) {
  return {
    id: row.id,
    title: row.title,
    company: row.company,
    location: row.location || '',
    description: row.description || '',
    isActive: row.isActive,
    postedBy: row.postedBy,
    createdAt: row.created_at,
    skills: (row.JobSkill || []).map((s) => ({
      name: canonical(s.skillname),
      required: s.isRequired,
    })),
  };
}

/**
 * Score every job against the CV's skills.
 * Required skills weigh 2, optional 1. Jobs with 0% are dropped.
 */
function rankJobs(cvSkills, jobs, limit = 20) {
  const have = new Set(cvSkills.map((s) => s.toLowerCase()));
  return jobs
    .map((job) => {
      const total = job.skills.reduce((s, k) => s + (k.required ? 2 : 1), 0);
      if (!total) return null;
      const matched = job.skills.filter((k) => have.has(k.name.toLowerCase()));
      const got = matched.reduce((s, k) => s + (k.required ? 2 : 1), 0);
      return {
        ...job,
        matchPercent: Math.round((got / total) * 100),
        matchedSkills: matched.map((k) => k.name),
        missingSkills: job.skills.filter((k) => !have.has(k.name.toLowerCase())).map((k) => k.name),
      };
    })
    .filter((j) => j && j.matchPercent > 0)
    .sort((a, b) => b.matchPercent - a.matchPercent)
    .slice(0, limit);
}

module.exports = { formatJob, rankJobs };
