/**
 * Analyze parsed CV data against the current job market (all active job posts).
 *  - matchedSkills : CV skills that jobs ask for (fallback: top CV skills)
 *  - missingSkills : most-demanded REQUIRED skills the CV lacks
 *  - suggestedSkills: nice-to-have (optional) skills the CV lacks
 *  - score         : demand-weighted skill coverage, 0-100
 */
function analyze(parsed, jobs) {
  const have = new Set(parsed.skills.map((s) => s.toLowerCase()));
  const reqDemand = new Map();
  const optDemand = new Map();
  for (const job of jobs) {
    for (const k of job.skills) {
      const m = k.required ? reqDemand : optDemand;
      m.set(k.name, (m.get(k.name) || 0) + 1);
    }
  }
  const byDemand = (m) => [...m.entries()].sort((a, b) => b[1] - a[1]).map(([n]) => n);

  const demanded = new Set([...reqDemand.keys(), ...optDemand.keys()]);
  let matchedSkills = parsed.skills.filter((s) => demanded.has(s));
  if (!matchedSkills.length) matchedSkills = parsed.skills.slice(0, 6);

  const missingSkills = byDemand(reqDemand).filter((n) => !have.has(n.toLowerCase())).slice(0, 5);
  const suggestedSkills = byDemand(optDemand)
    .filter((n) => !have.has(n.toLowerCase()) && !missingSkills.includes(n))
    .slice(0, 3);

  // Score
  let score;
  const totalWeight = [...reqDemand.values()].reduce((a, b) => a + b * 2, 0) +
                      [...optDemand.values()].reduce((a, b) => a + b, 0);
  if (totalWeight > 0) {
    let got = 0;
    for (const [n, c] of reqDemand) if (have.has(n.toLowerCase())) got += c * 2;
    for (const [n, c] of optDemand) if (have.has(n.toLowerCase())) got += c;
    score = Math.round((got / totalWeight) * 100);
  } else {
    score = Math.min(100, parsed.skills.length * 8); // no jobs yet: fall back to skill count
  }

  // Suggestions (plain-language tips shown in the Flutter card)
  const suggestions = [];
  if (missingSkills.length)
    suggestions.push(`Employers most often ask for ${missingSkills.slice(0, 3).join(', ')} — add them if you have any experience.`);
  if (!parsed.hasMetrics)
    suggestions.push('Add measurable outcomes to your roles (e.g. "reduced load time by 30%").');
  if (parsed.experience.totalYears < 1)
    suggestions.push('Highlight internships, projects or freelance work to show hands-on experience.');
  if (parsed.skills.length < 5)
    suggestions.push('Add a clear Skills section listing your tools and technologies.');
  if (!parsed.hasSummary)
    suggestions.push('Start with a 2–3 line professional summary tailored to your target role.');
  if (!parsed.education.length)
    suggestions.push('Include an Education section with degree, institution and year.');
  if (suggestedSkills.length)
    suggestions.push(`Nice to have: ${suggestedSkills.join(', ')}.`);

  return {
    score,
    matchedSkills,
    missingSkills,
    suggestedSkills,
    suggestions: suggestions.slice(0, 5),
    totalYears: parsed.experience.totalYears,
  };
}

/* ---- Week 11: skill gap for ONE targeted job ---- */

/** Compare the CV's skills with a job's required / optional skills. */
function skillGap(cvSkills, job) {
  const have = new Set(cvSkills.map((s) => s.toLowerCase()));
  const matchedSkills = [];
  const missingRequired = [];
  const missingOptional = [];
  let total = 0;
  let got = 0;
  for (const k of job.skills) {
    const w = k.required ? 2 : 1; // same weighting as rankJobs()
    total += w;
    if (have.has(k.name.toLowerCase())) {
      got += w;
      matchedSkills.push(k.name);
    } else {
      (k.required ? missingRequired : missingOptional).push(k.name);
    }
  }
  return {
    matchPercent: total ? Math.round((got / total) * 100) : 0,
    totalSkills: job.skills.length,
    matchedSkills,
    missingRequired,
    missingOptional,
  };
}

const fallbackTip = (skill) =>
  `Start with the official ${skill} documentation, then build a small project that uses it.`;

/**
 * Short "how to start learning it" tips for the missing skills.
 * Uses Gemini when configured; always falls back to a generic tip so the
 * feature still works if the AI is missing, rate-limited or returns junk.
 * @param missing [{ skill, required }]
 */
async function recommendSkills(job, missing) {
  const list = missing.slice(0, 6);
  if (!list.length) return { aiGenerated: false, recommendations: [] };
  const generic = () => ({
    aiGenerated: false,
    recommendations: list.map((m) => ({ ...m, tip: fallbackTip(m.skill) })),
  });

  const { GEMINI_API_KEY, GEMINI_MODEL } = process.env;
  if (!GEMINI_API_KEY || !GEMINI_MODEL) return generic();

  try {
    const prompt =
      'You are a career coach. A job seeker is targeting the role "' + job.title + '" and lacks these skills: ' +
      JSON.stringify(list.map((m) => m.skill)) + '. ' +
      'For EACH skill give one practical tip (max 25 words) on how a beginner can start learning it. ' +
      'Do not include links or URLs. Respond ONLY with JSON: {"recommendations":[{"skill":"...","tip":"..."}]}';
    const resp = await fetch(
      'https://generativelanguage.googleapis.com/v1beta/models/' + GEMINI_MODEL + ':generateContent',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': GEMINI_API_KEY },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { responseMimeType: 'application/json', temperature: 0.3 },
        }),
        signal: AbortSignal.timeout(30000),
      }
    );
    if (!resp.ok) throw new Error('Gemini HTTP ' + resp.status);
    const data = await resp.json();
    const raw = (data?.candidates?.[0]?.content?.parts || []).map((p) => p.text || '').join('');
    const obj = JSON.parse(raw.replace(/```json|```/gi, '').trim());
    const arr = Array.isArray(obj) ? obj : obj.recommendations;
    const tips = new Map(
      (Array.isArray(arr) ? arr : []).map((r) => [String(r?.skill || '').toLowerCase(), String(r?.tip || '').trim().slice(0, 220)])
    );
    const recommendations = list.map((m) => ({ ...m, tip: tips.get(m.skill.toLowerCase()) || fallbackTip(m.skill) }));
    return { aiGenerated: list.some((m) => tips.get(m.skill.toLowerCase())), recommendations };
  } catch (e) {
    console.error('Skill recommendation failed:', e.message);
    return generic();
  }
}

module.exports = { analyze, skillGap, recommendSkills };
