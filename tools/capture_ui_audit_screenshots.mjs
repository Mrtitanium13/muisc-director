/**
 * Capture UI/UX audit screenshots of Music Director (Flutter web)
 * at desktop and mobile viewports.
 *
 * Usage (from tools/):
 *   npm run capture-ui-audit
 *   BASE_URL=http://127.0.0.1:5173 npm run capture-ui-audit
 */
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const OUT = path.join(ROOT, 'docs', 'ui_audit_screenshots');
const BASE = process.env.BASE_URL || 'http://127.0.0.1:5173';

const PAGES = [
  { slug: '01-splash', route: '/splash', settleMs: 600 },
  { slug: '02-onboarding', route: '/onboarding', settleMs: 1200, onboardingSlides: 3 },
  { slug: '03-login', route: '/login', settleMs: 1200 },
  { slug: '04-generate', route: '/generate', settleMs: 2500, scrollPasses: 6, scrollAnchors: [
    'PRIMARY GENRE',
    'GENRE FX',
    'VIBE',
    'BPM',
    'LYRICS',
    'HUMAN',
  ] },
  { slug: '05-analyzer', route: '/analyzer', settleMs: 1500 },
  { slug: '06-history', route: '/history', settleMs: 1500 },
  { slug: '07-settings', route: '/settings', settleMs: 1500, scrollPasses: 2 },
  { slug: '08-templates', route: '/templates', settleMs: 1500, scrollPasses: 1 },
  { slug: '09-batch-generate', route: '/batch-generate', settleMs: 1500 },
  { slug: '10-ab-compare', route: '/ab-compare', settleMs: 1500 },
  { slug: '11-quick-describe', route: '/quick-describe', settleMs: 1500 },
  { slug: '12-artifact-create', route: '/artifact/create', settleMs: 1800, scrollPasses: 2 },
  { slug: '13-artifact-fix-it', route: '/artifact/fix-it', settleMs: 1500 },
  { slug: '14-artifact-verified', route: '/artifact/verified', settleMs: 1500 },
  { slug: '15-output', route: '/output', settleMs: 1500 },
];

const VIEWPORTS = [
  { name: 'web', width: 1440, height: 900, isMobile: false, deviceScaleFactor: 1 },
  { name: 'mobile', width: 390, height: 844, isMobile: true, deviceScaleFactor: 2 },
];

function ensureDirs() {
  for (const vp of VIEWPORTS) {
    fs.mkdirSync(path.join(OUT, vp.name), { recursive: true });
  }
}

async function enableFlutterA11y(page) {
  await page
    .evaluate(() => {
      const btn =
        document.querySelector('flt-semantics-placeholder') ||
        [...document.querySelectorAll('button, [role="button"]')].find((b) =>
          (b.textContent || '').includes('Enable accessibility'),
        );
      if (btn) btn.click();
    })
    .catch(() => {});
  await page.waitForTimeout(500);
}

async function scrollToLabel(page, label) {
  const candidates = [
    page.getByText(label, { exact: false }),
    page.getByRole('button', { name: new RegExp(label, 'i') }),
  ];
  for (const loc of candidates) {
    try {
      if (await loc.count()) {
        await loc.first().scrollIntoViewIfNeeded({ timeout: 3000 });
        await page.waitForTimeout(500);
        return true;
      }
    } catch {
      /* try next */
    }
  }
  return false;
}

async function flutterDragScroll(page, deltaY = 520) {
  // Prefer touch swipe on mobile contexts; mouse drag otherwise.
  const vp = page.viewportSize();
  const x = Math.floor((vp?.width || 390) * 0.5);
  const startY = Math.floor((vp?.height || 800) * 0.75);
  const endY = Math.max(60, startY - deltaY);

  try {
    await page.touchscreen.swipe?.(x, startY, x, endY);
  } catch {
    /* swipe may not exist */
  }

  await page.mouse.move(x, startY);
  await page.mouse.down();
  await page.mouse.move(x, endY, { steps: 24 });
  await page.mouse.up();

  // Also dispatch wheel over Flutter view
  const handle = await page.$('flt-glass-pane, flutter-view');
  if (handle) {
    const box = await handle.boundingBox();
    if (box) {
      await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
      await page.mouse.wheel(0, deltaY);
    }
  }
  await page.waitForTimeout(600);
}

async function clickByName(page, name) {
  // Flutter a11y tree exposes buttons as role=button with accessible name
  const locators = [
    page.getByRole('button', { name, exact: true }),
    page.getByText(name, { exact: true }),
  ];
  for (const loc of locators) {
    try {
      if (await loc.count()) {
        await loc.first().click({ timeout: 2500 });
        await page.waitForTimeout(700);
        return true;
      }
    } catch {
      /* try next */
    }
  }
  return false;
}

