#!/usr/bin/env bash
# The whole suite, from the root of cemacs. It stops at the first failure.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."

cesia test .
cesia test . --no-spec
cesia run --allow read tests/color-std.ce
timeout -s KILL 60 cesia run --allow read,write,exec=mkfifo tests/files-check.ce
timeout -s KILL 60 cesia run --allow read,write,exec=mkfifo tests/commands-check.ce
trash=$(mktemp -d)
XDG_DATA_HOME="$trash" timeout -s KILL 60 cesia run --allow read,write,env=HOME,env=PWD,env=XDG_DATA_HOME tests/folders-check.ce
rm -rf "$trash"
SDL_VIDEODRIVER=dummy timeout -s KILL 60 cesia run --allow read,write,exec=cesia,ffi=SDL3,ffi=SDL3_ttf tests/window-check.ce
tests/start-check.sh
tests/reload-check.sh
