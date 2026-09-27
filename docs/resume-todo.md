# Resume TODO — deferred items

Items deliberately left out of [config/_default/params.toml](../config/_default/params.toml)
during the 2026-09-22 refresh because they need a decision or a number from you.

After changing params.toml, regenerate the downstream artifacts — see
[README.md](../README.md) or the commands at the bottom of this file.

## 1. Name the C++ standard

The resume lists `C++ (~9 years)` but never names a standard. Recruiters and
keyword screens look for `C++17` / `C++20` specifically.

- [ ] Decide which standard you use daily: C++14, C++17, or C++20.
- [ ] Update the `[[language.list]]` entry for C++, e.g. `language = "C++ (17)"`,
      or add it to a skills entry.

## 2. Name the secure-boot platform

The PTx entry says "Implemented secure boot and signed firmware images" without
naming the silicon. Naming it makes the claim concrete and interview-ready.

- [ ] Confirm the platform and mechanism — likely i.MX8 HABv4 / AHAB, but verify.
- [ ] Update the bullet to read "…on <platform> using <mechanism>".

## 3. Grow the skills list

Skills are condensed keyword groups (`[[skills.groups]]` in params.toml); the
percentage bars were dropped because ATS parsers ignore them and a bare
percentage invites the question "90% of what?". Adding a skill is one more
string in a group's `items`, or one more `[[skills.groups]]` block.

Only list what the Experience section can back up.

- [ ] Add OTA/cybersecurity keywords you would defend in an interview.

Deliberately absent: Balena, Mender, OSTree and the custom update agent. They
are self-directed personal work, not professional experience, and the Skills
section reads as a professional claim. They are represented instead by the
"Personal projects, self-directed" entry in Experience.

The docx.pdf must stay within 2 pages with body text of at least 10pt (11pt is
the default); `script/check_docx_fonts.py` fails the build if it does not.

## 4. Name agricultural machine types or operations

The PTx entry says "agricultural equipment electronics" generically. Naming the
machines or operations (planting, spraying, harvest, guidance, telematics) would
ground the domain claim.

- [ ] Confirm what you can say publicly without disclosing product details.
- [ ] If yes, extend the first PTx bullet.

## 5. Vehicle networks

Scoped to CAN only — see [can-bus-capability-roadmap.md](can-bus-capability-roadmap.md).
J1939 and ISOBUS are deliberately absent until that roadmap produces evidence.

## 6. Consider un-hiding the Daktronics internship

Commented out in params.toml to hold the resume to one page. It is a 2016–2017
student internship, so this is likely permanent — but the block is preserved
rather than deleted if you ever want it back.

---

## Regenerating artifacts after an edit

```bash
bash script/setup.bash                       # once: init the theme submodule

# Markdown post: copy the <pre> block from http://localhost:1313/md/
# into content/post/nathan-genetzky-resume.md
bash script/serve.bash                       # http://localhost:1313/

bash script/build_artifacts.bash             # everything below, then verifies it
bash script/build_site.bash                  # -> public/
```

`build_artifacts.bash` owns the server lifecycle, so it does not need
`serve.bash` running. Individually:

| Script | Produces |
|---|---|
| `script/build_capture.bash` | `static/nathan-genetzky-resume.{png,pdf}`, `-bw.pdf` (needs a running server) |
| `script/build_docx.bash` | `static/nathan-genetzky-resume.docx`, `.docx.pdf` |
| `script/check_artifacts.bash` | nothing; fails if an artifact is missing, stubbed or corrupt |

Hugo is pinned in [script/hugo.bash](../script/hugo.bash) and run from a
container, so no local install is needed. GitHub Actions runs the same scripts —
see [.github/workflows/build.yml](../.github/workflows/build.yml).
