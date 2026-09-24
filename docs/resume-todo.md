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

## 3. Add the three new skill bars

Recommended in the resume feedback but not added, because
`skills.list.level` must be an `NN%` string and the values were deferred.

Existing bars for calibration:

| Skill | Level |
|---|---|
| Yocto (Build System, Embedded Distro, BSP Support) | 90% |
| Developer Tools (Docker, Jenkins, Git, GDB, JTAG/SWD) | 85% |
| Terminal Workflow (Vim, GNU tools, shell scripting) | 85% |
| Linux Kernel (Drivers, Config, BSP) | 55% |
| Python Middleware (DBus, REST, GObject, threading) | 35% |
| FPGA Development (SW Interface, Reusable Verilog, Automated Builds) | 25% |

- [ ] `OTA & Update Systems (RAUC, A/B, secure boot fallback)` — `__%`
- [ ] `Product Cybersecurity (EN 18031, secure boot, SBOM)` — `__%`

Deliberately not suggested: a "Device Cloud Platforms (Balena)" bar. Balena,
Mender, OSTree and the custom update agent are self-directed personal work, not
professional experience, and a skills bar reads as a professional claim. They
are represented instead by the "Personal projects, self-directed" entry in
Experiences.

Note: the current PDF fills one page with no room to spare. Adding two bars
will likely push it over. Options: drop the two weakest existing bars
(Python Middleware 35%, FPGA 25%), or trim the Vaddio/Dojo Five bullets.

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

# Serve (no local hugo install needed)
docker run --rm --network host -v "$PWD":/src -w /src \
  klakegg/hugo:0.111.3 server --bind 0.0.0.0

# Markdown post: copy the <pre> block from http://localhost:1313/md/
# into content/post/nathan-genetzky-resume.md

bash script/build_capture.bash               # -> static/*.png, static/*.pdf
bash script/build_docx.bash                  # -> static/*.docx, *.docx.pdf (needs pandoc)
```
