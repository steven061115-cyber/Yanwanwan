import test from 'node:test';
import assert from 'node:assert/strict';
import {
  convertEventTimesToBeijing,
  formatOffset,
  serverRegionName,
  normalizeServerOffset,
  parseOffsetMinutes,
  toBeijingTime
} from '../src/event-time.js';

test('parses the offset spellings AI and notices use', () => {
  assert.equal(parseOffsetMinutes('+08:00'), 480);
  assert.equal(parseOffsetMinutes('-05:00'), -300);
  assert.equal(parseOffsetMinutes('UTC-5'), -300);
  assert.equal(parseOffsetMinutes('GMT+1'), 60);
  assert.equal(parseOffsetMinutes('+0530'), 330);
  assert.equal(parseOffsetMinutes('UTC'), 0);
  assert.equal(parseOffsetMinutes('server time'), null);
  assert.equal(parseOffsetMinutes(''), null);
  assert.equal(parseOffsetMinutes(undefined), null);
});

test('converts notice times to Beijing time', () => {
  assert.equal(toBeijingTime('2026-11-02 03:59', 480), '2026-11-02 03:59');
  // America server 03:59 (UTC-5) is 16:59 the same day in Beijing.
  assert.equal(toBeijingTime('2026-11-02 03:59', -300), '2026-11-02 16:59');
  // Europe server 23:00 (UTC+1) rolls over to the next day in Beijing.
  assert.equal(toBeijingTime('2026-12-31 23:00', 60), '2027-01-01 06:00');
  assert.equal(toBeijingTime('2026-11-02', -300), '2026-11-02 13:00');
  assert.equal(toBeijingTime('version end', -300), 'version end');
});

test('uses the event offset when given, otherwise the server offset', () => {
  const event = {
    title: 'Overflowing Favor',
    startDate: '2026-10-21 10:00',
    startOffset: '+08:00',
    endDate: '2026-11-02 03:59',
    category: '版本活动'
  };
  const converted = convertEventTimesToBeijing(event, -300);
  assert.equal(converted.startDate, '2026-10-21 10:00');
  assert.equal(converted.endDate, '2026-11-02 16:59');
  assert.equal(converted.title, 'Overflowing Favor');
});

test('falls back to Beijing time for missing or invalid server offsets', () => {
  assert.equal(normalizeServerOffset(undefined), 480);
  assert.equal(normalizeServerOffset('abc'), 480);
  assert.equal(normalizeServerOffset(7), 480);
  assert.equal(normalizeServerOffset(-300), -300);
  assert.equal(normalizeServerOffset(60), 60);
});

test('formats offsets for the prompt', () => {
  assert.equal(formatOffset(480), '+08:00');
  assert.equal(formatOffset(-300), '-05:00');
  assert.equal(formatOffset(330), '+05:30');
});

test('names the server region from the offset the app sends', () => {
  assert.equal(serverRegionName(-300), 'Americas（美服）');
  assert.equal(serverRegionName(60), 'Europe（欧服）');
  assert.equal(serverRegionName(480), 'Asia（亚服）/ 国服');
  assert.equal(serverRegionName(330), 'UTC+05:30');
});
