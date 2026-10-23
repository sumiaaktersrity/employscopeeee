// src/jobRequirements.js
// POST /api/job/requirements
// Accepts any of: jobText, jobUrl, pdf (all optional, at least one required).
// Returns: { requirements: ["...", "..."] }

require('dotenv').config();

const express = require('express');
const multer = require('multer');
const pdfParse = require('pdf-parse');
const dns = require('node:dns').promises;
const net = require('node:net');
const { createClient } = require('@supabase/supabase-js');

const router = express.Router();

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL ;
const MAX_TEXT_CHARS = 60000;
const MAX_PDF_BYTES = 5 * 1024 * 1024;
const MAX_PAGE_BYTES = 2 * 1024 * 1024;

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// ---------- upload (memory, PDF only) ----------
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_PDF_BYTES, files: 1 },
  fileFilter: (req, file, cb) => {
    const isPdf =
      file.mimetype === 'application/pdf' ||
      file.originalname.toLowerCase().endsWith('.pdf');
    if (!isPdf) return cb(new HttpError(400, 'Only PDF files are allowed'));
    cb(null, true);
  },
});

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

// ---------- auth: verify Supabase token ----------
async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) throw new HttpError(401, 'Missing auth token');
    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data?.user) throw new HttpError(401, 'Invalid auth token');
    req.user = data.user;
    next();
  } catch (e) {
    next(e);
  }
}

// ---------- URL fetching (with basic SSRF protection) ----------
function isPrivateIp(ip) {
  if (net.isIPv4(ip)) {
    const [a, b] = ip.split('.').map(Number);
    return (
      a === 10 ||
      a === 127 ||
      a === 0 ||
      (a === 169 && b === 254) ||
      (a === 172 && b >= 16 && b <= 31) ||
      (a === 192 && b === 168)
    );
  }
  const v = ip.toLowerCase();
  return (
    v === '::1' ||
    v === '::' ||
    v.startsWith('fc') ||
    v.startsWith('fd') ||
    v.startsWith('fe80') ||
    v.startsWith('::ffff:')
  );
}

async function assertPublicUrl(rawUrl) {
  let url;
  try {
    url = new URL(rawUrl);
  } catch {
    throw new HttpError(400, 'That job URL is not valid');
  }
  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    throw new HttpError(400, 'Job URL must start with http:// or https://');
  }
  const records = await dns.lookup(url.hostname, { all: true }).catch(() => []);
  if (records.length === 0) {
    throw new HttpError(400, "Couldn't reach that link. Paste the job text instead.");
  }
  if (records.some((r) => isPrivateIp(r.address))) {
    throw new HttpError(400, 'That link is not allowed');
  }
  return url;
}

function htmlToText(html) {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<noscript[\s\S]*?<\/noscript>/gi, ' ')
    .replace(/<(br|\/p|\/div|\/li|\/h[1-6]|\/tr)\s*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/[ \t]+/g, ' ')
    .replace(/\n\s*\n+/g, '\n')
    .trim();
}

async function fetchUrlText(rawUrl) {
  const failMsg = "Couldn't read that link. Paste the job text instead.";
  let current = rawUrl;

  for (let hop = 0; hop < 4; hop++) {
    const url = await assertPublicUrl(current);
    let resp;
    try {
      resp = await fetch(url, {
        redirect: 'manual',
        signal: AbortSignal.timeout(10000),
        headers: { 'User-Agent': 'Mozilla/5.0 (compatible; EmployScopeBot/1.0)' },
      });
    } catch {
      throw new HttpError(422, failMsg);
    }

    if (resp.status >= 300 && resp.status < 400) {
      const loc = resp.headers.get('location');
      if (!loc) throw new HttpError(422, failMsg);
      current = new URL(loc, url).toString();
      continue;
    }
    if (!resp.ok) throw new HttpError(422, failMsg);

    const buf = Buffer.from(await resp.arrayBuffer());
    if (buf.length > MAX_PAGE_BYTES) throw new HttpError(422, 'That page is too large');

    const type = resp.headers.get('content-type') || '';
    if (type.includes('application/pdf')) {
      const parsed = await pdfParse(buf).catch(() => null);
      if (!parsed?.text?.trim()) throw new HttpError(422, failMsg);
      return parsed.text;
    }
    const text = htmlToText(buf.toString('utf8'));
    if (text.length < 50) throw new HttpError(422, failMsg);
    return text;
  }
  throw new HttpError(422, failMsg);
}

