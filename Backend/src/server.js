import { createServer } from 'node:http';
import { promises as fs } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createDatabase } from './db.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, '..');
const usageFile = path.join(rootDir, 'data', 'daily-ai-usage.json');

await loadDotEnv();

const port = Number(process.env.PORT ?? 8787);
const host = process.env.HOST ?? '0.0.0.0';
const deepSeekApiKey = process.env.DEEPSEEK_API_KEY ?? '';
const maxTextChars = Number(process.env.MAX_TEXT_CHARS ?? 50000);
const deepSeekTimeoutMs = Number(process.env.DEEPSEEK_TIMEOUT_MS ?? 90000);
const database = createDatabase({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_SSL === 'true' ? { rejectUnauthorized: false } : undefined
});
const dailyLimits = {
  free: 2,
  premium: 5
};

await database.init();

const server = createServer((req, res) => {
  handleRequest(req, res).catch((error) => {
    console.error(error);
    sendJSON(res, 500, {
      error: 'internal_error',
      message: '服务器内部错误'
    });
  });
});

server.listen(port, host, () => {
  console.log(`AI backend listening on http://${host}:${port}`);
  console.log(`Simulator URL: http://127.0.0.1:${port}`);
  console.log(`Real device URL: http://<your-mac-lan-ip>:${port}`);
});

async function handleRequest(req, res) {
  if (req.method === 'GET' && req.url === '/health') {
    const databaseHealth = await database.health().catch((error) => ({
      ok: false,
      configured: database.isEnabled,
      message: error?.message ?? 'database unavailable'
    }));

    sendJSON(res, 200, {
      ok: true,
      deepSeekConfigured: Boolean(deepSeekApiKey),
      database: databaseHealth
    });
    return;
  }

  if (req.method === 'POST' && req.url === '/api/extract-events') {
    await handleExtractEvents(req, res);
    return;
  }

  sendJSON(res, 404, {
    error: 'not_found',
    message: '接口不存在'
  });
}

async function handleExtractEvents(req, res) {
  if (!deepSeekApiKey || deepSeekApiKey.startsWith('sk-your-')) {
    sendJSON(res, 500, {
      error: 'deepseek_not_configured',
      message: '请先在 Backend/.env 配置 DEEPSEEK_API_KEY'
    });
    return;
  }

  const body = await readJSONBody(req);
  const installId = getHeader(req, 'x-install-id')?.trim();
  const tier = getEntitlementTier(req);
  const gameName = typeof body.gameName === 'string' ? body.gameName.trim() : '';
  const articleUrl = typeof body.articleURL === 'string' ? body.articleURL.trim() : '';
  const text = typeof body.text === 'string' ? body.text.trim() : '';

  if (!installId || installId.length > 120) {
    sendJSON(res, 400, {
      error: 'missing_install_id',
      message: '缺少设备标识，请更新 App 后重试'
    });
    return;
  }

  if (!gameName) {
    sendJSON(res, 400, {
      error: 'missing_game_name',
      message: '缺少 gameName'
    });
    return;
  }

  if (!text) {
    sendJSON(res, 400, {
      error: 'missing_text',
      message: '缺少公告正文 text'
    });
    return;
  }

  const limitedText = text.slice(0, maxTextChars);
  const normalizedUrl = normalizeArticleURL(articleUrl);
  const contentHash = hashText(limitedText);
  const cacheKey = buildExtractionCacheKey({ normalizedUrl, contentHash, gameName });

  if (database.isEnabled) {
    const cached = await database.getCachedExtraction({ cacheKey });
    if (cached) {
      const quota = await getDailyQuota({ installId, tier });
      sendJSON(res, 200, {
        events: cached.events,
        quota,
        cache: {
          hit: true,
          articleURL: cached.articleUrl,
          updatedAt: cached.updatedAt
        }
      });
      return;
    }
  }

  let reservedQuota = null;
  if (database.isEnabled) {
    reservedQuota = await reserveDailyUsage({ installId, tier });
    if (!reservedQuota) {
      const quota = await getDailyQuota({ installId, tier });
      sendDailyLimitExceeded(res, { tier, quota });
      return;
    }
  } else {
    const quota = await getDailyQuota({ installId, tier });
    if (quota.used >= quota.limit) {
      sendDailyLimitExceeded(res, { tier, quota });
      return;
    }
  }

  let events;
  try {
    events = await extractEventsWithDeepSeek({
      gameName,
      text: limitedText
    });
  } catch (error) {
    if (reservedQuota) {
      await refundDailyUsage({ installId, tier }).catch((refundError) => {
        console.error('Failed to refund daily AI usage', refundError);
      });
    }

    console.error(error);
    sendJSON(res, 502, {
      error: 'deepseek_error',
      message: error?.message ?? 'DeepSeek 请求失败，请稍后重试'
    });
    return;
  }

  if (database.isEnabled) {
    await database.saveExtraction({
      cacheKey,
      articleUrl: articleUrl || null,
      normalizedUrl,
      contentHash,
      gameName,
      events
    }).catch((error) => {
      console.error('Failed to save extraction cache', error);
    });
  }

  const updatedQuota = reservedQuota ?? await incrementDailyUsage({ installId, tier });

  sendJSON(res, 200, {
    events,
    quota: updatedQuota,
    cache: {
      hit: false
    }
  });
}

