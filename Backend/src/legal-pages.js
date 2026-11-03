// Privacy policy and terms pages, served in each language the app supports.
// The app links here with ?lang=<AppLanguage>; App Store Connect links can use the same parameter.

export const SUPPORT_EMAIL = 'steven061115@gmail.com';
export const LEGAL_LANGS = ['zh-Hans', 'zh-Hant', 'en', 'ja', 'ko'];
const DEFAULT_LANG = 'en';
const UPDATED_AT = '2026-11-03';
const APPLE_EULA_URL = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

const LANG_ALIASES = {
  'zh-hans': 'zh-Hans', 'zh-cn': 'zh-Hans', 'zh-sg': 'zh-Hans', zh: 'zh-Hans',
  'zh-hant': 'zh-Hant', 'zh-tw': 'zh-Hant', 'zh-hk': 'zh-Hant', 'zh-mo': 'zh-Hant',
  en: 'en', ja: 'ja', ko: 'ko'
};

const LANG_NAMES = {
  'zh-Hans': '简体中文', 'zh-Hant': '繁體中文', en: 'English', ja: '日本語', ko: '한국어'
};

function matchLang(tag) {
  if (!tag) return null;
  const lower = String(tag).trim().toLowerCase();
  if (LANG_ALIASES[lower]) return LANG_ALIASES[lower];
  // zh-Hant-TW, zh-Hans-CN, en-US, ja-JP ...
  const parts = lower.split('-');
  for (let n = parts.length - 1; n >= 1; n -= 1) {
    const prefix = parts.slice(0, n).join('-');
    if (LANG_ALIASES[prefix]) return LANG_ALIASES[prefix];
  }
  return null;
}

// ?lang= wins; otherwise the first Accept-Language entry we support; otherwise English.
export function resolveLegalLang(queryLang, acceptLanguage) {
  const fromQuery = matchLang(queryLang);
  if (fromQuery) return fromQuery;

  const ranked = String(acceptLanguage ?? '')
    .split(',')
    .map((entry, index) => {
      const [tag, ...params] = entry.trim().split(';');
      const q = params.map((p) => p.trim()).find((p) => p.startsWith('q='));
      return { tag, q: q ? Number(q.slice(2)) || 0 : 1, index };
    })
    .filter((entry) => entry.tag && entry.q > 0)
    .sort((a, b) => b.q - a.q || a.index - b.index);

  for (const { tag } of ranked) {
    const lang = matchLang(tag);
    if (lang) return lang;
  }
  return DEFAULT_LANG;
}

const mail = `<a href="mailto:${SUPPORT_EMAIL}">${SUPPORT_EMAIL}</a>`;

