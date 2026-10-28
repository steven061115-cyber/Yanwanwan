// 公告里的时间可能是北京时间、UTC 偏移或各服务器时间。AI 照抄原文时间并标出偏移，
// 这里统一换算成北京时间（UTC+8），App 端按北京时间解析即可。

const BEIJING_OFFSET_MINUTES = 8 * 60;
const DATE_TIME_PATTERN = /^(\d{4})-(\d{1,2})-(\d{1,2})(?:[ T](\d{1,2}):(\d{2}))?$/;
const OFFSET_PATTERN = /([+-])\s*(\d{1,2})(?::?(\d{2}))?/;

// App 传来的服务器偏移（分钟）。不合法时按北京时间处理，与旧版 App 行为一致。
export function normalizeServerOffset(value) {
  const minutes = Number(value);
  if (!Number.isInteger(minutes) || minutes < -12 * 60 || minutes > 14 * 60 || minutes % 15 !== 0) {
    return BEIJING_OFFSET_MINUTES;
  }
  return minutes;
}

// "+08:00"、"-05:00"、"UTC-5"、"GMT+1" → 分钟；"Z"/"UTC" 视为 0；无法识别返回 null。
export function parseOffsetMinutes(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.round(value * 60);
  if (typeof value !== 'string') return null;

  const text = value.trim();
  if (!text) return null;
  if (/^(z|utc|gmt)$/i.test(text)) return 0;

  const match = text.match(OFFSET_PATTERN);
  if (!match) return null;

  const sign = match[1] === '-' ? -1 : 1;
  const hours = Number(match[2]);
  const minutes = Number(match[3] ?? 0);
  if (hours > 14 || minutes > 59) return null;
  return sign * (hours * 60 + minutes);
}

// "YYYY-MM-DD HH:mm"（偏移为 offsetMinutes）→ 北京时间的 "YYYY-MM-DD HH:mm"。格式不对时原样返回。
export function toBeijingTime(dateText, offsetMinutes) {
  if (typeof dateText !== 'string') return dateText;
  const match = dateText.trim().match(DATE_TIME_PATTERN);
  if (!match) return dateText;

  const [, year, month, day, hour = '0', minute = '0'] = match;
  const utcMs = Date.UTC(Number(year), Number(month) - 1, Number(day), Number(hour), Number(minute))
    - offsetMinutes * 60 * 1000;
  const beijing = new Date(utcMs + BEIJING_OFFSET_MINUTES * 60 * 1000);

  const pad = (n) => String(n).padStart(2, '0');
  return `${beijing.getUTCFullYear()}-${pad(beijing.getUTCMonth() + 1)}-${pad(beijing.getUTCDate())} `
    + `${pad(beijing.getUTCHours())}:${pad(beijing.getUTCMinutes())}`;
}

// AI 返回的单个活动：按 startOffset / endOffset 换算，没给偏移就用服务器偏移。
export function convertEventTimesToBeijing(event, serverOffsetMinutes) {
  if (!event || typeof event !== 'object') return event;

  const startOffset = parseOffsetMinutes(event.startOffset) ?? serverOffsetMinutes;
  const endOffset = parseOffsetMinutes(event.endOffset) ?? serverOffsetMinutes;

  return {
    ...event,
    startDate: toBeijingTime(event.startDate, startOffset),
    endDate: toBeijingTime(event.endDate, endOffset)
  };
}

export function formatOffset(minutes) {
  const sign = minutes < 0 ? '-' : '+';
  const abs = Math.abs(minutes);
  return `${sign}${String(Math.floor(abs / 60)).padStart(2, '0')}:${String(abs % 60).padStart(2, '0')}`;
}