// ---------- Gemini extraction ----------
const PROMPT = `You are reading a job post. List EVERY requirement it states or clearly implies: technical skills, tools, technologies, years of experience, education, certifications, languages, soft skills, responsibilities the candidate must be able to do, and any other qualification.

Rules:
- Do not limit the number of items. Include all of them.
- Each item is one short, clear phrase (max about 12 words).
- No duplicates. No commentary.
- If the text is not a job post or has no requirements, return an empty list.
- Reply with JSON only, exactly in this shape: {"requirements": ["...", "..."]}

JOB POST:
`;

function parseRequirements(raw) {
  const cleaned = raw.replace(/```json|```/gi, '').trim();
  const obj = JSON.parse(cleaned);
  const list = Array.isArray(obj) ? obj : obj.requirements;
  if (!Array.isArray(list)) throw new Error('bad shape');
  const seen = new Set();
  const out = [];
  for (const item of list) {
    const s = String(item).trim();
    const key = s.toLowerCase();
    if (s && !seen.has(key)) {
      seen.add(key);
      out.push(s);
    }
  }
  return out;
}

async function callGemini(jobText) {
  if (!GEMINI_API_KEY) throw new HttpError(500, 'Server is missing GEMINI_API_KEY');

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;
  const body = {
    contents: [{ parts: [{ text: PROMPT + jobText }] }],
    generationConfig: { responseMimeType: 'application/json', temperature: 0.2 },
  };

  for (let attempt = 0; attempt < 2; attempt++) {
    let resp;
    try {
      resp = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': GEMINI_API_KEY,
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(60000),
      });
    }      catch (e) {
      console.error('Gemini fetch failed:', e.cause || e);
      throw new HttpError(502, 'The AI service could not be reached');
    }

    if (resp.status === 429) {
      throw new HttpError(429, 'AI free-tier limit reached. Try again in a minute.');
    }
    if (!resp.ok) {
      console.error('Gemini error', resp.status, await resp.text().catch(() => ''));
      throw new HttpError(502, 'The AI service returned an error');
    }

    const data = await resp.json();
    const raw = data?.candidates?.[0]?.content?.parts?.map((p) => p.text || '').join('') || '';
    try {
      return parseRequirements(raw);
    } catch {
      if (attempt === 1) throw new HttpError(502, 'The AI returned an unreadable answer');
      // retry once on bad JSON
    }
  }
}

// ---------- route ----------
router.post('/requirements', requireAuth, upload.single('pdf'), async (req, res, next) => {
  try {
    const jobText = (req.body?.jobText || '').trim();
    const jobUrl = (req.body?.jobUrl || '').trim();
    const pdfFile = req.file;

    if (!jobText && !jobUrl && !pdfFile) {
      throw new HttpError(400, 'Provide a job description, URL, or PDF');
    }

    const parts = [];
    if (jobText) parts.push(jobText);

    if (pdfFile) {
      const parsed = await pdfParse(pdfFile.buffer).catch(() => null);
      if (!parsed?.text?.trim()) {
        throw new HttpError(422, "Couldn't read text from that PDF (is it a scan?)");
      }
      parts.push(parsed.text);
    }

    if (jobUrl) parts.push(await fetchUrlText(jobUrl));

    const combined = parts.join('\n\n').slice(0, MAX_TEXT_CHARS);
    const requirements = await callGemini(combined);
    res.json({ requirements });
  } catch (e) {
    next(e);
  }
});

// ---------- error handler for this router ----------
router.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    const msg = err.code === 'LIMIT_FILE_SIZE' ? 'PDF is too large (max 5 MB)' : err.message;
    return res.status(400).json({ error: msg });
  }
  const status = err.status || 500;
  if (status === 500) console.error(err);
  res.status(status).json({ error: status === 500 ? 'Something went wrong' : err.message });
});

module.exports = router;