const PRIVACY = {
  'zh-Hans': {
    title: '隐私政策',
    sections: [
      { p: '二游活动小灵通用于整理游戏活动和提醒。我们遵循最小必要原则，不出售用户数据，也不进行跨 App 或跨网站追踪。' },
      { h: '运营者与联系', p: `本服务由二游活动小灵通的开发者（即 App Store 产品页显示的开发者）运营。你可以发送邮件至 ${mail}，提出查阅、更正、删除、撤回同意或投诉请求。` },
      { h: '我们会处理的数据', ul: [
        '安装标识：App 会生成一个随机安装标识，用于后端计算每日 AI 提取额度和基础限流。',
        'IP 地址：后端会临时使用请求的 IP 地址做基础限流和防滥用，只保存在内存中，不写入数据库。',
        '公告内容：仅当你主动使用 AI 提取时，游戏名、公告链接和公告正文会发送到后端，用于整理活动。共享结果缓存不保存安装标识与结果之间的映射。',
        '购买凭证：开通会员后，App 会把 App Store 交易凭证发送给后端，只用于验证会员额度。',
        '本地内容：你创建的游戏、活动、通知设置和小组件数据主要保存在设备本地；如果系统启用 iCloud，同步由 Apple iCloud 处理。'
      ] },
      { h: '第三方服务', p: 'AI 提取功能通过我们的后端调用 DeepSeek 模型。后端托管在 Railway 云平台。Apple 提供 App 内购买、iCloud 和通知能力；活动数据接口用于获取公开活动时间。付款信息不经过我们的服务器。' },
      { h: '数据保留', p: '后端仅按提供服务及安全审计所需的最短期限保留安装标识对应的额度记录。提取缓存保存公告内容哈希、链接和结构化结果，不保存原始公告正文。你可以在 App 的“管理我的数据”中删除额度记录并重置安装标识。' },
      { h: '数据存储', p: '你的数据可能在你所在国家或地区以外的服务器上处理。我们采用 HTTPS 传输，并采取合理措施保护存储安全。' },
      { h: '你的权利', p: '你可以在 App 内清除本地数据、删除当前安装标识对应的服务器记录、撤回隐私同意。撤回后，在再次同意前 App 不会启动联网服务。' },
      { h: '未成年人保护', p: '本 App 不以未成年人为主要服务对象。未成年人应在监护人指导下使用 AI 功能和购买服务。' },
      { h: '联系我们', p: `如需隐私相关支持，请发送邮件至 ${mail}。` }
    ]
  },
  'zh-Hant': {
    title: '隱私政策',
    sections: [
      { p: '二遊活動小靈通用於整理遊戲活動與提醒。我們遵循最小必要原則，不出售使用者資料，也不進行跨 App 或跨網站追蹤。' },
      { h: '營運者與聯絡方式', p: `本服務由二遊活動小靈通的開發者（即 App Store 產品頁顯示的開發者）營運。你可以寄送電子郵件至 ${mail}，提出查閱、更正、刪除、撤回同意或申訴請求。` },
      { h: '我們會處理的資料', ul: [
        '安裝識別碼：App 會產生一組隨機安裝識別碼，供後端計算每日 AI 擷取額度與基礎限流。',
        'IP 位址：後端會暫時使用請求的 IP 位址進行基礎限流與防濫用，僅保存在記憶體中，不寫入資料庫。',
        '公告內容：僅在你主動使用 AI 擷取時，遊戲名稱、公告連結與公告內文會傳送到後端，用於整理活動。共享結果快取不保存安裝識別碼與結果之間的對應關係。',
        '購買憑證：開通會員後，App 會將 App Store 交易憑證傳送到後端，僅用於驗證會員額度。',
        '本機內容：你建立的遊戲、活動、通知設定與小工具資料主要保存在裝置本機；若系統啟用 iCloud，同步由 Apple iCloud 處理。'
      ] },
      { h: '第三方服務', p: 'AI 擷取功能透過我們的後端呼叫 DeepSeek 模型。後端託管於 Railway 雲端平台。Apple 提供 App 內購買、iCloud 與通知功能；活動資料介面用於取得公開的活動時間。付款資訊不會經過我們的伺服器。' },
      { h: '資料保留', p: '後端僅依提供服務及安全稽核所需的最短期限，保留安裝識別碼對應的額度紀錄。擷取快取保存公告內容雜湊值、連結與結構化結果，不保存公告原文。你可以在 App 的「管理我的資料」中刪除額度紀錄並重設安裝識別碼。' },
      { h: '資料儲存', p: '你的資料可能在你所在國家或地區以外的伺服器上處理。我們採用 HTTPS 傳輸，並採取合理措施保護儲存安全。' },
      { h: '你的權利', p: '你可以在 App 內清除本機資料、刪除目前安裝識別碼對應的伺服器紀錄、撤回隱私同意。撤回後，在再次同意前 App 不會啟動連網服務。' },
      { h: '未成年人保護', p: '本 App 不以未成年人為主要服務對象。未成年人應在監護人指導下使用 AI 功能與購買服務。' },
      { h: '聯絡我們', p: `如需隱私相關協助，請寄送電子郵件至 ${mail}。` }
    ]
  },
  en: {
    title: 'Privacy Policy',
    sections: [
      { p: 'Gacha Event Tracker helps you keep track of game events and reminders. We collect only what we need, we never sell user data, and we do not track you across other apps or websites.' },
      { h: 'Who we are and how to reach us', p: `This service is operated by the developer of Gacha Event Tracker (the developer shown on the App Store product page). Email ${mail} to request access to, correction or deletion of your data, to withdraw consent, or to make a complaint.` },
      { h: 'Data we process', ul: [
        'Install ID: The app generates a random install ID that our server uses to count your daily AI extractions and apply basic rate limits.',
        'IP address: Our server briefly uses the IP address of each request for basic rate limiting and abuse prevention. It is kept in memory only and is never written to our database.',
        'Announcement content: Only when you choose to use AI extraction, the game name, announcement link and announcement text are sent to our server to organize events. The shared result cache does not link results to install IDs.',
        'Purchase transactions: After you buy Premium, the app sends the App Store transaction to our server solely to verify your Premium quota.',
        'Local content: The games, events, notification settings and widget data you create are stored mainly on your device. If iCloud is enabled, syncing is handled by Apple iCloud.'
      ] },
      { h: 'Third-party services', p: 'AI extraction calls the DeepSeek model through our server. Our server is hosted on Railway. Apple provides in-app purchases, iCloud and notifications; an event data API provides public event schedules. Payment details never pass through our servers.' },
      { h: 'Data retention', p: 'Our server keeps quota records tied to an install ID only as long as needed to provide the service and for security auditing. The extraction cache stores a hash of the announcement, its link and the structured result, never the original announcement text. You can delete your quota records and reset your install ID under “Manage My Data” in the app.' },
      { h: 'Where data is stored', p: 'Your data may be processed on servers outside your country or region. We use HTTPS and take reasonable measures to keep stored data secure.' },
      { h: 'Your rights', p: 'In the app you can clear local data, delete the server records for your current install ID, and withdraw your privacy consent. After you withdraw, the app will not start any network services until you consent again.' },
      { h: 'Children', p: 'This app is not directed at children. Minors should use the AI features and make purchases under the guidance of a parent or guardian.' },
      { h: 'Contact us', p: `For privacy questions, email ${mail}.` }
    ]
  },
  ja: {
    title: 'プライバシーポリシー',
    sections: [
      { p: 'Gacha Event Trackerは、ゲームのイベントとリマインダーを整理するためのアプリです。必要最小限の情報のみを扱い、ユーザーデータを販売することはなく、他のアプリやウェブサイトをまたいだトラッキングも行いません。' },
      { h: '運営者と連絡先', p: `本サービスはGacha Event Trackerの開発者（App Storeの製品ページに表示される開発者）が運営しています。データの開示・訂正・削除、同意の撤回、苦情については ${mail} までメールでご連絡ください。` },
      { h: '取り扱うデータ', ul: [
        'インストールID：アプリはランダムなインストールIDを生成し、サーバーで1日のAI抽出回数の計算と基本的なレート制限に使用します。',
        'IPアドレス：サーバーは基本的なレート制限と不正利用防止のため、リクエストのIPアドレスを一時的に使用します。メモリ上でのみ扱い、データベースには保存しません。',
        'お知らせの内容：ご自身でAI抽出を実行した場合に限り、ゲーム名、お知らせのリンクと本文をサーバーに送信し、イベントの整理に使用します。共有の結果キャッシュは、インストールIDと結果を紐づけません。',
        '購入情報：プレミアムの購入後、アプリはApp Storeの取引情報をサーバーに送信します。これはプレミアムの利用枠の確認にのみ使用します。',
        '端末内のデータ：作成したゲーム、イベント、通知設定、ウィジェットのデータは主に端末内に保存されます。iCloudが有効な場合、同期はApple iCloudが行います。'
      ] },
      { h: '第三者のサービス', p: 'AI抽出は、当社のサーバーを経由してDeepSeekモデルを呼び出します。サーバーはRailwayでホストしています。Appleはアプリ内課金、iCloud、通知機能を提供し、イベントデータAPIは公開されているイベント日程の取得に使用します。支払い情報が当社のサーバーを通ることはありません。' },
      { h: 'データの保存期間', p: 'インストールIDに紐づく利用枠の記録は、サービス提供とセキュリティ監査に必要な最短期間のみ保存します。抽出キャッシュにはお知らせのハッシュ、リンク、整理結果を保存し、お知らせの本文そのものは保存しません。アプリの「データの管理」から、利用枠の記録を削除しインストールIDをリセットできます。' },
      { h: 'データの保管場所', p: 'お客様のデータは、お住まいの国や地域以外のサーバーで処理される場合があります。HTTPSによる通信と、保存データを守るための合理的な措置を講じています。' },
      { h: 'お客様の権利', p: 'アプリ内で、端末内データの消去、現在のインストールIDに紐づくサーバー記録の削除、プライバシーへの同意の撤回ができます。撤回後は、再び同意するまでアプリはネットワークサービスを開始しません。' },
      { h: '未成年の方へ', p: '本アプリは未成年の方を主な対象としていません。未成年の方は、保護者の指導のもとでAI機能の利用や購入を行ってください。' },
      { h: 'お問い合わせ', p: `プライバシーに関するお問い合わせは ${mail} までメールでご連絡ください。` }
    ]
  },
  ko: {
    title: '개인정보 처리방침',
    sections: [
      { p: 'Gacha Event Tracker는 게임 이벤트와 알림을 정리하는 앱입니다. 꼭 필요한 정보만 처리하며, 사용자 데이터를 판매하지 않고, 다른 앱이나 웹사이트에 걸친 추적을 하지 않습니다.' },
      { h: '운영자 및 연락처', p: `본 서비스는 Gacha Event Tracker 개발자(App Store 제품 페이지에 표시된 개발자)가 운영합니다. 데이터 열람·정정·삭제, 동의 철회 또는 불만 제기는 ${mail}로 이메일을 보내 주세요.` },
      { h: '처리하는 데이터', ul: [
        '설치 ID: 앱은 무작위 설치 ID를 생성하며, 서버는 이를 일일 AI 추출 횟수 계산과 기본 요청 제한에 사용합니다.',
        'IP 주소: 서버는 기본 요청 제한과 남용 방지를 위해 요청의 IP 주소를 일시적으로 사용합니다. 메모리에서만 사용하며 데이터베이스에 저장하지 않습니다.',
        '공지 내용: 사용자가 직접 AI 추출을 실행할 때에만 게임 이름, 공지 링크와 본문이 서버로 전송되어 이벤트 정리에 사용됩니다. 공유 결과 캐시는 설치 ID와 결과를 연결하지 않습니다.',
        '구매 정보: 프리미엄 구매 후 앱은 App Store 거래 정보를 서버로 보내며, 이는 프리미엄 이용 한도 확인에만 사용됩니다.',
        '기기 내 데이터: 사용자가 만든 게임, 이벤트, 알림 설정, 위젯 데이터는 주로 기기에 저장됩니다. iCloud가 켜져 있으면 동기화는 Apple iCloud가 처리합니다.'
      ] },
      { h: '제3자 서비스', p: 'AI 추출은 당사 서버를 통해 DeepSeek 모델을 호출합니다. 서버는 Railway에서 호스팅됩니다. Apple은 앱 내 구입, iCloud, 알림 기능을 제공하며, 이벤트 데이터 API는 공개된 이벤트 일정을 가져오는 데 사용됩니다. 결제 정보는 당사 서버를 거치지 않습니다.' },
      { h: '데이터 보관 기간', p: '설치 ID에 연결된 이용 한도 기록은 서비스 제공과 보안 감사에 필요한 최소 기간 동안만 보관합니다. 추출 캐시에는 공지 내용의 해시, 링크, 정리된 결과만 저장하며 공지 원문은 저장하지 않습니다. 앱의 ‘내 데이터 관리’에서 이용 한도 기록을 삭제하고 설치 ID를 재설정할 수 있습니다.' },
      { h: '데이터 저장 위치', p: '사용자의 데이터는 거주 국가나 지역 밖의 서버에서 처리될 수 있습니다. 당사는 HTTPS로 전송하며 저장된 데이터를 보호하기 위한 합리적인 조치를 취합니다.' },
      { h: '사용자의 권리', p: '앱에서 기기 내 데이터 삭제, 현재 설치 ID에 연결된 서버 기록 삭제, 개인정보 동의 철회를 할 수 있습니다. 철회 후에는 다시 동의할 때까지 앱이 네트워크 서비스를 시작하지 않습니다.' },
      { h: '미성년자 보호', p: '본 앱은 미성년자를 주요 대상으로 하지 않습니다. 미성년자는 보호자의 지도 아래 AI 기능을 사용하고 구매해야 합니다.' },
      { h: '문의하기', p: `개인정보 관련 문의는 ${mail}로 이메일을 보내 주세요.` }
    ]
  }
};

