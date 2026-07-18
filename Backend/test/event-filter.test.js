import test from 'node:test';
import assert from 'node:assert/strict';
import {
  normalizeExtractedEvents,
  shouldExcludeEvent
} from '../src/event-filter.js';

const baseEvent = {
  startDate: '2026-07-18 10:00',
  endDate: '2026-08-01 03:59',
  category: '版本活动'
};

test('excludes gacha and sign-in related events from extraction results', () => {
  const events = normalizeExtractedEvents([
    { ...baseEvent, title: '星芒巡游' },
    { ...baseEvent, title: '青雀 UP 卡池', category: '卡池' },
    { ...baseEvent, title: '角色活动祈愿' },
    { ...baseEvent, title: '角色试用活动' },
    { ...baseEvent, title: '武器强化活动' },
    { ...baseEvent, title: '限定寻访 斩荆辟路' },
    { ...baseEvent, title: '七日登录奖励' },
    { ...baseEvent, title: '每日签到补给' }
  ]);

  assert.deepEqual(events.map((event) => event.title), ['星芒巡游']);
});

test('recognizes common gacha naming variants', () => {
  assert.equal(shouldExcludeEvent({ title: '角色跃迁 溯回忆象', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: '培养素材双倍', category: '角色活动' }), true);
  assert.equal(shouldExcludeEvent({ title: '限时挑战', category: '武器活动' }), true);
  assert.equal(shouldExcludeEvent({ title: '音擎调频 灿烂和声', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: '扩充补给 概率提升', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: '精准补给 破晓强袭', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: '联合作战挑战', category: '副本挑战' }), false);
});
