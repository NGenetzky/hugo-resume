#!/usr/bin/env python3
"""Patch pandoc's default reference.docx margins, body font and body size.

Word defaults to 1in margins, which wastes space on a dense resume, and pandoc's
reference sets 12pt Cambria. Pandoc has no command-line option for either, so
they have to be edited inside the reference document it copies styles from.

Usage: make_reference_docx.py <input.docx> <output.docx> <margin-inches> [body-pt]
"""

import re
import sys
import zipfile

TWIPS_PER_INCH = 1440
LETTER = '<w:pgSz w:w="12240" w:h="15840"/>'
BODY_FONT = "Calibri"


def patch_margins(xml: bytes, twips: int) -> bytes:
    text = xml.decode("utf-8")
    pg_mar = (
        f'<w:pgMar w:top="{twips}" w:right="{twips}" w:bottom="{twips}" '
        f'w:left="{twips}" w:header="720" w:footer="720" w:gutter="0"/>'
    )

    if "<w:pgMar" in text:
        def set_attrs(match: "re.Match[str]") -> str:
            tag = match.group(0)
            for attr in ("top", "right", "bottom", "left"):
                tag = re.sub(rf'w:{attr}="\d+"', f'w:{attr}="{twips}"', tag)
            return tag

        patched, count = re.subn(r"<w:pgMar[^>]*/>", set_attrs, text)
    else:
        # pandoc's reference.docx ships an empty <w:sectPr />, relying on Word's
        # implicit 1in defaults, so the geometry has to be inserted.
        patched, count = re.subn(
            r"<w:sectPr\s*/>", f"<w:sectPr>{LETTER}{pg_mar}</w:sectPr>", text
        )
        if count == 0:
            patched, count = re.subn(
                r"<w:sectPr(\s[^>]*)?>", lambda m: m.group(0) + pg_mar, text, count=1
            )

    if count == 0:
        raise SystemExit("error: no <w:pgMar> or <w:sectPr> found in word/document.xml")
    return patched.encode("utf-8")


def patch_body_font(xml: bytes, body_pt: float) -> bytes:
    """Set the document default run font and size, which all body styles inherit."""
    text = xml.decode("utf-8")
    match = re.search(r"<w:rPrDefault>.*?</w:rPrDefault>", text, re.S)
    if match is None:
        raise SystemExit("error: no <w:rPrDefault> found in word/styles.xml")

    half_points = round(body_pt * 2)
    fonts = (
        f'<w:rFonts w:ascii="{BODY_FONT}" w:hAnsi="{BODY_FONT}" '
        f'w:eastAsia="{BODY_FONT}" w:cs="{BODY_FONT}" />'
    )
    block = re.sub(r"<w:rFonts[^>]*/>", fonts, match.group(0))
    block = re.sub(r'<w:sz w:val="\d+"\s*/>', f'<w:sz w:val="{half_points}" />', block)
    block = re.sub(r'<w:szCs w:val="\d+"\s*/>', f'<w:szCs w:val="{half_points}" />', block)
    if f'w:val="{half_points}"' not in block or BODY_FONT not in block:
        raise SystemExit("error: could not set the default font in word/styles.xml")
    return (text[: match.start()] + block + text[match.end() :]).encode("utf-8")


def main() -> None:
    if len(sys.argv) not in (4, 5):
        raise SystemExit(__doc__)
    src, dst, margin_in = sys.argv[1], sys.argv[2], float(sys.argv[3])
    body_pt = float(sys.argv[4]) if len(sys.argv) == 5 else None
    twips = round(margin_in * TWIPS_PER_INCH)

    with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == "word/document.xml":
                data = patch_margins(data, twips)
            elif item.filename == "word/styles.xml" and body_pt is not None:
                data = patch_body_font(data, body_pt)
            zout.writestr(item, data)

    body = f", {body_pt:g}pt {BODY_FONT} body" if body_pt is not None else ""
    print(f"wrote {dst} with {margin_in}in margins ({twips} twips){body}")


if __name__ == "__main__":
    main()
