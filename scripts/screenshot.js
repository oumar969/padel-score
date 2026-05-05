const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const W = 390, H = 844;
const BASE = 'http://localhost:5050';
const OUT = path.join(__dirname, '..', 'screenshots');

const sleep = ms => new Promise(r => setTimeout(r, ms));

async function shot(page, name) {
  if (!fs.existsSync(OUT)) fs.mkdirSync(OUT, { recursive: true });
  await page.screenshot({ path: path.join(OUT, `${name}.png`) });
  console.log(`✓ ${name}.png`);
}

async function tap(page, x, y, wait = 700) {
  await page.mouse.click(x, y);
  await sleep(wait);
}

(async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu'],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: W, height: H, deviceScaleFactor: 2 });

  // ── 1. Home — Kampe tab ─────────────────────────────────────────────
  console.log('Home screen...');
  await page.goto(BASE, { waitUntil: 'load', timeout: 40000 });
  await sleep(4000);
  await tap(page, 97, 815, 600); // Kampe tab
  await shot(page, '01_home');

  // ── 2. Statistik tab ────────────────────────────────────────────────
  console.log('Stats screen...');
  await tap(page, 293, 815, 1000);
  await shot(page, '02_stats');

  // ── 3. Ny kamp skærm — direkte URL ──────────────────────────────────
  console.log('New match screen...');
  await page.goto(`${BASE}/new`, { waitUntil: 'load', timeout: 20000 });
  await sleep(2500);
  await shot(page, '03_new_match');

  // ── 4. Klik på en kamp fra home for at åbne score ───────────────────
  console.log('Clicking first match card...');
  await page.goto(BASE, { waitUntil: 'load', timeout: 20000 });
  await sleep(3000);
  await tap(page, 97, 815, 600);  // Kampe tab
  await tap(page, 195, 320, 3000); // Første kort i listen
  await shot(page, '04_score_start');

  // ── 5. Giv points ───────────────────────────────────────────────────
  console.log('Scoring points...');
  await tap(page, 90, 400);
  await tap(page, 90, 400);
  await tap(page, 90, 400);
  await tap(page, 295, 400);
  await tap(page, 295, 400);
  await tap(page, 295, 400);
  await tap(page, 90, 400);
  await shot(page, '05_score_40_30');

  // ── 6. Vindscore ────────────────────────────────────────────────────
  await tap(page, 90, 400);
  await sleep(500);
  for (let i = 0; i < 3; i++) {
    for (let p = 0; p < 4; p++) { await tap(page, 90, 400, 120); }
    await sleep(300);
  }
  for (let i = 0; i < 2; i++) {
    for (let p = 0; p < 4; p++) { await tap(page, 295, 400, 120); }
    await sleep(300);
  }
  await shot(page, '06_set_score');

  await browser.close();
  console.log('\nFærdig!');
})().catch(err => {
  console.error('Fejl:', err.message);
  process.exit(1);
});
