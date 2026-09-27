# ATS requirements for the resume

Applicant tracking systems (ATS) turn a resume into structured fields (name,
contact details, jobs, dates, skills) and a keyword index that recruiters
search. This document lists what that parsing needs, how confident each rule is,
and how this repo meets it.

**Which file to submit:** `nathan-genetzky-resume.docx`, or its
`.docx.pdf` where a PDF is required. The colour and B&W PDFs and the PNG are
captures of the two-column website: a parser reads their sidebar and main
column interleaved line by line, so never submit those to an ATS.

The captures deliberately keep the sidebar; they are for people. They still
follow the ATS copy's content and print limits: every section, at most 2
sheets, body text of 10pt or more. [capture.js](../script/capture.js) shrinks
the type to fit the sheet limit and warns if that takes it under 10pt.

## Confidence levels

- **Established:** widely documented in ATS vendor and recruiter guidance, and
  explained by how text extraction works. Treat these as requirements.
- **Likely:** common guidance with a plausible mechanism, but parsers differ.
  It costs nothing to comply.
- **Folklore:** repeated often, but not how parsers behave. Listed so it does
  not drive changes.

## Established

| Requirement | Why | How this repo meets it |
|---|---|---|
| Single column, no tables or text boxes | Extraction follows reading order; columns and boxes scramble it | Pandoc writes a flat docx. `DOCX_TWOCOLUMN` defaults off and is documented as unsafe in [build_docx.bash](../script/build_docx.bash) |
| Real text, not images | Images carry no text to parse | docx and docx.pdf are text; the PNG is not an ATS artifact |
| Contact details in the body, not the Word header/footer | Many parsers skip headers and footers | The Contact block is the first body section |
| Standard section headings | Parsers classify sections by heading text | Summary, Skills, Experience, Education, Projects, Languages, Interests |
| Name on the first line | Parsers take the top line as the candidate name | The document title is the name only. It used to read "Nathan Genetzky's Resume" |
| Consistent job blocks: title, employer, dates | Parsers split jobs on a repeated pattern | Every job is `### Title`, then `Employer (dates)`, then bullets |
| Skills as plain keywords | Recruiter searches match words. A 90% bar is an image with no searchable meaning | `[[skills.groups]]` in [params.toml](../config/_default/params.toml): one line of keywords per group |

## Likely

| Requirement | Why | How this repo meets it |
|---|---|---|
| Dates as `Mon YYYY` (or `MM/YYYY`), consistently, with `Present` | Date parsers recognise these forms reliably. `04.2024` is less common and can be misread | `Apr 2024 – Present` throughout |
| City and state in the contact block | Recruiters filter by location; a missing location can exclude you from a search | `Minneapolis, MN`, kept free of qualifiers. "Open to hybrid and remote roles" goes in the Summary so it cannot corrupt the location field |
| One consistent heading hierarchy | Parsers that use Word heading styles, and screen readers, rely on it | Sections use Heading 2, entries Heading 3. Skills and Education used to sit one level below Projects |
| One degree per entry | A minor listed as its own entry with the same dates can parse as a second degree | "BS Electrical Engineering, Minor in Software Engineering" is one entry |
| No empty or broken links | An empty target (`[url]()`) or `mailto: user` (with a space) is noise at best | Links are autolinks. Their visible text is the address itself, so it survives even when links are stripped |

## Folklore

- **"ATS rejects resumes over one page."** Page count matters to the human
  reader, not the parser. This repo caps the docx.pdf at 2 pages for the reader.
- **"You must use Arial or Times New Roman."** Text in a docx is extracted
  without regard to its font. The font matters for legibility. The body is
  11pt Calibri, and resume norms put body text at 10 to 12pt.
- **"An en dash in date ranges breaks parsing."** This is not demonstrated.
  Consistency matters more than which dash is used.
- **"Hyperlinks break parsing."** Links are fine as long as the visible text
  is meaningful.

## Print legibility

For the reader rather than the ATS: body text at 10pt or larger (11pt by
default) and at most 2 pages.
[check_docx_fonts.py](../script/check_docx_fonts.py) enforces both.
[check_artifacts.bash](../script/check_artifacts.bash) runs it, so CI fails
on a regression. The PDF size is read from the PDF's own text commands.
Bounding-box heights from `pdftotext -bbox` misreport the size and once made a
10pt PDF look like ~7.8pt.

Tunables: `DOCX_FONTSIZE` (10pt, 11pt or 12pt) in
[build_docx.bash](../script/build_docx.bash), and `DOCX_MIN_PT` /
`DOCX_MAX_PAGES` in [check_artifacts.bash](../script/check_artifacts.bash).

## Checking what a parser sees

```bash
pdftotext static/nathan-genetzky-resume.docx.pdf - | less   # reading order
pandoc static/nathan-genetzky-resume.docx -t markdown | less  # heading structure
```

The text should read top to bottom: name, contact line, Summary, Skills,
Languages, Experience (title, employer and dates for each job), Education,
Projects, Interests.
