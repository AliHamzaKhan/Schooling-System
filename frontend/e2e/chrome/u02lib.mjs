import { open, boot, texts, shot, enableSemantics } from './harness.mjs';
const BASE = 'http://localhost:8080/#';
const CLASS = 'Grade ' + (Date.now() % 100000);
const results = [];
const check = (name, ok, detail = '') => { results.push({ name, ok, detail }); console.log(`${ok ? 'PASS' : 'FAIL'} ${name} ${detail}`); };
const has = async (page, re) => (await texts(page)).some(t => re.test(t));
const settle = async (page, ms = 2500) => { await page.waitForTimeout(ms); await enableSemantics(page); };
async function tapText(page, re) {
  // Click the centre of the semantics node: valid only when it is on screen.
  const nodes = page.locator('flt-semantics');
  const n = await nodes.count();
  for (let i = 0; i < n; i++) {
    const el = nodes.nth(i);
    const label = (await el.getAttribute('aria-label')) || (await el.textContent()) || '';
    if (re.test(label.trim())) { const box = await el.boundingBox(); if (box && box.width > 0 && box.y >= 0 && box.y + box.height <= (page.viewportSize()?.height ?? 860)) { await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2); return true; } }
  }
  return false;
}
async function focusField(page, el) {
  let box = await el.boundingBox();
  for (let i = 0; box && i < 8 && (box.y < 60 || box.y + Math.min(box.height, 80) > 820); i++) {
    await page.mouse.move(683, 430);
    await page.mouse.wheel(0, box.y < 60 ? -300 : 300);
    await page.waitForTimeout(400);
    await enableSemantics(page);
    box = await el.boundingBox();
  }
  if (box) await page.mouse.click(box.x + 40, box.y + Math.min(box.height / 2, 70));
  else await el.click({ force: true });
}
async function typeInto(page, labelRe, value) {
  const inputs = page.locator('input[type="text"], input[type="password"], input:not([type]), textarea');
  if (typeof labelRe === 'number') { const el = inputs.nth(labelRe); await focusField(page, el); await page.keyboard.press('End'); for (let k = 0; k < 40; k++) await page.keyboard.press('Backspace'); if (value) await page.keyboard.type(value); return true; }
  const n = await inputs.count();
  for (let i = 0; i < n; i++) {
    const el = inputs.nth(i);
    const label = (await el.getAttribute('aria-label')) || (await el.getAttribute('placeholder')) || '';
    if (labelRe.test(label)) { await focusField(page, el); await page.keyboard.press('End'); for (let k = 0; k < 40; k++) await page.keyboard.press('Backspace'); if (value) await page.keyboard.type(value); return true; }
  }
  return false;
}
export { check, has, settle, tapText, typeInto, results, BASE, focusField };

