const EXCLUDED_EVENT_PATTERNS = [
  /签到|签领|打卡|登录奖励|登录赠礼|累计登录|连续登录|每日登录|七日登录|登录活动/,
  /角色|武器/,
  /卡池|抽卡|祈愿|跃迁|寻访|调频|频段|复刻池|限定池|常驻池|角色池|武器池|装备池/i,
  /UP\s*池|概率\s*(提升|UP)|限时\s*UP|抽取|召唤|唤取/i,
  /(扩充|精准|标配|家园|人偶|SP|角色|装备|圣痕|武器)\s*补给/i,
  /(补给|招募|共鸣).*(角色|武器|装备|圣痕|限定|常驻|UP|概率|卡池|抽取)/i,
  /(角色|武器|装备|圣痕|限定|常驻|UP|概率|卡池|抽取).*(补给|招募|共鸣)/i,
  // 繁体公告（国际服中文官网）
  /簽到|簽領|登入獎勵|累計登入|連續登入|每日登入|卡池|祈願|躍遷|尋訪|調頻|復刻池|喚取|召喚|武器池|角色池/,
  // 英文公告（国际服英文官网）
  /\b(banners?|wish(es)?|warps?|convene|headhunting|gacha|rate[- ]?up|signal search|recruitment)\b/i,
  // 与中文规则"角色|武器"对应
  /\b(characters?|weapons?)\b/i,
  // 日文公告（"武器"与中文同形，已由上面的中文规则覆盖）
  /ガチャ|ピックアップ|祈願|ワープ|スカウト|召喚|調律|ログインボーナス|ログイン報酬|ログインイベント|ログイン|キャラクター/,
  // 韩文公告
  /가챠|뽑기|픽업|기원|워프|헤드헌팅|스카우트|소환|출석|로그인|캐릭터|무기/,
  /\b(check-?in|log-?in|login|sign-?in) (event|rewards?|bonus)\b|\bdaily (check-?in|login|sign-?in)\b/i,
  // 各游戏的抽取 / 开箱 / 外观售卖叫法（鸣潮、终末地、异环）
  /\b(arsenal issue|re-?factor|arc research|mystery box(es)?|limited s-class|featured (resonator|weapon))\b/i,
  /\b(outfits?|skins?)\b.*\b(shop|sale|discount|price)\b|\b(shop|sale|discount)\b.*\b(outfits?|skins?)\b/i
];

export function normalizeExtractedEvents(events) {
  if (!Array.isArray(events)) return [];
  return events.map(normalizeEvent).filter(Boolean);
}

export function normalizeEvent(event) {
  if (!event || typeof event !== 'object') return null;

  const title = typeof event.title === 'string' ? event.title.trim() : '';
  const startDate = typeof event.startDate === 'string' ? event.startDate.trim() : '';
  const endDate = typeof event.endDate === 'string' ? event.endDate.trim() : '';
  const category = typeof event.category === 'string' && event.category.trim()
    ? event.category.trim()
    : '活动';

  if (!title || !endDate) return null;
  if (shouldExcludeEvent({ title, category })) return null;

  return { title, startDate, endDate, category };
}

export function shouldExcludeEvent(event) {
  const title = typeof event?.title === 'string' ? event.title.trim() : '';
  const category = typeof event?.category === 'string' ? event.category.trim() : '';
  const searchable = `${title} ${category}`;
  return EXCLUDED_EVENT_PATTERNS.some((pattern) => pattern.test(searchable));
}
