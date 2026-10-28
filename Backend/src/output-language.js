// AI 输出活动名所用的语言，对应 App 的界面语言。

const LANGUAGE_NAMES = {
  'zh-Hans': '简体中文',
  'zh-Hant': '繁體中文（台灣用語）',
  en: 'English',
  ja: '日本語',
  ko: '한국어'
};

export const DEFAULT_OUTPUT_LANGUAGE = 'zh-Hans';

// 旧版 App 不传语言，按简体中文处理，与改动前一致。
export function normalizeOutputLanguage(value) {
  return Object.hasOwn(LANGUAGE_NAMES, value) ? value : DEFAULT_OUTPUT_LANGUAGE;
}

export function outputLanguageName(language) {
  return LANGUAGE_NAMES[normalizeOutputLanguage(language)];
}
