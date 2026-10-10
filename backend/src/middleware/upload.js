const multer = require('multer');
const path = require('path');

const ALLOWED = ['.pdf', '.docx'];

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB, matches the Flutter UI copy
  fileFilter: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (!ALLOWED.includes(ext)) {
      const err = new Error('Only PDF or DOCX files are allowed.');
      err.status = 400;
      return cb(err);
    }
    cb(null, true);
  },
});

module.exports = { uploadCv: upload.single('file') };