const eula = (label) => `<a href="${APPLE_EULA_URL}">${label}</a>`;

const TERMS = {
  'zh-Hans': {
    title: '服务条款',
    sections: [
      { p: '使用二游活动小灵通，即表示你同意本条款。App 用于个人整理游戏活动信息，提取结果可能受公告内容质量和 AI 服务状态影响，请以游戏官方公告为准。' },
      { h: '会员与购买', ul: [
        '月度会员为自动续订订阅，价格以 App Store 购买页显示为准。',
        '一休尼会员为一次性购买项目，购买后可长期使用当前会员权益。',
        '购买、续订、取消和退款由 Apple App Store 处理。你可以在系统账户的订阅管理中取消月度会员。',
        '月度会员会自动续订，除非在当前周期结束前至少 24 小时取消。'
      ] },
      { h: '会员权益', p: '会员当前包含更高的自定义游戏数量上限和每日 AI 提取额度。具体额度以 App 内展示为准。为了保证服务稳定，我们仍可能对异常高频请求进行限制。' },
      { h: '使用限制', p: '请勿批量滥用接口、绕过额度限制、提交违法内容，或将本服务用于侵犯他人权益的用途。' },
      { h: '非官方声明', p: '本 App 为非官方工具，与游戏厂商不存在隶属或授权关系。第三方名称和信息仅用于说明兼容对象，相关权利归原权利人所有。' },
      { h: 'Apple 标准协议', p: `App 内购买还受 ${eula('Apple 标准许可协议（EULA）')} 约束。` },
      { h: '联系我们', p: `如需服务相关支持，请发送邮件至 ${mail}。` }
    ]
  },
  'zh-Hant': {
    title: '服務條款',
    sections: [
      { p: '使用二遊活動小靈通，即表示你同意本條款。App 用於個人整理遊戲活動資訊，擷取結果可能受公告內容品質與 AI 服務狀態影響，請以遊戲官方公告為準。' },
      { h: '會員與購買', ul: [
        '月度會員為自動續訂訂閱，價格以 App Store 購買頁面顯示為準。',
        '一休尼會員為一次性購買項目，購買後可長期使用目前的會員權益。',
        '購買、續訂、取消與退款由 Apple App Store 處理。你可以在系統帳號的訂閱管理中取消月度會員。',
        '月度會員會自動續訂，除非在目前週期結束前至少 24 小時取消。'
      ] },
      { h: '會員權益', p: '會員目前包含更高的自訂遊戲數量上限與每日 AI 擷取額度。具體額度以 App 內顯示為準。為確保服務穩定，我們仍可能限制異常高頻率的請求。' },
      { h: '使用限制', p: '請勿大量濫用介面、規避額度限制、提交違法內容，或將本服務用於侵害他人權益的用途。' },
      { h: '非官方聲明', p: '本 App 為非官方工具，與遊戲廠商不存在隸屬或授權關係。第三方名稱與資訊僅用於說明相容對象，相關權利歸原權利人所有。' },
      { h: 'Apple 標準協議', p: `App 內購買亦受 ${eula('Apple 標準授權協議（EULA）')} 約束。` },
      { h: '聯絡我們', p: `如需服務相關協助，請寄送電子郵件至 ${mail}。` }
    ]
  },
  en: {
    title: 'Terms of Service',
    sections: [
      { p: 'By using Gacha Event Tracker, you agree to these terms. The app is for personally organizing game event information. Extraction results depend on the quality of the announcement and the availability of the AI service, so always rely on the official game announcements.' },
      { h: 'Premium and purchases', ul: [
        'Monthly Premium is an auto-renewing subscription. The price is as shown on the App Store purchase sheet.',
        'Lifetime Premium is a one-time purchase that unlocks the current Premium benefits for the long term.',
        'Purchases, renewals, cancellations and refunds are handled by the Apple App Store. You can cancel Monthly Premium in your Apple account’s subscription settings.',
        'Monthly Premium renews automatically unless canceled at least 24 hours before the end of the current period.'
      ] },
      { h: 'Premium benefits', p: 'Premium currently includes a higher limit on custom games and a higher daily AI extraction quota. The exact limits are shown in the app. To keep the service stable, we may still limit unusually frequent requests.' },
      { h: 'Acceptable use', p: 'Do not abuse the API in bulk, bypass quota limits, submit unlawful content, or use the service to infringe the rights of others.' },
      { h: 'Unofficial app', p: 'This is an unofficial tool and is not affiliated with or endorsed by any game publisher. Third-party names and information are used only to identify compatible games; all rights belong to their respective owners.' },
      { h: 'Apple Standard EULA', p: `In-app purchases are also subject to the ${eula('Apple Standard License Agreement (EULA)')}.` },
      { h: 'Contact us', p: `For support, email ${mail}.` }
    ]
  },
  ja: {
    title: '利用規約',
    sections: [
      { p: 'Gacha Event Trackerを利用することで、本規約に同意したものとみなされます。本アプリは個人でゲームのイベント情報を整理するためのものです。抽出結果はお知らせの内容やAIサービスの状況によって左右されるため、必ずゲームの公式のお知らせをご確認ください。' },
      { h: 'プレミアムと購入', ul: [
        '月額プレミアムは自動更新サブスクリプションです。価格はApp Storeの購入画面に表示されるとおりです。',
        '買い切りプレミアムは1回限りの購入で、購入後は現在のプレミアム特典を長期間ご利用いただけます。',
        '購入、更新、解約、返金はApple App Storeが取り扱います。月額プレミアムはAppleアカウントのサブスクリプション設定から解約できます。',
        '月額プレミアムは、現在の期間が終了する24時間前までに解約しない限り自動的に更新されます。'
      ] },
      { h: 'プレミアム特典', p: 'プレミアムには現在、カスタムゲームの登録上限の拡大と、1日のAI抽出回数の拡大が含まれます。具体的な上限はアプリ内の表示をご確認ください。サービスを安定して提供するため、異常に頻繁なリクエストは制限する場合があります。' },
      { h: '禁止事項', p: 'APIの大量利用による濫用、利用枠制限の回避、違法なコンテンツの送信、他者の権利を侵害する目的での利用はおやめください。' },
      { h: '非公式アプリについて', p: '本アプリは非公式のツールであり、ゲームの開発・運営会社とは提携・承認の関係にありません。第三者の名称や情報は対応タイトルを示すためにのみ使用しており、関連する権利はそれぞれの権利者に帰属します。' },
      { h: 'Appleの標準使用許諾契約', p: `アプリ内課金には${eula('Appleの標準使用許諾契約（EULA）')}も適用されます。` },
      { h: 'お問い合わせ', p: `サポートが必要な場合は ${mail} までメールでご連絡ください。` }
    ]
  },
  ko: {
    title: '서비스 약관',
    sections: [
      { p: 'Gacha Event Tracker를 사용하면 본 약관에 동의한 것으로 간주됩니다. 이 앱은 개인이 게임 이벤트 정보를 정리하기 위한 것입니다. 추출 결과는 공지 내용의 품질과 AI 서비스 상태에 따라 달라질 수 있으므로 반드시 게임 공식 공지를 기준으로 확인해 주세요.' },
      { h: '프리미엄 및 구매', ul: [
        '월간 프리미엄은 자동 갱신 구독이며, 가격은 App Store 구매 화면에 표시된 금액을 따릅니다.',
        '평생 프리미엄은 1회 구매 상품으로, 구매 후 현재의 프리미엄 혜택을 장기간 이용할 수 있습니다.',
        '구매, 갱신, 취소 및 환불은 Apple App Store가 처리합니다. 월간 프리미엄은 Apple 계정의 구독 관리에서 취소할 수 있습니다.',
        '월간 프리미엄은 현재 기간이 끝나기 최소 24시간 전에 취소하지 않으면 자동으로 갱신됩니다.'
      ] },
      { h: '프리미엄 혜택', p: '프리미엄에는 현재 더 높은 커스텀 게임 추가 한도와 일일 AI 추출 한도가 포함됩니다. 정확한 한도는 앱 내 표시를 따릅니다. 안정적인 서비스를 위해 비정상적으로 잦은 요청은 제한될 수 있습니다.' },
      { h: '이용 제한', p: 'API를 대량으로 남용하거나, 이용 한도를 우회하거나, 불법 콘텐츠를 제출하거나, 타인의 권리를 침해하는 용도로 서비스를 이용하지 마세요.' },
      { h: '비공식 앱 안내', p: '본 앱은 비공식 도구이며 게임 개발사·운영사와 제휴하거나 승인을 받은 관계가 아닙니다. 제3자의 명칭과 정보는 지원 대상 게임을 표시하기 위해서만 사용되며, 관련 권리는 각 권리자에게 있습니다.' },
      { h: 'Apple 표준 라이선스 계약', p: `앱 내 구입에는 ${eula('Apple 표준 라이선스 계약(EULA)')}도 적용됩니다.` },
      { h: '문의하기', p: `지원이 필요하면 ${mail}로 이메일을 보내 주세요.` }
    ]
  }
};

