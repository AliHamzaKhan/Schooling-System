// Accountant journey: finance home, adjustment request, Headmaster approval,
// and school photos loading only with a token.
import { open, boot, login, texts, shot, click, apiToken } from './harness.mjs';
const API = 'http://127.0.0.1:8000/api/v1';
const hm = await apiToken('head@chromeschool.edu', 'HeadPass123');
const H = t => ({ authorization: `Bearer ${t}`, 'content-type': 'application/json' });
const me = await (await fetch(`${API}/auth/me`, { headers: H(hm) })).json();
const sid = me.school_id;
const email = 'accountant@chromeschool.edu';
let r = await fetch(`${API}/schools/${sid}/users`, { method: 'POST', headers: H(hm),
  body: JSON.stringify({ email, password: 'Passw0rd1', full_name: 'Synthetic Accountant', role_codes: ['accountant'] }) });
console.log('create accountant', r.status, '(409/400 = already exists)');
const users = await (await fetch(`${API}/schools/${sid}/users?limit=100`, { headers: H(hm) })).json();
const student = (users.items || users).find(u => u.email === 'student@chromeschool.edu');
const inv = await (await fetch(`${API}/schools/${sid}/fees/invoices`, { method: 'POST', headers: H(hm),
  body: JSON.stringify({ student_id: student.id, title: `Accountant check fee ${Date.now()}`, amount: 500, due_date: '2026-12-01' }) })).json();
const acct = await apiToken(email, 'Passw0rd1');
const req = await fetch(`${API}/schools/${sid}/fees/adjustments`, { method: 'POST', headers: H(acct),
  body: JSON.stringify({ kind: 'waiver', target_id: inv.id, proposed_amount: '100', reason: 'Sibling discount' }) });
const adj = await req.json();
console.log('accountant request', req.status, 'decision:', adj.decision);

// 1. Accountant UI
let { browser, page, logs } = await open('school_portal', { width: 1280, height: 860 });
await boot(page, 'http://localhost:8081/');
await login(page, email, 'Passw0rd1');
console.log('accountant landed on', page.url());
console.log('  ', (await texts(page)).filter(t => t.length < 90).slice(0, 12).join(' | '));
await shot(page, 'accountant_home');
await click(page, 'Refunds, credits and waivers');
await page.waitForTimeout(3000);
const queue = await texts(page);
console.log('  queue shows waiting:', queue.some(t => t.includes('Waiting for the Headmaster')), '| approve button:', queue.some(t => t === 'Approve'));
await shot(page, 'accountant_queue');
if (logs.length) console.log('  console:', logs.slice(0, 3).join(' || ').slice(0, 300));
await browser.close();

// 2. Headmaster approves in the UI
({ browser, page, logs } = await open('school_portal', { width: 1280, height: 860 }));
await boot(page, 'http://localhost:8081/');
await login(page, 'head@chromeschool.edu', 'HeadPass123');
await page.goto('http://localhost:8081/#/headmaster/fees/adjustments');
await page.waitForTimeout(5000);
const { enableSemantics } = await import('./harness.mjs');
await enableSemantics(page);
console.log('headmaster at', page.url(), '|', (await texts(page)).filter(t => t.length < 60).slice(0, 8).join(' | '));
await shot(page, 'headmaster_queue');
await page.mouse.click(943, 412);  // Approve on the first request card
await page.waitForTimeout(1500);
await enableSemantics(page);
const reason = page.locator('input, textarea').last();
await reason.click(); await reason.fill('Approved sibling discount');
await shot(page, 'headmaster_dialog');
await page.getByRole('button', { name: /^Approve$/ }).last().click();
await page.waitForTimeout(3000);
await shot(page, 'headmaster_approved');
await browser.close();
const after = await (await fetch(`${API}/schools/${sid}/fees/invoices/${inv.id}`, { headers: H(hm) })).json();
console.log('invoice after approval: amount', after.amount, 'balance', after.balance, '(was 500)');

// 3. Photos are private
const png = Buffer.from('89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000d49444154789c63000100000500010d0a2db40000000049454e44ae426082', 'hex');
const form = new FormData();
form.append('folder', 'avatars');
form.append('file', new Blob([png], { type: 'image/png' }), 'logo.png');
const up = await (await fetch(`${API}/schools/${sid}/uploads`, { method: 'POST', headers: { authorization: `Bearer ${hm}` }, body: form })).json();
const mediaUrl = up.url.startsWith('http') ? up.url : `http://127.0.0.1:8000${up.url}`;
console.log('photo without sign-in:', (await fetch(mediaUrl)).status);
console.log('photo as accountant (same school):', (await fetch(mediaUrl, { headers: { authorization: `Bearer ${acct}` } })).status);
