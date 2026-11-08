#!/usr/bin/env bash
# The whole suite, from the root of cemacs. It stops at the first failure.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."

cesia test .
cesia test . --no-spec
cesia run --allow read tests/color-std.ce
# src/ui needs no permission and no window: it uses only the packages of std/ that touch nothing outside.
! grep "^use " src/ui/ui.ce | grep -qvE "^use std/(list|math|value|text|dict)$"
[ "$(cesia run tests/ui-pure.ce; echo "exit $?")" = "$(cat tests/ui-pure.expected)" ]
tests/sdl/run.sh
timeout -s KILL 60 cesia run --allow read,write,exec=mkfifo,exec=truncate tests/files-check.ce
timeout -s KILL 60 cesia run --allow read,write,exec=mkfifo,exec=truncate tests/commands-check.ce
timeout -s KILL 60 cesia run --allow read,write,exec=cesia tests/check-check.ce
timeout -s KILL 60 cesia run --allow read,write,exec=cesia,exec=mktemp,exec=rm,env=PWD tests/run-check.ce
# C-c c r in a project of its own, made in a new folder, where cesia do finds its cesia.toml.
root="$PWD"
project=$(mktemp -d)
(cd "$project" && timeout -s KILL 60 cesia run --allow read,write,exec=cesia,env=PWD "$root/tests/task-check.ce")
rm -rf "$project"
trash=$(mktemp -d)
XDG_DATA_HOME="$trash" timeout -s KILL 60 cesia run --allow read,write,env=HOME,env=PWD,env=XDG_DATA_HOME tests/folders-check.ce
rm -rf "$trash"
SDL_VIDEODRIVER=dummy timeout -s KILL 60 cesia run --allow read,write,exec=cesia,ffi=SDL3,ffi=SDL3_ttf tests/window-check.ce
tests/start-check.sh
tests/reload-check.sh
