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

  // ── 1. Home screen ───────────────────────────────────────────────────
  console.log('Loading app...');
  await page.goto(BASE, { waitUntil: 'load', timeout: 40000 });
  await sleep(4000);
  await shot(page, '01_home');

  // ── 2. New match screen ──────────────────────────────────────────────
  // FAB "Ny kamp" — bottom right
  await tap(page, 308, 800, 1500);
  await shot(page, '02_new_match');

  // ── 3. Fill in team names ────────────────────────────────────────────
  // Team 1 input
  await tap(page, 195, 152, 400);
  await page.keyboard.down('Control');
  await page.keyboard.press('a');
  await page.keyboard.up('Control');
  await page.keyboard.type('FC Padel');
  await sleep(200);

  // Team 2 input
  await tap(page, 195, 298, 400);
  await page.keyboard.down('Control');
  await page.keyboard.press('a');
  await page.keyboard.up('Control');
  await page.keyboard.type('Team Smash');
  await sleep(200);

  await shot(page, '03_new_match_filled');

  // ── 4. Start match ───────────────────────────────────────────────────
  await tap(page, 195, 807, 6000); // Wait for Firestore
  await shot(page, '04_score_start');

  // ── 5. Add points: 30 - 15 ──────────────────────────────────────────
  await tap(page, 90, 428);  // T1 point
  await tap(page, 90, 428);  // T1 → 30
  await tap(page, 295, 428); // T2 point → 15
  await shot(page, '05_score_30_15');

  // ── 6. 40 - 30 ──────────────────────────────────────────────────────
  await tap(page, 90, 428);  // T1 → 40
  await tap(page, 295, 428); // T2 → 30
  await shot(page, '06_score_40_30');

  // ── 7. Win a game then build set score ──────────────────────────────
  await tap(page, 90, 428);  // T1 wins game → 1-0
  await sleep(600);

  // Quickly win more games for T1: 4-0
  for (let i = 0; i < 3; i++) {
    for (let p = 0; p < 4; p++) { await tap(page, 90, 428, 150); }
    await sleep(400);
  }
  // T2 wins 2 games: 4-2
  for (let i = 0; i < 2; i++) {
    for (let p = 0; p < 4; p++) { await tap(page, 295, 428, 150); }
    await sleep(400);
  }
  await shot(page, '07_set_score_4_2');

  await browser.close();
  console.log('\nAlle screenshots gemt i /screenshots/');
})().catch(err => {
  console.error('Fejl:', err.message);
  process.exit(1);
});
