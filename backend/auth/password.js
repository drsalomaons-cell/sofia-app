const crypto = require('crypto');

const SCRYPT_PARAMS = { N: 16384, r: 8, p: 1, maxmem: 64 * 1024 * 1024 };
const KEY_LEN = 64;

function hashPassword(plain) {
  const salt = crypto.randomBytes(16);
  const hash = crypto.scryptSync(plain, salt, KEY_LEN, SCRYPT_PARAMS);
  return `scrypt:${salt.toString('hex')}:${hash.toString('hex')}`;
}

function verifyPassword(plain, stored) {
  if (!stored) return false;
  if (!stored.startsWith('scrypt:')) {
    return plain === stored;
  }
  const [, saltHex, hashHex] = stored.split(':');
  const salt = Buffer.from(saltHex, 'hex');
  const expected = Buffer.from(hashHex, 'hex');
  const actual = crypto.scryptSync(plain, salt, KEY_LEN, SCRYPT_PARAMS);
  return crypto.timingSafeEqual(expected, actual);
}

function needsRehash(stored) {
  return !stored || !stored.startsWith('scrypt:');
}

module.exports = { hashPassword, verifyPassword, needsRehash };
