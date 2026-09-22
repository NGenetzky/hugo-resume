// Regenerates static/nathan-genetzky-resume.{png,pdf} from the live Hugo site.
// Run via script/build_capture.bash.
const puppeteer = require('puppeteer');

const URL = process.env.CAPTURE_URL || 'http://localhost:1313/';
// Must stay above the theme's ~1200px sidebar breakpoint; smaller = larger print.
const LAYOUT_WIDTH = Number(process.env.CAPTURE_WIDTH || 1250);
const PX_PER_IN = 96;
const PAGE_W_IN = 8.5;
const PAGE_H_IN = 11;

(async () => {
  const browser = await puppeteer.launch({ args: ['--no-sandbox', '--disable-gpu'] });
  const page = await browser.newPage();
  // The theme's print stylesheet drops the sidebar and body; keep the screen layout.
  await page.emulateMediaType('screen');

  // Short viewport so scrollHeight reports real content height, not the viewport.
  await page.setViewport({ width: LAYOUT_WIDTH, height: 600, deviceScaleFactor: 2 });
  await page.goto(URL, { waitUntil: 'networkidle0' });
  const height = await page.evaluate(() => document.documentElement.scrollHeight);
  console.log(`content: ${LAYOUT_WIDTH}x${height}`);

  await page.screenshot({ path: '/out/nathan-genetzky-resume.png', fullPage: true });

  const scale = Math.min(
    (PAGE_W_IN * PX_PER_IN) / LAYOUT_WIDTH,
    (PAGE_H_IN * PX_PER_IN) / height,
  );
  await page.pdf({
    path: '/out/nathan-genetzky-resume.pdf',
    printBackground: true,
    format: 'Letter',
    scale,
    margin: { top: 0, right: 0, bottom: 0, left: 0 },
    pageRanges: '1',
  });
  console.log(`scale: ${scale.toFixed(3)} (layout width ${(PAGE_W_IN * PX_PER_IN) / scale | 0}px)`);

  await browser.close();
})();
