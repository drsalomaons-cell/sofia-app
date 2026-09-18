#!/usr/bin/env node
/** Migra dados JSON → PostgreSQL (execute após definir DATABASE_URL) */
require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const fs = require('fs');
const path = require('path');
const pg = require('../db/postgres');

const DATA = path.join(__dirname, '../data/data');

async function main() {
  const ok = await pg.initPool();
  if (!ok) {
    console.error('DATABASE_URL não configurada');
    process.exit(1);
  }
  const load = (name) => {
    const fp = path.join(DATA, `${name}.json`);
    if (!fs.existsSync(fp)) return [];
    return JSON.parse(fs.readFileSync(fp, 'utf8'));
  };
  const users = load('users');
  const rooms = load('rooms');
  const txs = load('transactions');
  const catalog = load('gift_catalog');
  if (users.length) await pg.pgSaveUsers(users);
  if (rooms.length) await pg.pgSaveRooms(rooms);
  if (txs.length) await pg.pgSaveTransactions(txs);
  if (catalog.length) await pg.pgWriteCollection?.('gift_catalog', catalog);
  console.log(`Migrado: ${users.length} users, ${rooms.length} rooms, ${txs.length} txs`);
  process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(1); });
