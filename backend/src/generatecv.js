// generatecv.js  (put next to server.js, like createcv.js)
// POST /api/cvgen
// Body (JSON): { requirements: ["ticked requirement", ...], templateId: 12 }
// Returns: application/pdf bytes
//
// How it works (one Gemini call):
//  - Gemini LOOKS at the saved template image and returns a style (colors, font, header look)
//  - the same call picks the presaved skills / experiences / participations that fit the ticked requirements
//  - pdfkit draws the CV from that style + the profile data

require('dotenv').config();

const express = require('express');
const PDFDocument = require('pdfkit');
const { supabase } = require('./config/supabase');
const { requireUser } = require('./middleware/auth');

const router = express.Router();

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL;
const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

const httpError = (status, message) => Object.assign(new Error(message), { status });
const str = (v, max) => (typeof v === 'string' ? v.trim().slice(0, max) : '');

/* ---------------- profile (same data as GET /api/profile) ---------------- */
async function loadProfile(req) {
  const [infoRes, skillsRes] = await Promise.all([
    supabase.from('UserInfo').select('*').eq('id', req.userId).maybeSingle(),
    supabase.from('UserSkill').select('skillname').eq('userid', req.userId).eq('source', 'manual').order('id'),
  ]);
  if (infoRes.error) throw infoRes.error;
  if (skillsRes.error) throw skillsRes.error;
  const info = infoRes.data || {};

  let name = str(info.name, 200);
  if (!name) {
    const token = (req.header('authorization') || '').slice(7).trim();
    const { data } = await supabase.auth.getUser(token);
    name = str(data?.user?.user_metadata?.name, 200);
  }
  if (!name) throw httpError(400, 'Add your name in Pre Saved Information first.');

  const contacts = (info.contacts || []).filter((c) => c?.value);
  if (!contacts.some((c) => /email/i.test(c.label || ''))) {
    contacts.unshift({ label: 'Email', value: req.user.email });
  }

  return {
    name,
    contacts,
    address: str(info.address, 500),
    bio: str(info.bio, 2000),
    education: info.education || [],
    skills: skillsRes.data.map((r) => r.skillname),
    experiences: info.experiences || [],
    participations: info.participations || [],
  };
}

/* ---------------- template image ---------------- */
async function loadImage(url) {
  let r;
  try {
    r = await fetch(url, { signal: AbortSignal.timeout(15000) });
  } catch {
    throw httpError(422, "Couldn't load the template image.");
  }
  if (!r.ok) throw httpError(422, "Couldn't load the template image.");
  const buf = Buffer.from(await r.arrayBuffer());
  if (buf.length > MAX_IMAGE_BYTES) throw httpError(422, 'Template image is too large.');

  let mime = (r.headers.get('content-type') || '').split(';')[0];
  if (!/^image\/(png|jpeg|webp)$/.test(mime)) {
    const ext = url.split('?')[0].split('.').pop().toLowerCase();
    mime = ext === 'png' ? 'image/png' : ext === 'webp' ? 'image/webp' : 'image/jpeg';
  }
  return { mime, b64: buf.toString('base64') };
}

/* ---------------- Gemini ---------------- */
function buildPrompt(profile, requirements) {
  return `You build a CV for one target job from a candidate's saved profile.

Do two things.

1) STYLE: look at the attached CV template image and describe its look.
2) CONTENT: pick what best proves the ticked job requirements.

STRICT RULES
- Never invent facts, skills, employers, dates or numbers.
- "skills": strings copied EXACTLY from CANDIDATE SKILLS, most relevant first. Only relevant ones.
- "experiences" and "participations": choose by index from the lists, most relevant first.
  "text" may only tighten the wording of that same line (fix grammar, cut filler, lead with the
  relevant skills). It must keep every fact from the original line.
- At most 5 experiences and 3 participations.
- Colors are 6-digit hex like #1f3a5f. "font" is one of: Helvetica, Times-Roman, Courier.
- "headerStyle" is one of: banner (name on a colored band), centered, plain.
- "headingStyle" is one of: underline, bar, plain.

Reply with JSON only, exactly this shape:
{"style":{"font":"Helvetica","background":"#ffffff","text":"#222222","accent":"#1f3a5f","headerStyle":"banner","headingStyle":"underline"},
 "skills":["..."],
 "experiences":[{"index":0,"text":"..."}],
 "participations":[{"index":0,"text":"..."}]}

TICKED REQUIREMENTS:
${JSON.stringify(requirements)}

CANDIDATE SKILLS:
${JSON.stringify(profile.skills)}

CANDIDATE EXPERIENCES (index = position):
${JSON.stringify(profile.experiences.map((text, index) => ({ index, text })))}

CANDIDATE PARTICIPATIONS (index = position):
${JSON.stringify(profile.participations.map((text, index) => ({ index, text })))}`;
}

