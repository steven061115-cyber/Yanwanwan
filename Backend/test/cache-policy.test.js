import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const serverSource = await readFile(new URL('../src/server.js', import.meta.url), 'utf8');

test('cache hits return before daily usage is reserved', () => {
  const cacheLookup = serverSource.indexOf('const cached = await database.getCachedExtraction');
  const cachedBranch = serverSource.indexOf('if (cached)', cacheLookup);
  const cachedReturn = serverSource.indexOf('return;', cachedBranch);
  const reserveUsage = serverSource.indexOf('reservedQuota = await reserveDailyUsage');

  assert.notEqual(cacheLookup, -1);
  assert.notEqual(cachedBranch, -1);
  assert.notEqual(cachedReturn, -1);
  assert.notEqual(reserveUsage, -1);
  assert.ok(cacheLookup < reserveUsage);
  assert.ok(cachedReturn < reserveUsage);
});

test('DeepSeek failures refund reserved daily usage before returning an error', () => {
  const deepSeekCall = serverSource.indexOf('events = await extractEventsWithDeepSeek');
  const catchBlock = serverSource.indexOf('} catch (error) {', deepSeekCall);
  const refund = serverSource.indexOf('await refundDailyUsage', catchBlock);
  const deepSeekError = serverSource.indexOf("error: 'deepseek_error'", catchBlock);

  assert.notEqual(deepSeekCall, -1);
  assert.notEqual(catchBlock, -1);
  assert.notEqual(refund, -1);
  assert.notEqual(deepSeekError, -1);
  assert.ok(refund < deepSeekError);
});

test('URL cache key is shared by link and unchanged content, not by game name', () => {
  const functionStart = serverSource.indexOf('function buildExtractionCacheKey');
  const functionEnd = serverSource.indexOf('function normalizeArticleURL', functionStart);
  const functionBody = serverSource.slice(functionStart, functionEnd);
  const urlBranch = functionBody.slice(
    functionBody.indexOf('if (normalizedUrl)'),
    functionBody.indexOf('return `text:')
  );

  assert.notEqual(functionStart, -1);
  assert.notEqual(functionEnd, -1);
  assert.match(urlBranch, /return `url:\$\{normalizedUrl\}:sha256:\$\{contentHash\}`/);
  assert.ok(!urlBranch.includes('gameName'));
});
