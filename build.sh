#!/bin/sh
# Build ttf2lff from source.
#
# There is no Qt and no CMake here: one C++17 file (main.cpp) plus FreeType.
# The upstream ttf2lff.pro pulls in ../../common.pri, i.e. it only builds inside
# a full LibreCAD checkout -- this script builds the same main.cpp standalone.
#
# Overrides (all optional):
#   CXX=clang++                     compiler (default: g++)
#   FREETYPE_CFLAGS / FREETYPE_LIBS use a particular FreeType build
#                                   e.g. FREETYPE_CFLAGS="-I$HOME/ft/include"
#                                        FREETYPE_LIBS="$HOME/ft/lib/libfreetype.a"
set -eu
cd "$(dirname "$0")"

CXX=${CXX:-g++}
CFLAGS=${CFLAGS:--O2}
OUT=${OUT:-ttf2lff}

if [ -n "${FREETYPE_CFLAGS:-}" ] || [ -n "${FREETYPE_LIBS:-}" ]; then
    INC=${FREETYPE_CFLAGS:-}
    LIB=${FREETYPE_LIBS:--lfreetype}
    echo "freetype: explicit FREETYPE_CFLAGS/FREETYPE_LIBS"
elif command -v pkg-config >/dev/null 2>&1 && pkg-config --exists freetype2 2>/dev/null; then
    INC=$(pkg-config --cflags freetype2)
    LIB=$(pkg-config --libs freetype2)
    echo "freetype: pkg-config freetype2 $(pkg-config --modversion freetype2)"
else
    # No pkg-config: guess the usual layouts (ALT: /usr/include/freetype2, /usr/lib64)
    INC="-I/usr/include/freetype2 -I/usr/local/include/freetype2"
    LIB="-lfreetype"
    echo "freetype: no pkg-config, using $INC $LIB"
fi

set -x
$CXX $CFLAGS -std=c++17 -Wall -Wextra -Wno-unused-parameter \
    $INC -o "$OUT" main.cpp $LIB
set +x

./"$OUT" --help | head -2
echo "built: $(pwd)/$OUT"
