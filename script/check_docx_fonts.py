#!/usr/bin/env python3
"""Fail if the ATS copy of the resume would be illegible when printed.

Checks the body text size of the .docx (resolved through its style chain) and
of the .docx.pdf (read from the PDF text operators), plus the PDF page count.
Standard library only, so it runs anywhere check_artifacts.bash does.

Usage: check_docx_fonts.py <file.docx> <file.docx.pdf> [min-pt] [max-pages]
"""

import collections
import re
import sys
import zipfile
import zlib

W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
# pandoc writes paragraphs as FirstParagraph/BodyText and list items as Compact.
BODY_STYLES = ("BodyText", "FirstParagraph", "Compact")
# TeX points are 1/72.27in; PDF points are 1/72in, so 10pt text shows as 9.96.
TEX_TO_PDF_PT = 72 / 72.27


def docx_style_sizes(path: str) -> dict:
    import xml.etree.ElementTree as ET

    with zipfile.ZipFile(path) as z:
        root = ET.fromstring(z.read("word/styles.xml"))

    default = root.find(f"{W}docDefaults/{W}rPrDefault/{W}rPr/{W}sz")
    default_hp = int(default.get(f"{W}val")) if default is not None else 20
    styles = {}
    for s in root.iter(f"{W}style"):
        sz = s.find(f"{W}rPr/{W}sz")
        based = s.find(f"{W}basedOn")
        styles[s.get(f"{W}styleId")] = (
            int(sz.get(f"{W}val")) if sz is not None else None,
            based.get(f"{W}val") if based is not None else None,
        )

    def resolve(sid: str) -> int:
        seen = set()
        while sid in styles and sid not in seen:
            seen.add(sid)
            sz, based = styles[sid]
            if sz is not None:
                return sz
            sid = based
        return default_hp

    return {sid: resolve(sid) / 2 for sid in BODY_STYLES if sid in styles}


def pdf_streams(data: bytes):
    for m in re.finditer(rb"stream\r?\n", data):
        start = m.end()
        end = data.find(b"endstream", start)
        try:
            yield zlib.decompressobj().decompress(data[start:end])
        except zlib.error:
            continue


def pdf_text_sizes(path: str):
    """Return (page count, chars per font size) from Tf/Tj/TJ operators."""
    with open(path, "rb") as f:
        data = f.read()

    chunks = [data, *pdf_streams(data)]
    pages = sum(len(re.findall(rb"/Type\s*/Page(?![s\w])", c)) for c in chunks)

    sizes = collections.Counter()
    token = re.compile(rb"/[^\s/\[\]()<>]+\s+([\d.]+)\s+Tf|\((?:\\.|[^\\)])*\)")
    for c in chunks[1:]:
        size = None
        for m in token.finditer(c):
            if m.group(1) is not None:
                size = round(float(m.group(1)), 2)
            elif size is not None:
                sizes[size] += len(m.group(0)) - 2
    return pages, sizes


def main() -> int:
    if not 3 <= len(sys.argv) <= 5:
        print(__doc__, file=sys.stderr)
        return 2
    docx, pdf = sys.argv[1], sys.argv[2]
    min_pt = float(sys.argv[3]) if len(sys.argv) > 3 else 10.0
    max_pages = int(sys.argv[4]) if len(sys.argv) > 4 else 2
    rc = 0

    for sid, pt in docx_style_sizes(docx).items():
        ok = pt >= min_pt
        rc |= not ok
        print(f"{'ok' if ok else 'SMALL':8} docx {sid} {pt:g}pt (min {min_pt:g}pt)")

    pages, sizes = pdf_text_sizes(pdf)
    if not sizes:
        print(f"UNKNOWN  pdf has no readable text operators: {pdf}", file=sys.stderr)
        return 1
    body_pdf_pt = sizes.most_common(1)[0][0]
    body_pt = body_pdf_pt / TEX_TO_PDF_PT
    ok = body_pt >= min_pt - 0.05
    rc |= not ok
    print(f"{'ok' if ok else 'SMALL':8} pdf body {body_pt:.1f}pt (min {min_pt:g}pt)")
    ok = 0 < pages <= max_pages
    rc |= not ok
    print(f"{'ok' if ok else 'PAGES':8} pdf {pages} page(s) (max {max_pages})")

    if rc:
        print("error: ATS copy fails the print legibility check", file=sys.stderr)
    return rc


if __name__ == "__main__":
    sys.exit(main())
