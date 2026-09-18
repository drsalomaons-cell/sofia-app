/**
 * ZEGO Express — geração de token (Token04) e configuração RTC
 */
const crypto = require('crypto');

const ZEGO_APP_ID = parseInt(process.env.ZEGO_APP_ID || '0', 10);
const ZEGO_SERVER_SECRET = process.env.ZEGO_SERVER_SECRET || process.env.ZEGO_APP_SIGN || '';

function isZegoConfigured() {
  return ZEGO_APP_ID > 0 && ZEGO_SERVER_SECRET.length > 0;
}

function generateToken04(userId, roomId, effectiveSeconds = 7200) {
  if (!isZegoConfigured()) {
    return {
      token: `sofia_dev_${userId}_${roomId}_${Date.now()}`,
      appId: 0,
      sandbox: true,
      expiresIn: effectiveSeconds,
    };
  }

  const now = Math.floor(Date.now() / 1000);
  const expire = now + effectiveSeconds;
  const nonce = crypto.randomBytes(8).toString('hex');
  const payload = JSON.stringify({
    app_id: ZEGO_APP_ID,
    user_id: userId,
    nonce,
    ctime: now,
    expire,
    payload: JSON.stringify({ room_id: roomId }),
  });

  const hash = crypto.createHmac('sha256', ZEGO_SERVER_SECRET).update(payload).digest('base64');
  const token = Buffer.from(JSON.stringify({ ver: 4, hash, payload })).toString('base64');

  return {
    token,
    appId: ZEGO_APP_ID,
    userId,
    roomId,
    expiresIn: effectiveSeconds,
    sandbox: false,
  };
}

module.exports = { isZegoConfigured, generateToken04, ZEGO_APP_ID };
