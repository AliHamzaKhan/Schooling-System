import { open, boot, login, texts, shot, enableSemantics } from './harness.mjs';
import { OUT, apiToken } from './harness.mjs';
import { check, results } from './u02lib.mjs';
import fs from 'node:fs';
const S = 'http://localhost:8081/#';
const settle = async (p, ms = 3000) => { await p.waitForTimeout(ms); await enableSemantics(p); };
const has = async (p, re) => (await texts(p)).some(t => re.test(t));
async function tapLabel(page, re) {
  const nodes = page.locator('flt-semantics');
  const n = await nodes.count();
  for (let i = 0; i < n; i++) {
    const el = nodes.nth(i);
    const label = ((await el.getAttribute('aria-label')) || (await el.textContent()) || '').trim();
    if (re.test(label)) { const b = await el.boundingBox(); if (b && b.width > 0 && b.y >= 0 && b.y + b.height <= 900) { await page.mouse.click(b.x + b.width / 2, b.y + b.height / 2); return true; } }
  }
  return false;
}

if (process.env.ONLY_F03) { } else {
// F02: refresh keeps session; logout clears it; Back after logout shows no data.
{
  const { browser, page } = await open('school_portal', { width: 390, height: 844 });
  await boot(page, `${S}/`);
  await login(page, 'teacher@chromeschool.edu', 'Passw0rd1');
  await page.reload(); await settle(page, 6000);
  check('F02 refresh keeps the teacher signed in', page.url().includes('/teacher') && await has(page, /Synthetic Teacher/));
  const tapped = await tapLabel(page, /^Log out$/);
  await settle(page, 2500);
  if (await has(page, /^(Log out|Sign out|Confirm)$/i)) { await tapLabel(page, /^(Log out|Sign out|Confirm)$/i); await settle(page, 3000); }
  await shot(page, 'f02_after_logout');
  check('F02 logout returns to sign-in', tapped && /login|\/$/.test(page.url()) && await has(page, /Login|Sign in/i), page.url());
  await page.goBack(); await settle(page, 3000);
  check('F02 Back after logout does not reveal teacher data', !(await has(page, /Synthetic Teacher/)), page.url());
  await page.goto(`${S}/teacher`); await settle(page, 5000);
  check('F02 direct URL after logout requires sign-in', !(await has(page, /Synthetic Teacher/)) && await has(page, /Login|Sign in/i), page.url());
  const stored = await page.evaluate(() => Object.keys(localStorage).filter(k => /token|refresh/i.test(k) && localStorage.getItem(k)));
  check('F02 no token remains in browser storage after logout', stored.length === 0, JSON.stringify(stored));
  await browser.close();
}

// F02: cross-tab logout invalidates the other tab.
{
  const { browser, context, page } = await open('school_portal', { width: 390, height: 844 });
  await boot(page, `${S}/`);
  await login(page, 'teacher@chromeschool.edu', 'Passw0rd1');
  const other = await context.newPage();
  await other.goto(`${S}/teacher`); await settle(other, 7000);
  check('F02 second tab shares the session', await has(other, /Synthetic Teacher/));
  await tapLabel(page, /^Log out$/); await settle(page, 2500);
  if (await has(page, /^(Log out|Sign out|Confirm)$/i)) { await tapLabel(page, /^(Log out|Sign out|Confirm)$/i); await settle(page, 3000); }
  await settle(other, 4000);
  await shot(other, 'f02_other_tab_after_logout');
  check('F02 logout in one tab signs the other tab out', !(await has(other, /Synthetic Teacher/)), other.url());
  await browser.close();
}

}
// F03: login return to a deep link; teacher denied headmaster routes.
{
  const { browser, page } = await open('school_portal', { width: 1280, height: 860 });
  await boot(page, `${S}/teacher/calendar`);
  const atLogin = await has(page, /Login|Sign in/i);
  await login(page, 'teacher@chromeschool.edu', 'Passw0rd1'); await settle(page, 3000);
  check('F03 signed-out deep link returns to it after login', atLogin && page.url().includes('/teacher/calendar'), page.url());
  await shot(page, 'f03_login_return');
  await page.goto(`${S}/headmaster/settings`); await settle(page, 5000);
  check('F03 teacher cannot open a headmaster route by URL', !(await has(page, /Save Settings|Monthly fee due day/i)), page.url());
  await page.goto(`${S}/teacher/messages`); await settle(page, 5000);
  await page.reload(); await settle(page, 6000);
  check('F03 teacher route survives refresh', page.url().includes('/teacher/messages') && !(await has(page, /arguments required|Something went wrong/i)), (await texts(page)).slice(0, 4).join(' / ').slice(0, 200));
  await shot(page, 'f03_teacher_messages_refresh');
  await browser.close();
}

// Guardian cannot read another student's data by URL-manipulated id (API).
{
  const api = 'http://127.0.0.1:8000/api/v1';
  const tok = (u, p) => apiToken(u, p);
  const ids = JSON.parse(fs.readFileSync(`${OUT}/ids.txt`, 'utf8').trim().split('\n').pop());
  const g = await tok('guardian@chromeschool.edu', 'Passw0rd1');
  const r = await fetch(`${api}/schools/${ids.school}/students/${ids.teacher}/attendance`, { headers: { authorization: `Bearer ${g}` } });
  check('F01 guardian cannot read a non-linked user record by id', r.status === 403 || r.status === 404, String(r.status));
}
fs.writeFileSync(`${OUT}/f02f03_results.json`, JSON.stringify(results, null, 2));
