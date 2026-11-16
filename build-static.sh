#!/bin/sh
# Build a FULLY STATIC ttf2lff: FreeType is compiled in, so the resulting binary
# needs no libfreetype, no libstdc++, no libc -- it runs on any x86_64 Linux,
# including distributions whose glibc is older than the build host's (ALT, RHEL,
# old Debian). No root: everything is built inside $WORK.
#
# Env: FTVER (FreeType version, default 2.13.3), WORK (build dir, default ./build)
set -eu
cd "$(dirname "$0")"

FTVER=${FTVER:-2.13.3}
WORK=${WORK:-$PWD/build}
FT=$WORK/freetype-$FTVER
mkdir -p "$WORK"

if [ ! -f "$FT/objs/.libs/libfreetype.a" ]; then
    echo "== fetching FreeType $FTVER =="
    cd "$WORK"
    if [ ! -f freetype.tar.xz ] && [ ! -d "$FT" ]; then
        if ! curl -fsSL --retry 4 --retry-all-errors -o freetype.tar.xz \
            "https://download.savannah.gnu.org/releases/freetype/freetype-$FTVER.tar.xz"; then
            rm -f freetype.tar.xz
            curl -fsSL --retry 4 --retry-all-errors -o freetype.tar.xz \
                "https://github.com/freetype/freetype/releases/download/VER-${FTVER//./-}/freetype-$FTVER.tar.xz" || {
                    echo "download failed; put freetype-$FTVER.tar.xz into $WORK" >&2
                    exit 1; }
        fi
    fi
    [ -d "$FT" ] || tar xf freetype.tar.xz

    echo "== configuring FreeType (static, no zlib/png/bzip2/brotli/harfbuzz) =="
    cd "$FT"
    # --prefix is only cosmetic here: we link the build tree, never run make install.
    ./configure --prefix="$WORK/ft" --disable-shared --enable-static \
        --without-zlib --without-bzip2 --without-png --without-brotli --without-harfbuzz \
        > "$WORK/configure.log" 2>&1 || { echo "configure failed:"; tail -30 "$WORK/configure.log"; exit 1; }
    echo "== making FreeType =="
    make -j"$(nproc)" > "$WORK/make.log" 2>&1 || { echo "make failed:"; tail -40 "$WORK/make.log"; exit 1; }
    cd - >/dev/null
fi

echo "== linking ttf2lff (static) =="
CXX=${CXX:-g++}
$CXX ${CFLAGS:--O2} -std=c++17 -Wall -Wextra -Wno-unused-parameter \
    -I"$FT/include" -I"$FT/objs" \
    -o ttf2lff main.cpp \
    -static "$FT/objs/.libs/libfreetype.a"
strip ttf2lff 2>/dev/null || true

file ttf2lff
ldd ttf2lff 2>&1 || true
./ttf2lff --help | head -1
echo "built: $(pwd)/ttf2lff"
