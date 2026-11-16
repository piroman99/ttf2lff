# ttf2lff

[![License: GPL v2](https://img.shields.io/badge/license-GPL--2.0-blue.svg)](LICENSE)
[![Platform: linux-x86_64](https://img.shields.io/badge/binary-linux--x86__64%20static-success.svg)](#prebuilt-static-binary)
[![Deps: none](https://img.shields.io/badge/runtime%20deps-none-brightgreen.svg)](#prebuilt-static-binary)
[![C++17](https://img.shields.io/badge/C%2B%2B-17-informational.svg)](#build-from-source)

`ttf2lff` converts **TrueType/OpenType fonts** (`.ttf`, `.otf`) into
**LibreCAD Font Format** (`.lff`) — the vector font format LibreCAD uses for text
inside CAD drawings.

It is part of the [LibreCAD](https://github.com/LibreCAD/LibreCAD) project
(`tools/ttf2lff`): a single C++17 file plus FreeType. This repository packages the same
code so that it builds **outside** a full LibreCAD checkout — no Qt, no CMake, no
`../../common.pri`; and it ships a **fully static binary** that needs nothing installed on
the target machine.

---

## Table of contents

- [What this is for](#what-this-is-for)
- [Repository contents](#repository-contents)
- [Prebuilt static binary](#prebuilt-static-binary)
- [Usage](#usage)
- [Examples with real numbers](#examples-with-real-numbers)
- [Build from source](#build-from-source)
- [Where to put the .lff file](#where-to-put-the-lff-file)
- [The LFF format](#the-lff-format)
- [Troubleshooting](#troubleshooting)
- [License and credits](#license-and-credits)

---

## What this is for

LibreCAD does not render TrueType fonts directly. Text in a drawing is drawn from
`.lff` vector fonts — polyline glyphs defined by coordinates, so they scale, snap and
export to DXF cleanly. `ttf2lff` takes any system font and turns it into such a font:
it flattens each glyph outline into points (quadratic/cubic splines are approximated by
a configurable number of nodes), normalises the metrics and writes the
`LibreCAD Font 1` text format.

Typical uses:

* any language or typeface inside a drawing, without hunting for a hand-made CAD font,
* company/logo lettering as a real CAD font,
* one consistent font across title blocks, annotations and dimension text,
* reproducible output for scripts and CI (deterministic text, no GUI).

## Repository contents

| Path | What it is |
|---|---|
| `main.cpp` | The whole tool — one C++17 source file (1533 lines), upstream LibreCAD code |
| `build.sh` | Shared-library build; uses `pkg-config freetype2`, with a fallback to the usual include paths |
| `build-static.sh` | Fully static build: downloads FreeType 2.13.3, compiles it in, links with `-static` |
| `ttf2lff.pro`, `freetype.pri` | Upstream Qt/qmake project files, for building **inside** the LibreCAD tree |
| `ttf2lff.1` | Man page |
| `dist/ttf2lff-linux-x86_64` | Prebuilt static binary (2 776 056 bytes), also attached to the v0.0.0.2 release |
| `SHA256SUMS` | SHA-256 of the binary |
| `LICENSE` | GPL-2.0 |

## Prebuilt static binary

Download from the [latest release](https://github.com/piroman99/ttf2lff/releases/latest)
— `ttf2lff-linux-x86_64`, 2 776 056 bytes,
SHA-256 `232bba0a426f34d08dc08becc5119243f20838e5531874ded30492fdc1103844`:

```sh
curl -LO https://github.com/piroman99/ttf2lff/releases/download/v0.0.0.2/ttf2lff-linux-x86_64
curl -LO https://github.com/piroman99/ttf2lff/releases/download/v0.0.0.2/SHA256SUMS
sha256sum -c SHA256SUMS
chmod +x ttf2lff-linux-x86_64
./ttf2lff-linux-x86_64 --help
```

The same file is also committed at `dist/ttf2lff-linux-x86_64`, if you would rather
clone the repository than use release links.

It is genuinely static: `readelf -d` reports **no `NEEDED` entries at all** — no
`libfreetype`, no `libstdc++`, no `libc`. Nothing is resolved from the host, so it does
not care about the distribution or how old its glibc is.

Built on x86_64 Ubuntu 26.10 with `g++ 15.2.0` and FreeType 2.13.3 (both compiled in).
Smoke-tested here: `--help` and a full font conversion (see below). It has **not** been
run on ALT Linux / RHEL by the packager — if it misbehaves on your system, please open an
issue with `uname -a` and the exact command.

The binary is published in [Releases](../../releases) (and committed to `dist/` as well) on
purpose: the recipient only needs the file itself, not a toolchain.

## Usage

```
ttf2lff [options] <ttf file> <lff file>
```

| Option | Meaning | Default |
|---|---|---|
| `-n`, `--nodes N` | Number of nodes used to approximate quadratic/cubic splines | `4` |
| `-a`, `--author TEXT` | Author written into the font header | — |
| `-l`, `--letterspacing N` | Letter spacing | `3.0` |
| `-w`, `--wordspacing N` | Word spacing | `6.75` |
| `-f`, `--linespacing N` | Line spacing factor | `1.0` |
| `-d`, `--precision N` | Decimal digits after the point (min 1) | `6` |
| `-L`, `--license TEXT` | Font license written into the header | — |
| `-z`, `--zerovector` | Drop duplicate consecutive vertices | off |
| `-r`, `--round` | Round vertices to a grid | off |
| `-g`, `--grid N` | Grid size used by `--round` | `0.0001` |
| `-m`, `--mergepath` | Merge paths that share a start/end vertex | off |
| `-e`, `--nestedchar` | Analyse glyphs for nested characters | off |
| `-c`, `--nocomment` | Do not write per-glyph comments | off |
| `-t`, `--tuning` | Shorthand for the tuning set (implies `-d 2`) | off |
| `-h`, `--help` | Show help | — |

`-t` is the "someone already thought about this" preset: duplicate vertices removed,
vertices rounded, paths merged. Output gets much smaller and visually identical at
drawing scale.

## Examples with real numbers

DejaVu Sans, default options — a big Latin+Cyrillic+Greek font:

```sh
./ttf2lff-linux-x86_64 /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf dejavu.lff
```

→ **6 692 687 bytes, 5918 glyphs**, header `# Format: LibreCAD Font 1`, `# Encoding: UTF-8`,
letter spacing 3, word spacing 6.75. Header excerpt:

```
# Format:            LibreCAD Font 1
# Creator:           ttf2lff with python-lff tuning
# Name:              DejaVu Sans
# Encoding:          UTF-8
# LetterSpacing:     3
# WordSpacing:       6.75
# LineSpacingFactor: 1

[#20]

[#21] !
0,1.531145;1.22
```

A small 410-glyph display font (Russo One), measured on the machine that built the
binary:

| Command | Wall time | Output size |
|---|---|---|
| `ttf2lff RussoOne.ttf out.lff` | 0.015 s | 285 647 bytes |
| `ttf2lff -t RussoOne.ttf out.lff` | 0.020 s | 107 664 bytes |

So tuning shrinks the file ~2.6× for free. Conversion is fast enough to do a whole font
library in a loop.

More examples:

```sh
# name the author and the license in the header
./ttf2lff -a "Ivan Karpoukhin" -L "OFL" MyFont.ttf myfont.lff

# denser splines for very round glyphs, full tuning on top
./ttf2lff -t -n 8 Display.ttf display.lff

# strict grid, 3 decimals
./ttf2lff -r -g 0.01 -d 3 Tech.ttf tech.lff
```

## Build from source

### Shared build (needs FreeType headers)

```sh
./build.sh            # -> ./ttf2lff
```

Dependencies:

| Distribution | Packages |
|---|---|
| Debian/Ubuntu | `g++ make pkg-config libfreetype-dev` |
| Fedora/RHEL | `gcc-c++ make pkgconfig freetype-devel` |
| ALT Linux | `gcc-c++ make pkg-config libfreetype-devel` |

`build.sh` resolves FreeType through `pkg-config freetype2`; if `pkg-config` is missing
it falls back to `/usr/include/freetype2` and `-lfreetype`, which covers ALT and RHEL
layouts. To use a specific FreeType build:

```sh
FREETYPE_CFLAGS="-I$HOME/ft/include" FREETYPE_LIBS="$HOME/ft/lib/libfreetype.a" ./build.sh
```

Overrides: `CXX` (compiler, default `g++`), `CFLAGS` (default `-O2`), `OUT` (output name).

### Fully static build (no root, no system FreeType)

```sh
./build-static.sh     # -> ./ttf2lff, statically linked
```

It fetches FreeType 2.13.3 (`FTVER=` to change), configures it with
`--disable-shared --enable-static --without-{zlib,bzip2,png,brotli,harfbuzz}`, builds it
in `WORK` (default `./build`), then links `main.cpp` against
`.../objs/.libs/libfreetype.a` with `-static` and strips the result. Needs `curl`, `make`,
`g++`. The FreeType download falls back to a GitHub release if savannah is unreachable;
you can also drop `freetype-2.13.3.tar.xz` into the work directory yourself.

### Inside the LibreCAD tree

`ttf2lff.pro` still works as upstream intends — copy the directory to
`LibreCAD/tools/ttf2lff`, add it to `tools/tools.pro`, build with qmake. It includes
`../../common.pri` and `freetype.pri` (`FREETYPE_DIR=` supported, otherwise
`pkg-config freetype2`).

## Where to put the .lff file

LibreCAD lists `.lff` fonts found in the `fonts/` directory of its installation (next to
the other bundled CAD fonts). Put the converted file there — or side by side with the
existing `.lff` files of your install — restart LibreCAD, and the font appears in the text
font list. The `.lff` file is plain text, so it can be versioned, diffed and generated in
a build step.

## The LFF format

Short version, enough to sanity-check the output:

* ASCII/UTF-8 text, one glyph per block;
* a block starts with `[<codepoint>] <character>`, comments start with `#`;
* a header block carries `Format`, `Creator`, `Name`, `Encoding`, `LetterSpacing`,
  `WordSpacing`, `LineSpacingFactor`, `Created`, `Last modified`, `Author`, `License`;
* glyph geometry is a list of `x,y;x,y;...` polylines (comma between coordinates,
  semicolon between vertices), one line per polyline, followed by a space advance;
* units are font-relative: the em square is normalised, so the same file scales to any
  text height in the drawing.

Because it is all polylines, glyph quality is a trade-off between node count (`-n`) and
file size — that is the knob to turn if curves look faceted at large sizes.

## Troubleshooting

**`Unknown option: --version`** — there is no `--version`; the tool prints usage instead.
Upstream carries the version in the Qt project (`0.0.0.2`).

**Empty or tiny `.lff`** — the input font is probably a bitmap-only or a variable font
without outlines FreeType can decompose. Try a static instance of the font.

**Curves look angular** — raise `-n` (e.g. `-n 8` or `-n 12`); drop `-r`/`-g` if rounding
at 0.0001 is too coarse for the design.

**Huge file** — use `-t`, or `-z -r -m` individually, or lower `-d`.

**Static binary will not start** — check that it is executable and not blocked by a
noexec mount or a security policy:

```sh
chmod +x ttf2lff-linux-x86_64
file ttf2lff-linux-x86_64      # should say: statically linked
./ttf2lff-linux-x86_64 --help
```

## License and credits

GPL-2.0 — see [`LICENSE`](LICENSE). `main.cpp` is LibreCAD code; its header reads:

* Copyright (C) 2001-2003 RibbonSoft. All rights reserved.
* Copyright (C) 2011 Rallaz — rallazz@gmail.com
* Copyright (C) 2025 LibreCAD (librecad.org)
* Copyright (C) 2026 Dongxu Li (github.com/dxli)

The tuning options come from `python-lff`. The statically linked FreeType is under the
FreeType License (FTL), which is GPL-2.0 compatible. The build scripts and packaging in
this repository are under the same GPL-2.0.

This repository is a repackaging, not a fork: `main.cpp` is upstream code, taken from
`LibreCAD/LibreCAD` `tools/ttf2lff`. Patches to the converter itself belong upstream;
issues about the standalone build scripts belong here.
