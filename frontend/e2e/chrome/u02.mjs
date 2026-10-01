import { open, boot, texts, shot, enableSemantics } from './harness.mjs';
import { OUT, apiToken } from './harness.mjs';
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
export { check, has, settle, tapText, typeInto, results, BASE };


async function classExists(name) {
  const api = 'http://127.0.0.1:8000/api/v1';
  const token = await apiToken('head@chromeschool.edu', 'HeadPass123');
  const ids = JSON.parse((await import('node:fs')).readFileSync(`${OUT}/ids.txt`, 'utf8').trim().split('\n').pop());
  const rows = await (await fetch(`${api}/schools/${ids.school}/academic/classes`, { headers: { authorization: `Bearer ${token}` } })).json();
  return rows.some(r => r.name === name);
}

const { browser, page, logs } = await open('admin_portal', { storage: `${OUT}/hm_state.json` });
await boot(page, `${BASE}/headmaster/classes`);
check('cold deep link /headmaster/classes renders class directory', await has(page, /Class Directory/));

// Create class: empty name
await tapText(page, /^New Class$/); await settle(page);
await shot(page, 'u02_new_class_sheet');
const inputLabels = await page.$$eval('input', els => els.map(e => e.getAttribute('aria-label')));
console.log('sheet inputs', inputLabels);
await tapText(page, /^(Create|Save|Create Class|Add Class)$/i); await settle(page);
check('empty class name is rejected inline', await has(page, /Class name is required/));
await typeInto(page, /Grade 5/i, 'Grade 1'); await tapText(page, /^(Create|Save|Create Class|Add Class)$/i); await settle(page);
check('duplicate class name is rejected', await has(page, /already exists/i));
await shot(page, 'u02_dup_class');
await typeInto(page, /Grade 5/i, CLASS); await tapText(page, /^(Create|Save|Create Class|Add Class)$/i); await settle(page, 3500);
const totalBefore = 0;
check('valid class is created (server) and the sheet closes without an error', await classExists(CLASS) && !(await has(page, /already exists|required/i)));
await shot(page, 'u02_class_created');

// Refresh keeps the screen with real data
await page.reload(); await settle(page, 6000);
check('browser refresh keeps the class directory with data', await has(page, /Class Directory/) && await has(page, /Grade 1/));

// Settings validation
await page.goto(`${BASE}/headmaster/settings`); await settle(page, 5000);
await typeInto(page, 0, ''); await page.keyboard.press('Tab');
await page.mouse.wheel(0, 2000); await settle(page, 1000);
await tapText(page, /^Save/i); await settle(page);
check('empty school name is rejected', await has(page, /School name cannot be empty/i));
await shot(page, 'u02_settings_empty');
await typeInto(page, 0, 'Synthetic Chrome School');
await typeInto(page, /fee due day/i, '40');
await typeInto(page, /salary payout day/i, '0');
await tapText(page, /^Save/i); await settle(page);
check('fee day 40 rejected', await has(page, /fee day between 1 and 31/i));
await shot(page, 'u02_settings_days');
await typeInto(page, /fee due day/i, '10');
await tapText(page, /^Save/i); await settle(page);
check('salary day 0 rejected', await has(page, /salary day between 1 and 31/i));
await typeInto(page, /salary payout day/i, '28');
await tapText(page, /^Save/i); await settle(page, 3000);
check('valid settings save confirms', await has(page, /Settings saved/i));
await shot(page, 'u02_settings_saved');
const api = 'http://127.0.0.1:8000/api/v1';
const token = await apiToken('head@chromeschool.edu', 'HeadPass123');
const ids = JSON.parse((await import('node:fs')).readFileSync(`${OUT}/ids.txt`, 'utf8').trim().split('\n').pop());
const profile = await (await fetch(`${api}/schools/${ids.school}/profile`, { headers: { authorization: `Bearer ${token}` } })).json();
const saved = JSON.stringify(profile.settings ?? null);
check('saved settings persist on the server', saved.includes('10') && saved.includes('28') && profile.name === 'Synthetic Chrome School', saved === 'null' ? JSON.stringify(profile).slice(0, 160) : saved);
await page.reload(); await settle(page, 6000);
await page.mouse.move(683, 430); await page.mouse.wheel(0, 2000); await settle(page, 1000);
await shot(page, 'u02_settings_reloaded');

// Back / forward
await page.goto(`${BASE}/headmaster/classes`); await settle(page, 4000);
await page.goto(`${BASE}/headmaster/timetable`); await settle(page, 4000);
await page.goBack(); await settle(page, 4000);
check('browser Back returns to classes with data', await has(page, /Class Directory/) && await has(page, /Grade 1/));
await page.goForward(); await settle(page, 4000);
check('browser Forward returns to timetable', page.url().includes('/headmaster/timetable'));
await shot(page, 'u02_timetable');

console.log('ERRORS', logs.slice(0, 5).join('\n'));
await browser.close();
const fs = await import('node:fs');
fs.writeFileSync(`${OUT}/u02_results.json`, JSON.stringify(results, null, 2));
