// Regenerates static/nathan-genetzky-resume.{png,pdf} from the live Hugo site.
// Run via script/build_capture.bash.
const puppeteer = require('puppeteer');

const URL = process.env.CAPTURE_URL || 'http://localhost:1313/';
const OUT = process.env.CAPTURE_OUT || 'nathan-genetzky-resume';
const SKIP_PNG = process.env.CAPTURE_SKIP_PNG === '1';
// The theme hard-caps .wrapper at 960px. Left alone, the resume would occupy
// only ~5.6in of the sheet and have to shrink to ~56% to fit the height.
// Widening it to 1250px makes the content aspect (0.78) match Letter (0.77),
// so it fills the page at a much larger, more readable scale.
const LAYOUT_WIDTH = Number(process.env.CAPTURE_WIDTH || 1250);
// Keep clear of the non-printable edge on most printers.
const MARGIN_IN = Number(process.env.CAPTURE_MARGIN || 0.25);
const PX_PER_IN = 96;
const PAGE_W_IN = 8.5;
const PAGE_H_IN = 11;

(async () => {
  const browser = await puppeteer.launch({ args: ['--no-sandbox', '--disable-gpu'] });
  const page = await browser.newPage();
  // styles-1-compact.css puts `page-break-before: always` on .main-wrapper and
  // positions the sidebar absolutely, so print media paginates badly. Capture
  // the screen layout instead and scale it to one sheet.
  await page.emulateMediaType('screen');

  // Short viewport so scrollHeight reports real content height, not the viewport.
  await page.setViewport({ width: LAYOUT_WIDTH, height: 600, deviceScaleFactor: 2 });
  await page.goto(URL, { waitUntil: 'networkidle0' });
  await page.addStyleTag({
    content:
      `.wrapper{max-width:none !important;width:${LAYOUT_WIDTH}px !important;}` +
      // The colour/B&W switch is navigation, not resume content.
      `.version-toggle{display:none !important;}`,
  });
  const height = await page.evaluate(() => {
    document.body.offsetHeight; // force reflow after the injected style
    return document.documentElement.scrollHeight;
  });
  console.log(`content: ${LAYOUT_WIDTH}x${height} (aspect ${(LAYOUT_WIDTH / height).toFixed(3)})`);

  if (!SKIP_PNG) {
    await page.screenshot({ path: `/out/${OUT}.png`, fullPage: true });
  }

  const scale = Math.min(
    ((PAGE_W_IN - 2 * MARGIN_IN) * PX_PER_IN) / LAYOUT_WIDTH,
    ((PAGE_H_IN - 2 * MARGIN_IN) * PX_PER_IN) / height,
  );

  // Chrome lays a page out at (paperWidth - margins) / scale CSS pixels. Without
  // margins that width would not equal LAYOUT_WIDTH, so the content would reflow
  // to a different width than the one `height` was measured at. Pad the sheet so
  // the layout width matches exactly and the content stays centred.
  const marginX = Math.max(0, (PAGE_W_IN - (LAYOUT_WIDTH * scale) / PX_PER_IN) / 2);
  const marginY = Math.max(0, (PAGE_H_IN - (height * scale) / PX_PER_IN) / 2);

  await page.pdf({
    path: `/out/${OUT}.pdf`,
    printBackground: true,
    format: 'Letter',
    scale,
    margin: {
      top: marginY + 'in',
      right: marginX + 'in',
      bottom: marginY + 'in',
      left: marginX + 'in',
    },
    pageRanges: '1',
  });

  const effectiveWidth = ((PAGE_W_IN - 2 * marginX) * PX_PER_IN) / scale;
  const fill = (((PAGE_W_IN - 2 * marginX) * (PAGE_H_IN - 2 * marginY)) / (PAGE_W_IN * PAGE_H_IN)) * 100;
  console.log(
    `${OUT}: scale ${scale.toFixed(3)}  margins ${marginX.toFixed(2)}x${marginY.toFixed(2)}in  ` +
      `page fill ${fill.toFixed(0)}%  ` +
      `effective layout width ${effectiveWidth.toFixed(0)}px (want ${LAYOUT_WIDTH})`,
  );

  await browser.close();
})();