async function callGemini(prompt, img) {
  if (!GEMINI_API_KEY) throw httpError(500, 'Server is missing GEMINI_API_KEY');
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;
  const body = {
    contents: [{ parts: [{ text: prompt }, { inlineData: { mimeType: img.mime, data: img.b64 } }] }],
    generationConfig: { responseMimeType: 'application/json', temperature: 0.2 },
  };

  for (let attempt = 0; attempt < 2; attempt++) {
    let resp;
    try {
      resp = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': GEMINI_API_KEY },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(60000),
      });
    } catch (e) {
      console.error('Gemini fetch failed:', e.cause || e);
      throw httpError(502, 'The AI service could not be reached');
    }
    if (resp.status === 429) throw httpError(429, 'AI limit reached. Try again in a minute.');
    if (!resp.ok) {
      console.error('Gemini error', resp.status, await resp.text().catch(() => ''));
      throw httpError(502, 'The AI service returned an error');
    }
    const data = await resp.json();
    const raw = data?.candidates?.[0]?.content?.parts?.map((p) => p.text || '').join('') || '';
    try {
      return JSON.parse(raw.replace(/```json|```/gi, '').trim());
    } catch {
      if (attempt === 1) throw httpError(502, 'The AI returned an unreadable answer');
    }
  }
}

