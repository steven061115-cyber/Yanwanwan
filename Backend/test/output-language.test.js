import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeOutputLanguage, outputLanguageName } from '../src/output-language.js';

test('accepts the three app languages and defaults to Simplified Chinese', () => {
  assert.equal(normalizeOutputLanguage('en'), 'en');
  assert.equal(normalizeOutputLanguage('zh-Hant'), 'zh-Hant');
  assert.equal(normalizeOutputLanguage('zh-Hans'), 'zh-Hans');
  assert.equal(normalizeOutputLanguage(undefined), 'zh-Hans');
  assert.equal(normalizeOutputLanguage('fr'), 'zh-Hans');
  assert.equal(normalizeOutputLanguage('__proto__'), 'zh-Hans');
});

test('names the language for the prompt', () => {
  assert.equal(outputLanguageName('en'), 'English');
  assert.equal(outputLanguageName('zh-Hant'), '繁體中文（台灣用語）');
  assert.equal(outputLanguageName(null), '简体中文');
});
