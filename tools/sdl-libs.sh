#!/usr/bin/env bash
# Builds SDL3 and SDL3_ttf (FreeType and HarfBuzz inside) for Linux into FOLDER/lib, their licenses in FOLDER/lib/licenses:
# tools/sdl-libs.sh FOLDER. The window of Cemacs needs them, and Cesia no longer ships them. The CI keeps FOLDER in its cache,
# and finds them through LD_LIBRARY_PATH; on a desktop, the package manager of the system gives them (pacman -S sdl3 sdl3_ttf).
set -eu
sdl=3.2.24 ttf=3.2.2
out=$(mkdir -p "$1" && cd "$1" && pwd)
work=$(mktemp -d)
lib="$out/lib"
mkdir -p "$lib/licenses"
cd "$work"
jobs=$(getconf _NPROCESSORS_ONLN 2> /dev/null || echo 4)
curl -fsSL --retry 3 -o sdl.tgz "https://github.com/libsdl-org/SDL/releases/download/release-$sdl/SDL3-$sdl.tar.gz"
tar -xzf sdl.tgz
cmake -S "SDL3-$sdl" -B sdl-build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$work/prefix" -DSDL_SHARED=ON \
  -DSDL_STATIC=OFF -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF > /dev/null
cmake --build sdl-build -j"$jobs" > /dev/null
cmake --install sdl-build > /dev/null
cp "SDL3-$sdl/LICENSE.txt" "$lib/licenses/SDL3.txt"
git clone -q --depth 1 --recursive --branch "release-$ttf" https://github.com/libsdl-org/SDL_ttf.git ttf
cmake -S ttf -B ttf-build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$work/prefix" -DCMAKE_PREFIX_PATH="$work/prefix" \
  -DSDLTTF_VENDORED=ON -DSDLTTF_SAMPLES=OFF > /dev/null
cmake --build ttf-build -j"$jobs" > /dev/null
cmake --install ttf-build > /dev/null
cp ttf/LICENSE.txt "$lib/licenses/SDL3_ttf.txt"
cp -L "$work/prefix/lib/libSDL3.so.0" "$work/prefix/lib/libSDL3_ttf.so.0" "$lib/"
