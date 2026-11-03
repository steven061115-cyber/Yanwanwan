import test from 'node:test';
import assert from 'node:assert/strict';
import {
  LEGAL_LANGS,
  SUPPORT_EMAIL,
  privacyPolicyHTML,
  resolveLegalLang,
  termsOfServiceHTML
} from '../src/legal-pages.js';

test('?lang= wins over Accept-Language', () => {
  assert.equal(resolveLegalLang('ja', 'ko-KR,ko;q=0.9'), 'ja');
  assert.equal(resolveLegalLang('zh-tw', null), 'zh-Hant');
});

test('Accept-Language picks the best supported language', () => {
  assert.equal(resolveLegalLang(null, 'fr-FR,ko;q=0.8,en;q=0.5'), 'ko');
  assert.equal(resolveLegalLang(null, 'zh-Hant-TW'), 'zh-Hant');
  assert.equal(resolveLegalLang(null, 'zh-CN,zh;q=0.9'), 'zh-Hans');
  assert.equal(resolveLegalLang(null, 'en;q=0.4,ja;q=0.9'), 'ja');
});

test('unsupported or missing languages fall back to English', () => {
  assert.equal(resolveLegalLang('xx', 'fr-FR,de;q=0.8'), 'en');
  assert.equal(resolveLegalLang(undefined, undefined), 'en');
});

test('every language renders both pages with the contact email and no placeholders', () => {
  for (const lang of LEGAL_LANGS) {
    for (const html of [privacyPolicyHTML(lang), termsOfServiceHTML(lang)]) {
      assert.match(html, new RegExp(`<html lang="${lang}">`));
      assert.ok(html.includes(`mailto:${SUPPORT_EMAIL}`), `${lang} page lacks contact email`);
      assert.ok(!/正式发布前|备案|undefined/.test(html), `${lang} page has leftover text`);
    }
  }
});

test('terms pages link the Apple standard EULA', () => {
  for (const lang of LEGAL_LANGS) {
    assert.ok(termsOfServiceHTML(lang).includes('apple.com/legal/internet-services/itunes/dev/stdeula'));
  }
});