async function extractEventsWithDeepSeek({ gameName, text }) {
  const today = formatDateOnlyInShanghai(new Date());
  const exampleEnd = formatDateTimeInShanghai(new Date(Date.now() + 21 * 86400 * 1000));

  const system = `
你是一个从游戏公告中提取结构化活动数据的助手，必须以 JSON 格式返回结果。

【时间规则】所有时间使用北京时间（UTC+8），格式严格为 "YYYY-MM-DD HH:mm"（例如 "2025-06-25 10:00"）。
必须按照原文公告中给出的具体时间填写，不得只写日期、不得省略小时分钟、不得换算时区。
如果公告只给了日期没有时间，填 "YYYY-MM-DD 00:00"。
如果公告写的是"当前版本结束"或"版本维护时"，请根据上下文中版本结束时间推断并填入。

【提取规则】请提取所有相关活动的起止时间，即使公告只写了"当前版本结束"，也请尽量提取。
过期判断将由客户端处理，不需要在此过滤。

收录类型：
1. 版本限时活动（有明确开始和结束时间）
2. 周常任务（endDate 填当前版本的维护时间）
3. 副本/关卡挑战

排除：社交媒体活动、充值礼包、线下活动、官方直播、投票问卷、每日签到/打卡活动、时装/皮肤折扣或销售活动。

返回 JSON 格式如下：
{"events":[{"title":"活动名","startDate":"YYYY-MM-DD HH:mm","endDate":"YYYY-MM-DD HH:mm","category":"版本活动"}]}

category 规则：
- 版本限时活动 → "版本活动"
- 周常/每周任务 → "周常任务"
- 副本/关卡挑战 → "副本挑战"

找不到则返回 JSON：{"events":[]}。
`.trim();

  const user = `
游戏：${gameName}
今天（北京时间）：${today}
示例版本结束时间：${exampleEnd}

以下是从公告页面提取的正文：
${text}
`.trim();

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), deepSeekTimeoutMs);
  let response;

  try {
    response = await fetch('https://api.deepseek.com/chat/completions', {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Authorization': `Bearer ${deepSeekApiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'deepseek-chat',
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user }
        ],
        response_format: { type: 'json_object' },
        temperature: 0,
        max_tokens: 4000
      })
    });
  } catch (error) {
    if (error?.name === 'AbortError') {
      throw new Error(`DeepSeek 请求超时（${Math.round(deepSeekTimeoutMs / 1000)} 秒）`);
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`DeepSeek ${response.status}: ${body.slice(0, 240)}`);
  }

  const data = await response.json();
  const content = data?.choices?.[0]?.message?.content;
  if (typeof content !== 'string') {
    throw new Error('DeepSeek 响应格式异常');
  }

  const parsed = JSON.parse(extractJSONPayload(content));
  const rawEvents = Array.isArray(parsed.events) ? parsed.events : [];
  return rawEvents.map(normalizeEvent).filter(Boolean);
}

