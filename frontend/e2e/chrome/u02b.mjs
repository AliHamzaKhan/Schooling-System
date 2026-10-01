import { open, boot, texts, shot, enableSemantics, login } from './harness.mjs';
import { OUT } from './harness.mjs';
import { check, has, settle, tapText, typeInto, results, BASE } from './u02lib.mjs';
import fs from 'node:fs';

// 1. Add a section to the newest class, then a backend outage on class create.
{
  const { browser, page } = await open('admin_portal', { storage: `${OUT}/hm_state.json` });
  await boot(page, `${BASE}/headmaster/classes`);
  await tapText(page, /^Add Section$/); await settle(page);
  await shot(page, 'u02_add_section_sheet');
  console.log('section sheet inputs', await page.$$eval('input', els => els.map(e => e.getAttribute('aria-label'))));
  await tapText(page, /^(Add|Create|Save|Add Section|Create Section)$/i); await settle(page);
  check('empty section name is rejected', await has(page, /Section name is required/i));
  const name = 'S' + (Date.now() % 1000);
  await typeInto(page, /e\.g\.|section/i, name);
  await tapText(page, /^(Add|Create|Save|Add Section|Create Section)$/i); await settle(page, 3500);
  check('valid section is created and listed', await has(page, new RegExp(`^${name}$|\\b${name}\\b`)));
  await shot(page, 'u02_section_created');

  await page.route('http://localhost:8000/**', route => route.request().method() === 'POST' ? route.fulfill({ status: 503, contentType: 'application/json', body: '{"detail":"Service unavailable","error":{"code":"service_unavailable","message":"Service unavailable"}}' }) : route.continue());
  await tapText(page, /^New Class$/); await settle(page);
  await typeInto(page, /Grade 5/i, 'Outage Class');
  await tapText(page, /^(Create|Save|Create Class|Add Class)$/i); await settle(page, 3000);
  const t = await texts(page);
  check('backend failure keeps the sheet open with an error and creates nothing', t.some(x => /unavailable|failed|could not|error|try again/i.test(x)) && t.some(x => /e\.g\. Grade 5|New Class|Create/i.test(x)), t.filter(x => /unavailable|fail|could not|error/i.test(x)).join(' / ').slice(0, 160));
  await shot(page, 'u02_create_outage');
  await page.unroute('http://localhost:8000/**');
  await browser.close();
}

// 2. Read failure: the classes list shows a retryable error, not stale/empty data.
{
  const { browser, page } = await open('admin_portal', { storage: `${OUT}/hm_state.json` });
  await page.route(/localhost:8000\/api\/v1\/schools\/[^/]+\/academic\/classes/, route => route.fulfill({ status: 500, contentType: 'application/json', body: '{"detail":"Internal error","error":{"code":"internal_error","message":"Internal error"}}' }));
  await boot(page, `${BASE}/headmaster/classes`);
  const t = await texts(page);
  check('failed read shows a retryable error state', t.some(x => /retry|try again/i.test(x)), t.slice(0, 6).join(' / ').slice(0, 200));
  await shot(page, 'u02_read_failure');
  await browser.close();
}

// 3. Keyboard: Tab reaches the settings fields and the save action.
{
  const { browser, page } = await open('admin_portal', { storage: `${OUT}/hm_state.json` });
  await boot(page, `${BASE}/headmaster/settings`);
  const seen = [];
  for (let i = 0; i < 40; i++) {
    await page.keyboard.press('Tab'); await page.waitForTimeout(150);
    seen.push(await page.evaluate(() => { const a = document.activeElement; return a ? (a.getAttribute('aria-label') || a.tagName) : ''; }));
  }
  console.log('TABORDER', JSON.stringify([...new Set(seen)].map(s => s.replace(/\s+/g, ' ').slice(0, 50))));
  check('Tab reaches school name, fee day, salary day and Save', ['School name', 'fee due day', 'Salary payout', 'Save'].every(k => seen.some(s => s.toLowerCase().includes(k.toLowerCase()))));
  await shot(page, 'u02_keyboard_focus');
  await browser.close();
}

// 4. 200% zoom equivalent (half the CSS viewport) and reduced motion.
{
  const { browser, page } = await open('admin_portal', { storage: `${OUT}/hm_state.json`, width: 683, height: 430, reducedMotion: 'reduce' });
  await boot(page, `${BASE}/headmaster/settings`);
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth + 1);
  check('settings reflow at 200% zoom without page-level horizontal scroll', !overflow);
  await shot(page, 'u02_zoom200_settings');
  await page.goto(`${BASE}/headmaster/classes`); await settle(page, 4000);
  await shot(page, 'u02_zoom200_classes');
  await browser.close();
}

// 5. A teacher opening a headmaster module by direct URL is denied.
{
  const { browser, page } = await open('admin_portal');
  await boot(page, 'http://localhost:8080/');
  await login(page, 'teacher@chromeschool.edu', 'Passw0rd1');
  const afterLogin = await texts(page);
  await shot(page, 'u02_teacher_login_admin');
  await page.goto(`${BASE}/headmaster/settings`); await settle(page, 5000);
  const t = await texts(page);
  check('teacher cannot open headmaster settings by URL', !t.some(x => /Save Settings|Monthly fee due day/i.test(x)), `${page.url()} :: ${t.slice(0, 4).join(' / ').slice(0, 160)} :: afterLogin=${afterLogin.slice(0, 3).join(' / ').slice(0, 120)}`);
  await shot(page, 'u02_teacher_direct_url');
  await browser.close();
}
fs.writeFileSync(`${OUT}/u02b_results.json`, JSON.stringify(results, null, 2));
