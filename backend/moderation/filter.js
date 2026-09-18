/** Filtro de moderação — palavras, PII e regras regionais (adaptado de Sunlight punishment/moderation) */

const FORBIDDEN_WORDS = [
  'palavrão', 'ofensa', 'discriminação', 'racismo', 'nazismo', 'terrorismo',
  'pedofilia', 'estupro', 'ameaça', 'matar', 'droga ilegal',
];

const PII_PATTERNS = [
  { type: 'email', regex: /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/ },
  { type: 'phone_br', regex: /(\(?\d{2}\)?\s?)?\d{4,5}[-\s]?\d{4}/ },
  { type: 'cpf', regex: /\d{3}\.?\d{3}\.?\d{3}-?\d{2}/ },
  { type: 'link', regex: /https?:\/\/|www\./i },
  { type: 'pix_key', regex: /pix|chave\s*pix/i },
];

const REGION_RULES = {
  'América do Sul': { maxMessageLength: 500, strictPii: true, languages: ['pt', 'es'] },
  'América do Norte': { maxMessageLength: 500, strictPii: true, languages: ['en', 'es'] },
  Ásia: { maxMessageLength: 400, strictPii: true, languages: ['en'] },
  África: { maxMessageLength: 500, strictPii: true, languages: ['en', 'pt', 'fr'] },
  Global: { maxMessageLength: 500, strictPii: true, languages: ['pt', 'en', 'es'] },
};

function moderateContent(text, region = 'Global') {
  const lower = (text || '').toLowerCase().trim();
  const rules = REGION_RULES[region] || REGION_RULES.Global;
  const violations = [];

  if (!lower) {
    return { allowed: false, violations: [{ type: 'empty', reason: 'Mensagem vazia' }] };
  }

  if (lower.length > rules.maxMessageLength) {
    violations.push({ type: 'spam', reason: 'Mensagem muito longa' });
  }

  for (const word of FORBIDDEN_WORDS) {
    if (lower.includes(word)) {
      violations.push({ type: 'forbidden_word', reason: `Conteúdo inadequado: ${word}` });
    }
  }

  for (const pattern of PII_PATTERNS) {
    if (pattern.regex.test(text)) {
      violations.push({ type: 'pii', reason: `Dado pessoal detectado (${pattern.type})` });
    }
  }

  return {
    allowed: violations.length === 0,
    violations,
    region,
    sanitized: violations.length > 0 ? '[conteúdo bloqueado pela moderação]' : text,
  };
}

module.exports = { FORBIDDEN_WORDS, PII_PATTERNS, REGION_RULES, moderateContent };
