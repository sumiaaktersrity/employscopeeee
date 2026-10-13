const router = require('express').Router();
const { supabase } = require('../config/supabase');
const { requireUser } = require('../middleware/auth');
const { uploadTemplate } = require('../middleware/upload');

const TEMPLATE_BUCKET = 'templates';

router.use(requireUser);
const uid = (req) => req.userId ?? req.user?.id;

// List
router.get('/', async (req, res) => {
  const { data, error } = await supabase
    .from('Template')
    .select('id, name, previewUrl')
    .eq('userId', uid(req))
    .order('id', { ascending: false });
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

// Create (multipart: field "file" + field "name")
router.post('/', uploadTemplate, async (req, res) => {
  const file = req.file;
  const name = (req.body.name || '').trim();
  if (!file) return res.status(400).json({ error: 'No file uploaded (field name must be "file").' });
  if (!name) return res.status(400).json({ error: 'name required' });

  const safe = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
  const filePath = `${uid(req)}/${Date.now()}_${safe}`;

  const { error: upErr } = await supabase.storage.from(TEMPLATE_BUCKET).upload(filePath, file.buffer, {
    contentType: file.mimetype || 'application/octet-stream',
    upsert: false,
  });
  if (upErr) return res.status(500).json({ error: upErr.message });

  const { data: pub } = supabase.storage.from(TEMPLATE_BUCKET).getPublicUrl(filePath);

  const { data, error } = await supabase
    .from('Template')
    .insert({ name, previewUrl: pub.publicUrl, userId: uid(req) })
    .select('id, name, previewUrl')
    .single();
  if (error) {
    await supabase.storage.from(TEMPLATE_BUCKET).remove([filePath]); // don't orphan the file
    return res.status(500).json({ error: error.message });
  }
  res.status(201).json(data);
});

// Delete (only if yours), also removes the file
router.delete('/:id', async (req, res) => {
  const { data: row } = await supabase
    .from('Template').select('previewUrl')
    .eq('id', req.params.id).eq('userId', uid(req)).single();

  const { error } = await supabase
    .from('Template').delete()
    .eq('id', req.params.id).eq('userId', uid(req));
  if (error) return res.status(500).json({ error: error.message });

  if (row?.previewUrl) {
    const marker = `/object/public/${TEMPLATE_BUCKET}/`;
    const i = row.previewUrl.indexOf(marker);
    if (i !== -1) {
      await supabase.storage.from(TEMPLATE_BUCKET).remove([decodeURIComponent(row.previewUrl.slice(i + marker.length))]);
    }
  }
  res.json({ ok: true });
});

module.exports = router;