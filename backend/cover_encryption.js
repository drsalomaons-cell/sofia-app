const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const ALGO = 'aes-256-gcm';
const STORAGE_DIR = path.join(__dirname, 'storage', 'encrypted_covers');
const VARIANTS = ['icon', 'splash', 'background'];

function getKey() {
  const secret = process.env.BRANDING_PROTECTION_KEY || 'SOFIA_BRANDING_V1';
  return crypto.createHash('sha256').update(secret).digest();
}

function encryptBuffer(buffer) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv(ALGO, getKey(), iv);
  const encrypted = Buffer.concat([cipher.update(buffer), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, encrypted]);
}

function decryptBuffer(data) {
  const iv = data.subarray(0, 12);
  const tag = data.subarray(12, 28);
  const encrypted = data.subarray(28);
  const decipher = crypto.createDecipheriv(ALGO, getKey(), iv);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(encrypted), decipher.final()]);
}

function encryptedPath(coverId, variant = 'splash') {
  return path.join(STORAGE_DIR, `${coverId}_${variant}.enc`);
}

function ensureStorageDir() {
  if (!fs.existsSync(STORAGE_DIR)) {
    fs.mkdirSync(STORAGE_DIR, { recursive: true });
  }
}

function saveEncryptedCover(coverId, rawContent, variant = 'splash') {
  ensureStorageDir();
  const buffer = Buffer.isBuffer(rawContent)
    ? rawContent
    : Buffer.from(rawContent, typeof rawContent === 'string' ? 'utf8' : 'base64');
  fs.writeFileSync(encryptedPath(coverId, variant), encryptBuffer(buffer));
}

function encryptCoverFromFile(sourcePath, coverId, variant = 'splash') {
  ensureStorageDir();
  const content = fs.readFileSync(sourcePath);
  fs.writeFileSync(encryptedPath(coverId, variant), encryptBuffer(content));
  return encryptedPath(coverId, variant);
}

function loadDecryptedCoverBuffer(coverId, variant = 'splash') {
  const filePath = encryptedPath(coverId, variant);
  if (!fs.existsSync(filePath)) return null;
  return decryptBuffer(fs.readFileSync(filePath));
}

function loadDecryptedCover(coverId, variant = 'splash') {
  const buffer = loadDecryptedCoverBuffer(coverId, variant);
  if (!buffer) return null;
  const isText = buffer[0] === 0x3c || buffer[0] === 0xef;
  return isText ? buffer.toString('utf8') : buffer;
}

function coverVariantExists(coverId, variant = 'splash') {
  return fs.existsSync(encryptedPath(coverId, variant));
}

function coverExists(coverId) {
  return VARIANTS.some(v => coverVariantExists(coverId, v));
}

function bootstrapCoversFromAssets(covers, assetsDir) {
  ensureStorageDir();
  for (const cover of covers) {
    for (const variant of VARIANTS) {
      if (coverVariantExists(cover.id, variant)) continue;
      const pngFile = cover.files?.[variant];
      const svgFallback = cover.svgFile;
      const pngPath = pngFile ? path.join(assetsDir, pngFile) : null;
      const svgPath = svgFallback ? path.join(assetsDir, svgFallback) : null;
      if (pngPath && fs.existsSync(pngPath)) {
        encryptCoverFromFile(pngPath, cover.id, variant);
      } else if (svgPath && fs.existsSync(svgPath) && variant === 'splash') {
        encryptCoverFromFile(svgPath, cover.id, variant);
      }
    }
  }
}

module.exports = {
  STORAGE_DIR,
  VARIANTS,
  encryptCoverFromFile,
  saveEncryptedCover,
  loadDecryptedCover,
  loadDecryptedCoverBuffer,
  coverExists,
  coverVariantExists,
  bootstrapCoversFromAssets,
};
