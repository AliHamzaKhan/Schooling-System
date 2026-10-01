import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
// Output (screenshots, results, storage state) goes to E2E_OUT or the cwd.
export const OUT = process.env.E2E_OUT || process.cwd();
// Roboto from npm `@fontsource/roboto` (see README): gstatic may be unreachable.
const FONT = process.env.E2E_FONT || `${OUT}/package/files/roboto-latin-400-normal.woff2`;

export async function open(portal, { width = 1366, height = 860, reducedMotion = 'no-preference', storage } = {}) {
  const buildDir = new URL(`../../${portal}/build/web`, import.meta.url).pathname;
  const browser = await chromium.launch({ proxy: { server: process.env.HTTPS_PROXY, bypass: '<-loopback>,localhost,127.0.0.1' } });
  const context = await browser.newContext({ viewport: { width, height }, reducedMotion, storageState: storage, locale: process.env.PW_LOCALE || 'en-US' });
  // gstatic is blocked by network policy: serve CanvasKit from the build and Roboto from @fontsource.
  await context.route('https://www.gstatic.com/flutter-canvaskit/**', route => {
    const rel = new URL(route.request().url()).pathname.split('/').slice(3).join('/');
    const file = path.join(buildDir, 'canvaskit', rel);
    if (!fs.existsSync(file)) return route.fulfill({ status: 404 });
    route.fulfill({ body: fs.readFileSync(file), contentType: file.endsWith('.wasm') ? 'application/wasm' : 'text/javascript' });
  });
  await context.route('https://fonts.gstatic.com/**', route => route.fulfill({ body: fs.readFileSync(FONT), contentType: 'font/woff2' }));
  await context.route(/google-analytics|googletagmanager/, route => route.abort());
  const page = await context.newPage();
  const logs = [];
  page.on('console', m => { if (m.type() === 'error' || m.text().includes('TEMPDEBUG')) logs.push(m.text()); });
  page.on('pageerror', e => logs.push('pageerror: ' + e.message + '\n' + (e.stack||'').slice(0,1500)));
  return { browser, context, page, logs };
}

export async function boot(page, url, wait = 5000) {
  await page.goto(url);
  await page.waitForSelector('flt-glass-pane, flutter-view', { timeout: 30000, state: 'attached' });
  await page.waitForTimeout(wait);
  await enableSemantics(page);
}

export async function enableSemantics(page) {
  await page.evaluate(() => {
    const ph = document.querySelector('flt-semantics-placeholder');
    if (ph) ph.click();
  });
  await page.waitForTimeout(800);
}

export async function texts(page) {
  return page.$$eval('flt-semantics', els => [...new Set(els.map(e => (e.getAttribute('aria-label') || e.textContent || '').trim()).filter(Boolean))]);
}

export async function fill(page, label, value) {
  const input = page.locator(`input[aria-label*="${label}"], textarea[aria-label*="${label}"]`).first();
  if (await input.count()) { await input.click(); await input.fill(value); return; }
  const field = page.getByRole('textbox', { name: new RegExp(label, 'i') }).first();
  await field.click();
  await page.keyboard.press('Control+A');
  await page.keyboard.type(value);
}

export async function click(page, name) {
  const target = page.getByRole('button', { name: new RegExp(name, 'i') }).first();
  if (await target.count()) return target.click();
  return page.getByText(new RegExp(name, 'i')).first().click();
}

export async function shot(page, name) {
  fs.mkdirSync(`${OUT}/shots`, { recursive: true });
  await page.screenshot({ path: `${OUT}/shots/${name}.png` });
}

export async function login(page, email, password) {
  const user = page.locator('input[type="text"], input[type="email"]').first();
  await user.click(); await user.fill(email);
  const pass = page.locator('input[type="password"]').first();
  await pass.click(); await pass.fill(password);
  await page.keyboard.press('Enter');
  await page.waitForTimeout(5000);
  await enableSemantics(page);
}
