#!/usr/bin/env bash
# The whole suite, from the root of kemacs. It stops at the first failure.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."

kepler test .
kepler test . --no-spec
kepler run --allow read tests/color-std.k
kepler run --allow read,write tests/files-check.k
kepler run --allow read,write tests/commands-check.k
SDL_VIDEODRIVER=dummy timeout -s KILL 60 kepler run --allow read,write,exec=kepler,ffi=SDL3,ffi=SDL3_ttf tests/window-check.k
