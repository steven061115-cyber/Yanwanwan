# AI Backend

这个后端只做一件事：把 DeepSeek API key 留在服务器环境变量里，App 只请求自己的后端接口。

正式发布时建议部署到 Railway，并绑定 Railway Postgres。后端会使用 Postgres 保存：

- 每日 AI 查询次数
- 公告 URL + 正文 hash 的提取缓存
- DeepSeek 返回的结构化活动

命中缓存时不会调用 DeepSeek，也不会扣每日 AI 次数。

## 本地运行

```bash
cd Backend
cp .env.example .env
```

把 `.env` 里的 `DEEPSEEK_API_KEY` 换成真实 key。需要测试正式缓存/次数限制时，也填入 `DATABASE_URL`。

然后运行：

```bash
npm start
```

长公告提取可能比较慢。默认后端等待 DeepSeek 90 秒，App 等待后端 120 秒；需要调整时可修改 `.env` 里的 `DEEPSEEK_TIMEOUT_MS`。

健康检查：

```bash
curl http://127.0.0.1:8787/health
```

真机调试时，手机和 Mac 必须在同一个 Wi-Fi 下，App 里需要填 Mac 的局域网 IP：

```bash
ipconfig getifaddr en0
curl http://你的Mac局域网IP:8787/health
```

模拟器继续使用 `http://127.0.0.1:8787`。

## Railway 部署

1. 在 Railway 新建 Project。
2. 添加 Postgres 数据库。
3. 添加 Node 后端服务，根目录选择 `Backend`。
4. 在后端服务里配置环境变量：

```env
DEEPSEEK_API_KEY=你的 DeepSeek key
DATABASE_URL=${{Postgres.DATABASE_URL}}
MAX_TEXT_CHARS=50000
DEEPSEEK_TIMEOUT_MS=90000
```

Railway 会自动提供 `PORT`，不需要手动设置。部署成功后打开 `/health`，确认：

```json
{
  "ok": true,
  "deepSeekConfigured": true,
  "database": {
    "ok": true,
    "configured": true
  }
}
```

拿到 Railway 的 HTTPS 域名后，把 iOS 的 Release 后端地址改成该域名：

```swift
static let aiBackendBaseURL = "https://你的 Railway 域名"
```

提取接口：

```bash
curl -X POST http://127.0.0.1:8787/api/extract-events \
  -H 'Content-Type: application/json' \
  -H 'X-Install-ID: test-install-id' \
  -H 'X-Entitlement-Tier: free' \
  -d '{"gameName":"测试游戏","articleURL":"https://example.com/notice","text":"公告正文"}'
```

## 查询次数限制

后端按 `X-Install-ID` 和北京时间日期记录 AI 调用次数：

- 免费版：每日 1 次
- 会员：每日 5 次

命中缓存时不扣次数；缓存未命中时会在调用 DeepSeek 前预扣一次，如果 DeepSeek 失败会退回。请求头 `X-Entitlement-Tier` 传 `premium` 时按会员额度处理，其它值按免费版处理。

注意：当前会员状态仍由 App 传给后端，属于上线前的 MVP。正式防伪还需要接 Apple App Store Server API 校验订阅。