function normalizeEvent(event) {
  if (!event || typeof event !== 'object') return null;

  const title = typeof event.title === 'string' ? event.title.trim() : '';
  const startDate = typeof event.startDate === 'string' ? event.startDate.trim() : '';
  const endDate = typeof event.endDate === 'string' ? event.endDate.trim() : '';
  const category = typeof event.category === 'string' && event.category.trim()
    ? event.category.trim()
    : '活动';

  if (!title || !endDate) return null;
  return { title, startDate, endDate, category };
}

function extractJSONPayload(content) {
  const trimmed = content.trim();
  const fenced = extractFirstFencedBlock(trimmed);
  if (fenced) return extractJSONObject(fenced) ?? fenced;
  return extractJSONObject(trimmed) ?? trimmed;
}

function extractJSONObject(text) {
  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  if (start === -1 || end === -1 || start > end) return null;
  return text.slice(start, end + 1).trim();
}

function extractFirstFencedBlock(text) {
  const opening = text.indexOf('```');
  if (opening === -1) return null;
  const afterOpening = text.slice(opening + 3);
  const firstNewline = afterOpening.indexOf('\n');
  const contentStart = firstNewline === -1 ? opening + 3 : opening + 3 + firstNewline + 1;
  const closing = text.indexOf('```', contentStart);
  if (closing === -1) return null;
  return text.slice(contentStart, closing).trim();
}

function formatDateOnlyInShanghai(date) {
  return formatParts(date).slice(0, 3).join('-');
}

function formatDateTimeInShanghai(date) {
  const [year, month, day, hour, minute] = formatParts(date);
  return `${year}-${month}-${day} ${hour}:${minute}`;
}

function formatParts(date) {
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Shanghai',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23'
  });

  const parts = Object.fromEntries(
    formatter.formatToParts(date).map((part) => [part.type, part.value])
  );

  return [parts.year, parts.month, parts.day, parts.hour, parts.minute];
}

async function readJSONBody(req) {
  const chunks = [];
  let total = 0;

  for await (const chunk of req) {
    total += chunk.length;
    if (total > 2 * 1024 * 1024) {
      throw new Error('请求体过大');
    }
    chunks.push(chunk);
  }

  const raw = Buffer.concat(chunks).toString('utf8');
  if (!raw.trim()) return {};
  return JSON.parse(raw);
}

function getHeader(req, name) {
  const value = req.headers[name];
  if (Array.isArray(value)) return value[0];
  return value;
}

function getEntitlementTier(req) {
  return getHeader(req, 'x-entitlement-tier') === 'premium' ? 'premium' : 'free';
}

function sendDailyLimitExceeded(res, { tier, quota }) {
  sendJSON(res, 429, {
    error: 'daily_limit_exceeded',
    message: tier === 'premium'
      ? '今日提取次数已用完，明天再试'
      : '免费版今日提取次数已用完，升级会员可每日提取 5 次',
    tier,
    used: quota.used,
    limit: quota.limit
  });
}

function hashText(text) {
  return createHash('sha256').update(text, 'utf8').digest('hex');
}

function buildExtractionCacheKey({ normalizedUrl, contentHash, gameName }) {
  if (normalizedUrl) {
    return `url:${normalizedUrl}:sha256:${contentHash}`;
  }

  return `text:${gameName.toLowerCase()}:sha256:${contentHash}`;
}

