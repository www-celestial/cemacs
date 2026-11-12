#!/usr/bin/env bash
# Makes user/, the folder that is the person's own, from tools/user-template when it is missing; one that is there, or a link of that name, is never
# touched. bin/cemacs, tools/dev.sh and tests/run.sh run it before Cesia, which stops when a folder that cesia.toml names in src is missing. The copy is made
# beside user/, then renamed to it, so that a copy cut short leaves no half folder that the next start would take as made.
set -eu
home="$(dirname "$(dirname "$(readlink -f "$0")")")"
if [ -e "$home/user" ] || [ -L "$home/user" ]; then
  exit 0
fi
made="$home/.user.$$"
mkdir "$made"
cp -R "$home/tools/user-template/." "$made"
# The rename makes user/ while it is still missing; if another start made it in between, the copy went inside it, and is taken away.
mv "$made" "$home/user" 2> /dev/null || true
rm -rf "$home/user/${made##*/}" "$made"