const PAGE_TEXT = {
  'zh-Hans': { app: '二游活动小灵通', updated: '更新日期：' },
  'zh-Hant': { app: '二遊活動小靈通', updated: '更新日期：' },
  en: { app: 'Gacha Event Tracker', updated: 'Last updated: ' },
  ja: { app: 'Gacha Event Tracker', updated: '最終更新日：' },
  ko: { app: 'Gacha Event Tracker', updated: '최종 업데이트: ' }
};

function renderSections(sections) {
  return sections.map(({ h, p, ul }) => [
    h ? `<h2>${h}</h2>` : '',
    p ? `<p>${p}</p>` : '',
    ul ? `<ul>${ul.map((item) => `<li>${item}</li>`).join('')}</ul>` : ''
  ].join('')).join('\n    ');
}

function renderPage({ lang, path, doc }) {
  const text = PAGE_TEXT[lang];
  const switcher = LEGAL_LANGS
    .map((code) => code === lang
      ? `<strong>${LANG_NAMES[code]}</strong>`
      : `<a href="${path}?lang=${code}">${LANG_NAMES[code]}</a>`)
    .join(' · ');

  return `<!doctype html>
<html lang="${lang}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${doc.title} | ${text.app}</title>
  <style>
    :root { color-scheme: light; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color: #17213b; background: #f7f8fb; }
    body { margin: 0; }
    main { max-width: 760px; margin: 0 auto; padding: 40px 18px 56px; }
    nav { font-size: 13px; color: #69748a; margin-bottom: 24px; }
    h1 { margin: 0 0 8px; font-size: 30px; line-height: 1.2; }
    h2 { margin: 28px 0 10px; font-size: 18px; }
    p, li { font-size: 15px; line-height: 1.75; }
    p { margin: 0 0 12px; }
    ul { margin: 0; padding-left: 20px; }
    a { color: #d83d84; }
    .updated { color: #69748a; font-size: 13px; }
  </style>
</head>
<body>
  <main>
    <nav>${switcher}</nav>
    <h1>${doc.title}</h1>
    <p class="updated">${text.updated}${UPDATED_AT}</p>
    ${renderSections(doc.sections)}
  </main>
</body>
</html>`;
}

export function privacyPolicyHTML(lang) {
  return renderPage({ lang, path: '/privacy', doc: PRIVACY[lang] ?? PRIVACY[DEFAULT_LANG] });
}

export function termsOfServiceHTML(lang) {
  return renderPage({ lang, path: '/terms', doc: TERMS[lang] ?? TERMS[DEFAULT_LANG] });
}
