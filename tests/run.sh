#!/usr/bin/env bash
# The whole suite, from the root of kemacs. It stops at the first failure.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."

kepler test .
kepler test . --no-spec
kepler run --allow read tests/color_std.kp
kepler run --allow read,write tests/files_check.kp
kepler run --allow read,write tests/commands_check.kp
SDL_VIDEODRIVER=dummy timeout -s KILL 60 kepler run --allow read,write,exec=kepler,ffi=SDL3,ffi=SDL3_ttf tests/window_check.kp
