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

module.exports = { analyze };
