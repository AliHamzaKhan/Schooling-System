import { open, boot, login, texts, shot, OUT } from './harness.mjs';
const roles = [['teacher', 'teacher@chromeschool.edu', 'Passw0rd1'], ['student', 'student@chromeschool.edu', 'Passw0rd1'], ['guardian', 'guardian@chromeschool.edu', 'Passw0rd1'], ['driver', 'driver@chromeschool.edu', 'Passw0rd1'], ['headmaster', 'head@chromeschool.edu', 'HeadPass123']];
const [w, h] = (process.env.SIZE || '390x844').split('x').map(Number);
for (const [role, email, pw] of roles) {
  const { browser, context, page, logs } = await open('school_portal', { width: w, height: h });
  const bad = [];
  page.on('response', r => { if (r.url().includes(':8000/') && r.status() >= 400) bad.push(`${r.status()} ${r.request().method()} ${r.url().replace(/.*\/api\/v1/, '').replace(/[0-9a-f-]{36}/g, ':id')}`); });
  await boot(page, 'http://localhost:8081/');
  await login(page, email, pw);
  await page.waitForTimeout(3000);
  await shot(page, `role_${role}_${w}`);
  await context.storageState({ path: `${OUT}/${role}_state.json` });
  console.log(`== ${role} ${page.url()}`);
  console.log('  ', (await texts(page)).filter(t => t.length < 80).slice(0, 14).join(' | '));
  if (bad.length) console.log('   API errors:', [...new Set(bad)].join('; '));
  if (logs.length) console.log('   console:', logs.slice(0, 3).join(' || ').slice(0, 300));
  await browser.close();
}
