#!/usr/bin/env bash
# The whole suite, from the root of cemacs. It stops at the first failure.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."

# cesia.toml names user/ among the folders of the code, and Cesia stops when one is missing: a clone where Cemacs never started gets it first, from the
# template. The suite tests Cemacs only, core/ and src/; user/ is the person's, which cesia test user tests.
tools/user.sh
cesia test core
cesia test src
cesia test core --no-spec
cesia test src --no-spec
cesia run tests/color-std.ce
# Tab and Enter give each line of Cemacs and of the std of Cesia the indent that cesia fmt gives it: the folders of Cemacs, without user/.
tools/indent-corpus.sh --std bench core src tests tools
# src/ui needs no permission and no window: it uses only the packages of std/ that touch nothing outside.
! grep "^use " src/ui/ui.ce | grep -qvE "^use std/(list|math|value|text|dict)$"
[ "$(cesia run tests/ui-pure.ce; echo "exit $?")" = "$(cat tests/ui-pure.expected)" ]
# The template that Changing Cemacs shows is the one that user/ is made from.
[ "$(sed -n '/^(\*\* Your changes to Cemacs/,/^```$/p' docs/book/customising.md | sed '$d')" = "$(cat tools/user-template/config/config.ce)" ]
tests/sdl/run.sh
timeout -s KILL 60 cesia run --allow read,write,exec=mkfifo,exec=truncate tests/files-check.ce
timeout -s KILL 60 cesia run --allow read,write,exec=mkfifo,exec=truncate tests/commands-check.ce
timeout -s KILL 60 cesia run --allow read,write,exec=cesia tests/check-check.ce
timeout -s KILL 60 cesia run --allow read,write,exec=cesia,exec=mktemp,exec=rm,env=PWD tests/run-check.ce
timeout -s KILL 60 cesia run --allow read,write,exec=git,env=PWD tests/project-check.ce
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
