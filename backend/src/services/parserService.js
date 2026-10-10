const mammoth = require('mammoth');
const pdfParse = require('pdf-parse/lib/pdf-parse.js'); // direct path avoids pdf-parse's debug-mode quirk
const { findSkills } = require('./skillsDictionary');

/* ---------- 1. Text extraction ---------- */
async function extractText(buffer, ext) {
  if (ext === '.pdf') {
    const { text } = await pdfParse(buffer);
    return normalize(text);
  }
  if (ext === '.docx') {
    const { value } = await mammoth.extractRawText({ buffer });
    return normalize(value);
  }
  throw Object.assign(new Error('Unsupported file type'), { status: 400 });
}

const normalize = (t) =>
  (t || '').replace(/\r/g, '').replace(/[ \t]+/g, ' ').replace(/\n{3,}/g, '\n\n').trim();

/* ---------- 2. Section splitting ---------- */
const HEADINGS = {
  summary: /^(professional )?(summary|profile|objective|about( me)?)$/i,
  skills: /^(((technical|key|core) )?skills( & tools| and tools)?|technologies|tech stack)$/i,
  education: /^(education|academic( background| qualifications)?|qualifications)$/i,
  experience: /^((work|professional|employment|internship) )?(experience|history)( & internships)?$/i,
  projects: /^(projects|personal projects|academic projects)$/i,
};

function splitSections(lines) {
  const sections = { header: [], summary: [], skills: [], education: [], experience: [], projects: [], other: [] };
  let current = 'header';
  for (const raw of lines) {
    const line = raw.trim().replace(/[:\-–—]+$/, '').trim();
    if (line && line.length < 40) {
      const hit = Object.keys(HEADINGS).find((k) => HEADINGS[k].test(line));
      if (hit) { current = hit; continue; }
    }
    sections[current].push(raw.trim());
  }
  return sections;
}

/* ---------- 3. Education ---------- */
const DEGREE = /\b(bachelor|b\.?\s?sc|b\.?\s?tech|b\.?\s?e\b|bba|master|m\.?\s?sc|mba|m\.?\s?tech|ph\.?d|doctorate|diploma|associate degree|hsc|ssc|a[- ]levels?|o[- ]levels?)\b/i;
const INSTITUTION = /(university|college|institute|school|academy|polytechnic)/i;

function parseEducation(sec, all) {
  const lines = (sec.length ? sec : all).filter(Boolean);
  const out = [];
  lines.forEach((line, i) => {
    if (!DEGREE.test(line)) return;
    const near = [lines[i - 1], line, lines[i + 1]].filter(Boolean);
    const inst = near.find((l) => INSTITUTION.test(l));
    const years = near.join(' ').match(/(19|20)\d{2}/g);
    out.push({
      degree: line.slice(0, 160),
      institution: inst ? inst.slice(0, 160) : null,
      year: years ? Number(years[years.length - 1]) : null,
    });
  });
  const seen = new Set();
  return out.filter((e) => (seen.has(e.degree) ? false : seen.add(e.degree))).slice(0, 6);
}

/* ---------- 4. Experience ---------- */
const MONTHS = { jan: 0, feb: 1, mar: 2, apr: 3, may: 4, jun: 5, jul: 6, aug: 7, sep: 8, oct: 9, nov: 10, dec: 11 };
const M = '(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\\.?';
const RANGE = new RegExp(
  `((?:${M}\\s+)?(?:19|20)\\d{2})\\s*(?:-|–|—|to)\\s*((?:${M}\\s+)?(?:19|20)\\d{2}|present|current|now|ongoing)`,
  'i'
);

function toMonths(s) {
  if (/present|current|now|ongoing/i.test(s)) {
    const d = new Date();
    return d.getFullYear() * 12 + d.getMonth();
  }
  const y = Number(s.match(/(?:19|20)\d{2}/)[0]);
  const m = s.match(new RegExp(M, 'i'));
  return y * 12 + (m ? MONTHS[m[0].slice(0, 3).toLowerCase()] : 0);
}

function parseExperience(sec, all) {
  const lines = (sec.length ? sec : all).filter(Boolean);
  const entries = [];
  lines.forEach((line, i) => {
    const m = line.match(RANGE);
    if (!m) return;
    const months = Math.max(0, toMonths(m[2]) - toMonths(m[1]));
    if (months > 12 * 45) return; // ignore junk like "1980 - 2030"
    let title = line.replace(RANGE, '').replace(/[|,\-–—()]+\s*$/g, '').trim();
    if (title.length < 3) title = (lines[i - 1] || '').trim();
    entries.push({
      title: title.slice(0, 160) || 'Role',
      period: m[0],
      years: Math.round((months / 12) * 10) / 10,
    });
  });
  let total = entries.reduce((s, e) => s + e.years, 0);
  if (!entries.length) {
    const f = all.join(' ').match(/(\d{1,2})\+?\s*(?:years?|yrs?)\s+of\s+(?:\w+\s+){0,3}experience/i);
    if (f) total = Number(f[1]);
  }
  return { entries: entries.slice(0, 10), totalYears: Math.round(total * 10) / 10 };
}

/* ---------- 5. Main ---------- */
function parseCV(text) {
  const lines = text.split('\n');
  const sections = splitSections(lines);
  const skills = findSkills(text);
  return {
    skills,
    education: parseEducation(sections.education, lines),
    experience: parseExperience(sections.experience, lines),
    hasSummary: sections.summary.length > 0,
    hasMetrics: /\b\d+\s?%|\b\d+\s?\+?\s?(users|clients|customers|projects|downloads)\b|\$\s?\d+/i.test(text),
    wordCount: text.split(/\s+/).length,
  };
}

module.exports = { extractText, parseCV };
