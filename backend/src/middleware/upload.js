const multer = require('multer');
const path = require('path');

const ALLOWED = ['.pdf', '.docx'];
const IMAGE_EXT = ['.png', '.jpg', '.jpeg', '.webp'];

const makeFilter = (allowed, message) => (_req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  if (!allowed.includes(ext)) {
    const err = new Error(message);
    err.status = 400;
    return cb(err);
  }
  cb(null, true);
};

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB, matches the Flutter UI copy
  fileFilter: makeFilter(ALLOWED, 'Only PDF or DOCX files are allowed.'),
});

const uploadImage = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: makeFilter(IMAGE_EXT, 'Only PNG, JPG or WEBP images are allowed.'),
});

module.exports = {
  uploadCv: upload.single('file'),
  uploadTemplate: uploadImage.single('file'),
};