function normalizeArticleURL(rawUrl) {
  if (!rawUrl) return null;

  try {
    const url = new URL(rawUrl);
    url.protocol = url.protocol.toLowerCase();
    url.hostname = url.hostname.toLowerCase();
    url.hash = '';

    if (
      (url.protocol === 'https:' && url.port === '443') ||
      (url.protocol === 'http:' && url.port === '80')
    ) {
      url.port = '';
    }

    for (const key of Array.from(url.searchParams.keys())) {
      if (
        key.startsWith('utm_') ||
        [
          'spm_id_from',
          'share_source',
          'share_medium',
          'share_plat',
          'share_session_id',
          'bbid',
          'ts',
          'vd_source'
        ].includes(key)
      ) {
        url.searchParams.delete(key);
      }
    }

    url.searchParams.sort();
    return url.toString();
  } catch {
    const trimmed = rawUrl.trim();
    return trimmed ? trimmed : null;
  }
}

async function getDailyQuota({ installId, tier }) {
  const today = formatDateOnlyInShanghai(new Date());
  const limit = dailyLimits[tier] ?? dailyLimits.free;

  if (database.isEnabled) {
    return database.getDailyQuota({
      date: today,
      installId,
      tier,
      limit
    });
  }

  const usage = await readUsage();
  const used = usage?.[today]?.[installId]?.used ?? 0;
  return {
    date: today,
    tier,
    used,
    limit
  };
}

async function reserveDailyUsage({ installId, tier }) {
  const today = formatDateOnlyInShanghai(new Date());
  const limit = dailyLimits[tier] ?? dailyLimits.free;

  if (!database.isEnabled) return null;

  return database.reserveDailyUsage({
    date: today,
    installId,
    tier,
    limit
  });
}

async function refundDailyUsage({ installId, tier }) {
  const today = formatDateOnlyInShanghai(new Date());
  const limit = dailyLimits[tier] ?? dailyLimits.free;

  if (!database.isEnabled) {
    return getDailyQuota({ installId, tier });
  }

  return database.refundDailyUsage({
    date: today,
    installId,
    tier,
    limit
  });
}

async function incrementDailyUsage({ installId, tier }) {
  const today = formatDateOnlyInShanghai(new Date());
  const limit = dailyLimits[tier] ?? dailyLimits.free;

  if (database.isEnabled) {
    return database.reserveDailyUsage({
      date: today,
      installId,
      tier,
      limit
    });
  }

  const usage = await readUsage();
  usage[today] ??= {};
  usage[today][installId] ??= { used: 0, tier, updatedAt: null };
  usage[today][installId].used += 1;
  usage[today][installId].tier = tier;
  usage[today][installId].updatedAt = new Date().toISOString();
  await writeUsage(usage);

  return {
    date: today,
    tier,
    used: usage[today][installId].used,
    limit
  };
}

async function readUsage() {
  try {
    const data = await fs.readFile(usageFile, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    if (error?.code === 'ENOENT') return {};
    throw error;
  }
}

async function writeUsage(usage) {
  await fs.mkdir(path.dirname(usageFile), { recursive: true });
  await fs.writeFile(usageFile, `${JSON.stringify(usage, null, 2)}\n`, 'utf8');
}

function sendJSON(res, status, payload) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(payload));
}

async function loadDotEnv() {
  const envFile = path.join(rootDir, '.env');
  let raw;
  try {
    raw = await fs.readFile(envFile, 'utf8');
  } catch (error) {
    if (error?.code === 'ENOENT') return;
    throw error;
  }

  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const equalsIndex = trimmed.indexOf('=');
    if (equalsIndex === -1) continue;

    const key = trimmed.slice(0, equalsIndex).trim();
    let value = trimmed.slice(equalsIndex + 1).trim();
    if (!key || process.env[key] !== undefined) continue;

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    process.env[key] = value;
  }
}
