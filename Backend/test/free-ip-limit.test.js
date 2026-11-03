import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { FreeIPDailyLimiter } from '../src/free-ip-limit.js';

test('caps each IP per day, independent of other IPs', () => {
  const limiter = new FreeIPDailyLimiter(2);
  assert.equal(limiter.reserve('1.1.1.1', '2026-11-03'), true);
  assert.equal(limiter.reserve('1.1.1.1', '2026-11-03'), true);
  assert.equal(limiter.reserve('1.1.1.1', '2026-11-03'), false);
  assert.equal(limiter.reserve('2.2.2.2', '2026-11-03'), true);
});

test('a new day starts with a fresh allowance', () => {
  const limiter = new FreeIPDailyLimiter(1);
  assert.equal(limiter.reserve('1.1.1.1', '2026-11-03'), true);
  assert.equal(limiter.reserve('1.1.1.1', '2026-11-03'), false);
  assert.equal(limiter.reserve('1.1.1.1', '2026-11-04'), true);
});

test('release gives the slot back, but not across days', () => {
  const limiter = new FreeIPDailyLimiter(1);
  assert.equal(limiter.reserve('1.1.1.1', '2026-11-03'), true);
  limiter.release('1.1.1.1', '2026-11-03');
  assert.equal(limiter.reserve('1.1.1.1', '2026-11-03'), true);

  limiter.release('1.1.1.1', '2026-11-02');
  assert.equal(limiter.reserve('1.1.1.1', '2026-11-03'), false);
});

test('extraction reserves the free IP slot and releases it on DeepSeek failure', async () => {
  const source = await readFile(new URL('../src/server.js', import.meta.url), 'utf8');
  const reserve = source.indexOf('freeIPLimiter.reserve(');
  const quotaReserve = source.indexOf('reservedQuota = await reserveDailyUsage');
  const deepSeekCall = source.indexOf('events = await extractEventsWithDeepSeek');
  const deepSeekError = source.indexOf("error: 'deepseek_error'", deepSeekCall);
  const release = source.indexOf('releaseFreeIPSlot()', deepSeekCall);

  assert.notEqual(reserve, -1);
  assert.ok(reserve < quotaReserve, 'IP cap must be checked before install-ID quota is reserved');
  assert.ok(release > deepSeekCall && release < deepSeekError, 'DeepSeek failure must release the IP slot');
});