/* ---------------- sanitize what Gemini returned ---------------- */
const FONTS = { Helvetica: 'Helvetica-Bold', 'Times-Roman': 'Times-Bold', Courier: 'Courier-Bold' };
const hex = (v, d) => (/^#[0-9a-f]{6}$/i.test(v || '') ? v : d);
const lum = (h) => {
  const n = parseInt(h.slice(1), 16);
  return 0.299 * (n >> 16) + 0.587 * ((n >> 8) & 255) + 0.114 * (n & 255);
};

function cleanStyle(s = {}) {
  const st = {
    font: FONTS[s.font] ? s.font : 'Helvetica',
    background: hex(s.background, '#ffffff'),
    text: hex(s.text, '#222222'),
    accent: hex(s.accent, '#1f3a5f'),
    headerStyle: ['banner', 'centered', 'plain'].includes(s.headerStyle) ? s.headerStyle : 'plain',
    headingStyle: ['underline', 'bar', 'plain'].includes(s.headingStyle) ? s.headingStyle : 'underline',
  };
  // Keep text and headings readable on the page color.
  const light = lum(st.background) > 128;
  if (Math.abs(lum(st.background) - lum(st.text)) < 100) st.text = light ? '#222222' : '#f5f5f5';
  if (st.headerStyle !== 'banner' && Math.abs(lum(st.background) - lum(st.accent)) < 60) {
    st.accent = light ? '#1f3a5f' : '#cfd8ff';
  }
  return st;
}

function pickLines(items, source, max) {
  const used = new Set();
  const out = [];
  for (const it of Array.isArray(items) ? items : []) {
    const i = Number(it?.index);
    if (!Number.isInteger(i) || i < 0 || i >= source.length || used.has(i)) continue;
    used.add(i);
    out.push(str(it.text, 2000) || source[i]);
    if (out.length >= max) break;
  }
  return out;
}

/* ---------------- PDF ---------------- */
function renderPdf(p, st) {
  return new Promise((resolve, reject) => {
    const M = 40;
    const doc = new PDFDocument({ size: 'A4', margin: M });
    const chunks = [];
    doc.on('data', (c) => chunks.push(c));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    const R = st.font;
    const B = FONTS[st.font];
    const W = doc.page.width - M * 2;
    const onAccent = lum(st.accent) > 160 ? '#16243b' : '#ffffff';

    const paintBg = () => {
      if (st.background.toLowerCase() === '#ffffff') return;
      doc.save().rect(0, 0, doc.page.width, doc.page.height).fill(st.background).restore();
    };
    paintBg();
    doc.on('pageAdded', paintBg);

    const contactLine = [...p.contacts.map((c) => (c.label ? `${c.label}: ${c.value}` : c.value)), p.address]
      .filter(Boolean)
      .join('   |   ');

    // ----- header: name, contact info -----
    if (st.headerStyle === 'banner') {
      doc.rect(0, 0, doc.page.width, 100).fill(st.accent);
      doc.font(B).fontSize(26).fillColor(onAccent).text(p.name, M, 26, { width: W });
      doc.font(R).fontSize(9).fillColor(onAccent).text(contactLine, M, doc.y + 4, { width: W });
      doc.y = 100 + 10;
    } else {
      const align = st.headerStyle === 'centered' ? 'center' : 'left';
      doc.font(B).fontSize(26).fillColor(st.accent).text(p.name, M, M, { width: W, align });
      doc.font(R).fontSize(9).fillColor(st.text).text(contactLine, M, doc.y + 4, { width: W, align });
      doc.moveDown(0.5);
    }
    doc.x = M;

    const section = (title) => {
      doc.moveDown(0.7);
      const y = doc.y;
      if (st.headingStyle === 'bar') {
        doc.rect(M, y, W, 18).fill(st.accent);
        doc.font(B).fontSize(11).fillColor(onAccent).text(title.toUpperCase(), M + 8, y + 4, { width: W - 16 });
        doc.y = y + 24;
      } else {
        doc.font(B).fontSize(12).fillColor(st.accent).text(title.toUpperCase(), M, y, { width: W });
        if (st.headingStyle === 'underline') {
          const ly = doc.y + 2;
          doc.moveTo(M, ly).lineTo(M + W, ly).lineWidth(1).strokeColor(st.accent).stroke();
          doc.y = ly + 6;
        } else {
          doc.moveDown(0.3);
        }
      }
      doc.x = M;
    };

    const para = (t) => {
      doc.font(R).fontSize(10).fillColor(st.text).text(t, M, doc.y, { width: W });
      doc.moveDown(0.3);
    };
    const bullet = (t) => para(`\u2022  ${t}`);

    // ----- bio -----
    if (p.bio) {
      section('Summary');
      para(p.bio);
    }
    // ----- requirement-relevant skills + experience -----
    if (p.skills.length) {
      section('Skills');
      para(p.skills.join('   |   '));
    }
    if (p.experiences.length) {
      section('Experience');
      p.experiences.forEach(bullet);
    }
    if (p.participations.length) {
      section('Participations');
      p.participations.forEach(bullet);
    }
    // ----- barely-changed info last -----
    const edu = p.education.filter((e) => e && Object.values(e).some(Boolean));
    if (edu.length) {
      section('Education');
      for (const e of edu) {
        doc.font(B).fontSize(10).fillColor(st.text).text(str(e.degree, 200) || 'Degree', M, doc.y, { width: W });
        const dates = e.start || e.end ? `${e.start || ''} - ${e.end || ''}` : '';
        const line = [e.institution, dates, e.gpa ? `CGPA ${e.gpa}` : ''].filter(Boolean).join('   |   ');
        if (line) para(line);
        doc.moveDown(0.2);
      }
    }

    doc.end();
  });
}

/* ---------------- route ---------------- */
router.post('/', requireUser, async (req, res, next) => {
  try {
    const requirements = (Array.isArray(req.body?.requirements) ? req.body.requirements : [])
      .map((r) => str(r, 300))
      .filter(Boolean)
      .slice(0, 100);
    if (!requirements.length) throw httpError(400, 'Tick at least one requirement.');

    const templateId = Number(req.body?.templateId);
    if (!Number.isInteger(templateId)) throw httpError(400, 'Choose a template.');

    const { data: tpl, error: tplErr } = await supabase
      .from('Template')
      .select('id, previewUrl')
      .eq('id', templateId)
      .eq('userId', req.userId)
      .maybeSingle();
    if (tplErr) throw tplErr;
    if (!tpl?.previewUrl) throw httpError(404, 'Template not found.');

    const [profile, img] = await Promise.all([loadProfile(req), loadImage(tpl.previewUrl)]);
    const ai = await callGemini(buildPrompt(profile, requirements), img);

    // Skills must come from the user's own list (case-insensitive).
    const byLower = new Map(profile.skills.map((s) => [s.toLowerCase(), s]));
    let skills = (Array.isArray(ai.skills) ? ai.skills : [])
      .map((s) => byLower.get(String(s).trim().toLowerCase()))
      .filter(Boolean);
    skills = [...new Set(skills)];
    if (!skills.length) skills = profile.skills;

    const experiences = pickLines(ai.experiences, profile.experiences, 5);
    const participations = pickLines(ai.participations, profile.participations, 3);

    const pdf = await renderPdf(
      {
        ...profile,
        skills,
        experiences: experiences.length ? experiences : profile.experiences.slice(0, 3),
        participations,
      },
      cleanStyle(ai.style)
    );

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': 'inline; filename="cv.pdf"',
    });
    res.send(pdf);
  } catch (e) {
    next(e);
  }
});

module.exports = router;