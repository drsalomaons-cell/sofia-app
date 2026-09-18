/**
 * PagBank / PIX — sandbox + produção com webhook
 */
const crypto = require('crypto');
const pg = require('../db/postgres');

const PAGBANK_TOKEN = process.env.PAGBANK_TOKEN || process.env.PAGBANK_ACCESS_TOKEN || '';
const PAGBANK_SANDBOX = process.env.PAGBANK_SANDBOX !== 'false'
  && process.env.PAGBANK_AMBIENTE !== 'production';
const PAGBANK_WEBHOOK_SECRET = process.env.PAGBANK_WEBHOOK_SECRET || '';
const PAGBANK_API = PAGBANK_SANDBOX
  ? 'https://sandbox.api.pagseguro.com'
  : 'https://api.pagseguro.com';

const pendingJson = new Map();

function savePending(p) {
  if (pg.isPgActive()) {
    pg.pgAddPendingPayment(p).catch(() => {});
  } else {
    pendingJson.set(p.id, p);
  }
}

function getPending(id) {
  if (pg.isPgActive()) {
    return pg.pgFindPendingPayment(id);
  }
  return pendingJson.get(id) || null;
}

function completePending(id, status) {
  if (pg.isPgActive()) {
    pg.pgCompletePendingPayment(id, status).catch(() => {});
  } else {
    const p = pendingJson.get(id);
    if (p) pendingJson.set(id, { ...p, status });
  }
}

async function createPixCharge({ amount, userId, description, pendingId }) {
  const chargeId = pendingId || `pix_${Date.now()}_${userId}`;

  if (!PAGBANK_TOKEN) {
    return {
      success: true,
      sandbox: true,
      chargeId,
      qrCode: generateMockPixQr(amount),
      amount,
      status: PAGBANK_SANDBOX ? 'PAID' : 'PENDING',
      instantCredit: PAGBANK_SANDBOX,
      message: 'PagBank sandbox — pagamento simulado',
    };
  }

  try {
    const res = await fetch(`${PAGBANK_API}/charges`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${PAGBANK_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        reference_id: chargeId,
        description: description || 'Recarga SOFIA',
        amount: { value: Math.round(amount * 100), currency: 'BRL' },
        payment_method: { type: 'PIX' },
      }),
    });
    const data = await res.json();
    const externalId = data.id || chargeId;
    savePending({
      id: chargeId,
      userId,
      amount,
      type: 'recharge',
      status: 'pending',
      externalId,
      data,
    });
    return {
      success: res.ok,
      chargeId: externalId,
      sandbox: PAGBANK_SANDBOX,
      instantCredit: false,
      status: 'PENDING',
      ...data,
    };
  } catch (e) {
    return { success: false, error: e.message };
  }
}

async function createPixWithdraw({ amount, pixKey, userId, pendingId }) {
  const transferId = pendingId || `withdraw_${Date.now()}_${userId}`;

  if (!PAGBANK_TOKEN) {
    return {
      success: true,
      sandbox: true,
      transferId,
      amount,
      pixKey,
      status: 'PENDING',
      message: 'Saque PIX simulado — processamento em até 3 dias úteis',
    };
  }

  try {
    const res = await fetch(`${PAGBANK_API}/transfers`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${PAGBANK_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        amount: { value: Math.round(amount * 100), currency: 'BRL' },
        instrument: { type: 'PIX', pix_key: pixKey },
        reference: transferId,
      }),
    });
    const data = await res.json();
    savePending({
      id: transferId,
      userId,
      amount,
      type: 'withdraw',
      status: 'pending',
      externalId: data.id || transferId,
      data: { pixKey, ...data },
    });
    return { success: res.ok, transferId, ...data };
  } catch (e) {
    return { success: false, error: e.message };
  }
}

function verifyWebhookSignature(rawBody, signature) {
  if (!PAGBANK_WEBHOOK_SECRET) return PAGBANK_SANDBOX;
  const expected = crypto.createHmac('sha256', PAGBANK_WEBHOOK_SECRET).update(rawBody).digest('hex');
  return signature === expected;
}

function parseWebhookEvent(body) {
  const status = (body.status || body.charges?.[0]?.status || '').toUpperCase();
  const ref = body.reference_id || body.id || body.charges?.[0]?.reference_id;
  const paid = ['PAID', 'COMPLETED', 'CONFIRMED'].includes(status);
  return { ref, status, paid, raw: body };
}

function generateMockPixQr(amount) {
  return `00020126580014BR.GOV.BCB.PIX0136SOFIA${Date.now()}520400005303986540${amount.toFixed(2)}5802BR5925SOFIA6009SAO PAULO62070503***6304`;
}

module.exports = {
  createPixCharge,
  createPixWithdraw,
  verifyWebhookSignature,
  parseWebhookEvent,
  getPending,
  completePending,
  PAGBANK_SANDBOX,
};