async function shot(page, filePath) {
  await page.screenshot({ path: filePath, type: 'png' });
  console.log(`  saved ${path.relative(OUT, filePath).replace(/\\/g, '/')}`);
}

async function capturePage(page, vp, entry) {
  const url = `${BASE}/#${entry.route}`;
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(entry.settleMs || 1500);
  await enableFlutterA11y(page);
  await page.waitForTimeout(350);

  const dir = path.join(OUT, vp.name);
  await shot(page, path.join(dir, `${entry.slug}.png`));

  // Onboarding: advance slides
  if (entry.onboardingSlides && entry.onboardingSlides > 1) {
    for (let i = 2; i <= entry.onboardingSlides; i++) {
      const clicked = await clickByName(page, 'Continue');
      if (!clicked) break;
      await shot(page, path.join(dir, `${entry.slug}-slide-${i}.png`));
    }
  }

  // Scroll captures via drag + semantic scroll-into-view anchors
  const passes = entry.scrollPasses || 0;
  const anchors = entry.scrollAnchors || [];
  for (let i = 0; i < anchors.length; i++) {
    await scrollToLabel(page, anchors[i]);
    await flutterDragScroll(page, vp.isMobile ? 200 : 240);
    await shot(page, path.join(dir, `${entry.slug}-scroll-${i + 1}.png`));
  }
  for (let i = anchors.length + 1; i <= passes; i++) {
    await flutterDragScroll(page, vp.isMobile ? 480 : 560);
    await shot(page, path.join(dir, `${entry.slug}-scroll-${i}.png`));
  }
}

async function main() {
  ensureDirs();
  // Remove stale MCP leftover
  const stale = path.join(OUT, 'web', '01-generate.png');
  if (fs.existsSync(stale)) fs.unlinkSync(stale);

  console.log(`Base URL: ${BASE}`);
  console.log(`Output:   ${OUT}`);

  const browser = await chromium.launch({ headless: true });
  try {
    for (const vp of VIEWPORTS) {
      console.log(`\n=== ${vp.name} (${vp.width}x${vp.height}) ===`);
      const context = await browser.newContext({
        viewport: { width: vp.width, height: vp.height },
        deviceScaleFactor: vp.deviceScaleFactor,
        isMobile: vp.isMobile,
        hasTouch: vp.isMobile,
      });
      const page = await context.newPage();

      await page
        .goto(`${BASE}/#/generate`, { waitUntil: 'networkidle', timeout: 90000 })
        .catch(async () => {
          await page.goto(`${BASE}/#/generate`, {
            waitUntil: 'domcontentloaded',
            timeout: 90000,
          });
        });
      await page.waitForTimeout(2800);
      await enableFlutterA11y(page);

      for (const entry of PAGES) {
        try {
          await capturePage(page, vp, entry);
        } catch (err) {
          console.error(`  FAIL ${vp.name}/${entry.slug}: ${err.message}`);
        }
      }

      await context.close();
    }
  } finally {
    await browser.close();
  }

  const webFiles = fs
    .readdirSync(path.join(OUT, 'web'))
    .filter((f) => f.endsWith('.png'))
    .sort();
  const mobileFiles = fs
    .readdirSync(path.join(OUT, 'mobile'))
    .filter((f) => f.endsWith('.png'))
    .sort();
  const index = [
    '# UI/UX Audit Screenshots',
    '',
    `Captured: ${new Date().toISOString()}`,
    `App: ${BASE}`,
    '',
    '## Viewports',
    '- **web**: 1440×900 (desktop browser)',
    '- **mobile**: 390×844 @2x (iPhone-class)',
    '',
    '## Important pages',
    ...PAGES.map((p) => `- \`${p.route}\` → \`${p.slug}.png\``),
    '',
    '## Notes',
    '- Flutter web paints to a canvas; long pages use drag-scroll captures (`*-scroll-N.png`).',
    '- Onboarding multi-step slides are saved as `02-onboarding-slide-N.png`.',
    '- Desktop layout currently follows a mobile-first column (large side margins at 1440px).',
    '',
    `## Web files (${webFiles.length})`,
    ...webFiles.map((f) => `- \`web/${f}\``),
    '',
    `## Mobile files (${mobileFiles.length})`,
    ...mobileFiles.map((f) => `- \`mobile/${f}\``),
    '',
  ].join('\n');
  fs.writeFileSync(path.join(OUT, 'README.md'), index, 'utf8');
  console.log(`\nDone. Index: ${path.join(OUT, 'README.md')}`);
  console.log(`Web: ${webFiles.length} | Mobile: ${mobileFiles.length}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
