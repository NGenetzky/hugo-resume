#!/usr/bin/env python3
"""Patch pandoc's default reference.docx to use narrower page margins.

Word defaults to 1in margins, which wastes space on a dense resume. Pandoc has
no command-line option for this, so the page geometry has to be edited inside
the reference document that pandoc copies styles from.

Usage: make_reference_docx.py <input.docx> <output.docx> <margin-inches>
"""

import re
import sys
import zipfile

TWIPS_PER_INCH = 1440
LETTER = '<w:pgSz w:w="12240" w:h="15840"/>'


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


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    src, dst, margin_in = sys.argv[1], sys.argv[2], float(sys.argv[3])
    twips = round(margin_in * TWIPS_PER_INCH)

    with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == "word/document.xml":
                data = patch_margins(data, twips)
            zout.writestr(item, data)

    print(f"wrote {dst} with {margin_in}in margins ({twips} twips)")


if __name__ == "__main__":
    main()
