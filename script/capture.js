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
// Printed size is (css px x 0.75 x scale), and scale is fixed by the sheet width
// (see below). At 1.0 the body text lands at ~6.4pt. This is a ceiling: it steps
// down until the content fits CAPTURE_PAGES sheets (1.59 -> ~10.3pt on 2 today).
const FONT_SCALE = Number(process.env.CAPTURE_FONT_SCALE || 1.6);
// Same limits as the ATS copy (script/check_docx_fonts.py): <= 2 sheets, >= 10pt.
const PAGES = Number(process.env.CAPTURE_PAGES || 2);
const MIN_PT = Number(process.env.CAPTURE_MIN_PT || 10);
// Selectors omitted from the print artifacts only, e.g. '.projects-section'.
const HIDE = process.env.CAPTURE_HIDE ?? '';
const PX_PER_IN = 96;
const PAGE_W_IN = 8.5;
const PAGE_H_IN = 11;

(async () => {
  const browser = await puppeteer.launch({ args: ['--no-sandbox', '--disable-gpu'] });
  const page = await browser.newPage();
  // styles-1-compact.css puts `page-break-before: always` on .main-wrapper and
  // positions the sidebar absolutely, so print media paginates badly. Capture
  // the screen layout instead and scale it to the sheet width.
  await page.emulateMediaType('screen');

  // Chrome evaluates the theme's 768px breakpoint against the unscaled printable
  // width, so wider side margins collapse the sidebar above the main column.
  // Pin the margins and fit the page count by shrinking the type instead.
  const scale = ((PAGE_W_IN - 2 * MARGIN_IN) * PX_PER_IN) / LAYOUT_WIDTH;
  if ((PAGE_W_IN - 2 * MARGIN_IN) * PX_PER_IN < 768) {
    console.log(`WARNING: CAPTURE_MARGIN ${MARGIN_IN}in leaves under 768px; the sidebar will collapse`);
  }

  let fontScale = FONT_SCALE;
  let layout;
  let sheets;
  let marginY;
  for (;;) {
    layout = await layOut(page, fontScale);
    marginY = PAGES === 1
      ? Math.max(MARGIN_IN, (PAGE_H_IN - (layout.height * scale) / PX_PER_IN) / 2)
      : MARGIN_IN;
    const pdf = await page.pdf({
      path: `/out/${OUT}.pdf`,
      printBackground: true,
      format: 'Letter',
      scale,
      margin: { top: `${marginY}in`, right: `${MARGIN_IN}in`, bottom: `${marginY}in`, left: `${MARGIN_IN}in` },
    });
    sheets = (Buffer.from(pdf).toString('latin1').match(/\/Type\s*\/Page(?![s\w])/g) || []).length;
    if (sheets <= PAGES || fontScale <= 1) break;
    fontScale = Math.max(1, Math.round((fontScale - 0.01) * 100) / 100);
  }
  console.log(`content: ${LAYOUT_WIDTH}x${layout.height} at font-scale ${fontScale}`);

  if (!SKIP_PNG) {
    await page.screenshot({ path: `/out/${OUT}.png`, fullPage: true });
  }

  const bodyPt = layout.bodyPx * 0.75 * scale;
  console.log(
    `${OUT}: scale ${scale.toFixed(3)}  margins ${MARGIN_IN.toFixed(2)}x${marginY.toFixed(2)}in  ` +
      `${sheets} sheet(s) (max ${PAGES})`,
  );
  console.log(
    `${OUT}: body ${layout.bodyPx}px x ${fontScale} font-scale -> ${bodyPt.toFixed(2)}pt printed` +
      (bodyPt < MIN_PT - 0.05 ? `  [WARNING: under ${MIN_PT}pt]` : '') +
      (sheets > PAGES ? `  [WARNING: over ${PAGES} sheet(s)]` : ''),
  );

  await browser.close();
})();

async function layOut(page, fontScale) {
  // Short viewport so scrollHeight reports real content height, not the viewport.
  await page.setViewport({ width: LAYOUT_WIDTH, height: 600, deviceScaleFactor: 2 });
  await page.goto(URL, { waitUntil: 'networkidle0' });
  await page.addStyleTag({
    content:
      `.wrapper{max-width:none !important;width:${LAYOUT_WIDTH}px !important;}` +
      // The colour/B&W switch is navigation, not resume content.
      `.version-toggle{display:none !important;}` +
      // The sidebar is absolutely positioned with height:100%, so its coloured
      // panel is only as tall as the main column. Hiding a section or enlarging
      // the type leaves its content hanging past the panel as white text on
      // white. height:auto sizes the panel to its own content instead.
      `.sidebar-wrapper{height:auto !important;min-height:100% !important;padding-bottom:24px !important;}` +
      // The theme keeps every .section whole, but Experience is taller than a
      // sheet; break between jobs instead, and never straight after a heading.
      `.main-wrapper .section{break-inside:auto !important;}` +
      `.main-wrapper .item,.sidebar-wrapper .container-block{break-inside:avoid;}` +
      `.section-title,.job-title,.upper-row{break-after:avoid;}` +
      (HIDE ? `${HIDE}{display:none !important;}` : ''),
  });
  // Scale the computed size of every element, because the theme sets font sizes
  // in px on individual rules; there is no root em to scale.
  if (fontScale !== 1) {
    await page.evaluate((f) => {
      const els = [...document.querySelectorAll('body *')];
      const sizes = els.map((e) => parseFloat(getComputedStyle(e).fontSize));
      els.forEach((e, i) => {
        if (sizes[i]) e.style.fontSize = `${sizes[i] * f}px`;
      });
      // The sidebar is a fixed px width, so larger type would overflow it.
      const sb = document.querySelector('.sidebar-wrapper');
      const main = document.querySelector('.main-wrapper');
      if (sb && main) {
        const sbWidth = parseFloat(getComputedStyle(sb).width);
        const mainPad = parseFloat(getComputedStyle(main).paddingRight);
        sb.style.width = `${sbWidth * f}px`;
        main.style.paddingRight = `${mainPad + sbWidth * (f - 1)}px`;
      }
    }, fontScale);
  }
  // The sidebar is out of flow, so a sidebar taller than the main column would
  // not extend the document and would be cropped. Pad the main column to match.
  await page.evaluate(() => {
    const sb = document.querySelector('.sidebar-wrapper');
    const main = document.querySelector('.main-wrapper');
    if (!sb || !main) return;
    const panel = sb.getBoundingClientRect().height;
    if (panel > main.getBoundingClientRect().height) {
      main.style.minHeight = `${Math.ceil(panel)}px`;
    }
  });
  return page.evaluate(() => {
    document.body.offsetHeight; // force reflow after the injected style
    const counts = new Map();
    document.querySelectorAll('p, li, span, div, td').forEach((e) => {
      if (!e.textContent.trim() || e.offsetHeight === 0) return;
      const s = Math.round(parseFloat(getComputedStyle(e).fontSize) * 10) / 10;
      counts.set(s, (counts.get(s) || 0) + 1);
    });
    return {
      height: document.documentElement.scrollHeight,
      bodyPx: [...counts.entries()].sort((a, b) => b[1] - a[1])[0]?.[0] ?? 0,
    };
  });
}
