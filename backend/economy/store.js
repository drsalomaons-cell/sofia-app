const fs = require('fs');
const path = require('path');
const economy = require('../economy/engine');
const { DEFAULT_CONFIG } = require('../economy/config');

const CONFIG_FILE = path.join(__dirname, '..', 'data', 'economy_config.json');

function loadEconomyConfig() {
  try {
    if (fs.existsSync(CONFIG_FILE)) {
      const cfg = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
      economy.setConfig(cfg);
      return cfg;
    }
  } catch (_) {}
  economy.setConfig(DEFAULT_CONFIG);
  saveEconomyConfig(DEFAULT_CONFIG);
  return DEFAULT_CONFIG;
}

function saveEconomyConfig(cfg) {
  const dir = path.dirname(CONFIG_FILE);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(cfg, null, 2));
  economy.setConfig(cfg);
  return cfg;
}

module.exports = { loadEconomyConfig, saveEconomyConfig, CONFIG_FILE };
