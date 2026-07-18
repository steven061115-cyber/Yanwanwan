const EXCLUDED_EVENT_PATTERNS = [
  /签到|签领|打卡|登录奖励|登录赠礼|累计登录|连续登录|每日登录|七日登录|登录活动/,
  /角色|武器/,
  /卡池|抽卡|祈愿|跃迁|寻访|调频|频段|复刻池|限定池|常驻池|角色池|武器池|装备池/i,
  /UP\s*池|概率\s*(提升|UP)|限时\s*UP|抽取|召唤|唤取/i,
  /(扩充|精准|标配|家园|人偶|SP|角色|装备|圣痕|武器)\s*补给/i,
  /(补给|招募|共鸣).*(角色|武器|装备|圣痕|限定|常驻|UP|概率|卡池|抽取)/i,
  /(角色|武器|装备|圣痕|限定|常驻|UP|概率|卡池|抽取).*(补给|招募|共鸣)/i
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
