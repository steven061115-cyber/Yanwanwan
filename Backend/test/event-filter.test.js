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

test('excludes gacha and login events from global English and Traditional Chinese notices', () => {
  assert.equal(shouldExcludeEvent({ title: 'Featured Resonator Convene: Thawborn Renewal', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: 'Event Wish: Ballad in Goblets', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: 'Limited Headhunting', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: 'Character Event Warp', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: 'Daily Check-in', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: 'Login Event: Gift of Stars', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: '角色活動喚取', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: '每日簽到', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: 'Character Trial: Lingyang', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: 'Weapon Event: Abyssal Moon', category: '版本活动' }), true);
  assert.equal(shouldExcludeEvent({ title: 'Carefree Snowball Fight', category: '版本活动' }), false);
  assert.equal(shouldExcludeEvent({ title: 'Wishful Thinking Trials', category: '版本活动' }), false);
  assert.equal(shouldExcludeEvent({ title: '無憂無慮大雪仗', category: '版本活动' }), false);
});

test('excludes Endfield and NTE gacha, sign-in and outfit sales', () => {
  const excluded = [
    '[Spirit\'s Restoration] Sign-In Event',
    '[Moongleam Issue] Arsenal Issue Open',
    '[Tender Sprig Issue] RE-Factor Issue #1 Open',
    '[Rejuvenation] Chartered Headhunting',
    'Roostfeather Special Arc Research Program',
    'New Mystery Box Event: "Born to Race"',
    'New Limited S-Class Character: Blackbird',
    'New Blackbird Outfit "Wandering Stars" Added to Shop'
  ];
  for (const title of excluded) {
    assert.equal(shouldExcludeEvent({ title, category: '版本活动' }), true, title);
  }

  const kept = [
    '[Contingency Readiness] Limited-Time Event',
    '[Arena of Games] Challenge Event',
    '"Pukaland Travelogue" Limited-Time Event',
    '"Terminal Depths" Limited-Time Event',
    'Season of Phantasia'
  ];
  for (const title of kept) {
    assert.equal(shouldExcludeEvent({ title, category: '版本活动' }), false, title);
  }
});

test('excludes Japanese and Korean gacha and login events', () => {
  const excluded = [
    'イベント祈願「杯中のバラッド」',
    'キャラクターイベントワープ',
    '限定スカウト',
    'ログインボーナス',
    '캐릭터 이벤트 기원',
    '한정 헤드헌팅',
    '출석 이벤트',
    '무기 이벤트 워프'
  ];
  for (const title of excluded) {
    assert.equal(shouldExcludeEvent({ title, category: '版本活动' }), true, title);
  }

  for (const title of ['自由気ままな雪合戦', '幻想シアター', '근심 없는 눈싸움', '현실 속 환상극']) {
    assert.equal(shouldExcludeEvent({ title, category: '版本活动' }), false, title);
  }
});
