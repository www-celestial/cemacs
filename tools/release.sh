#!/usr/bin/env bash
# Prepares a release of Cemacs: tools/release.sh 0.2.0 shows the notes the release will have, from the messages of the commits
# since the tag before (tools/notes.sh), and the commands that make it. A release is its tag and its notes, with no binary: it
# runs on the Cesia that cesia.toml asks for. It commits nothing.
set -eu
cd "$(dirname "$0")/.."
if [ $# -ne 1 ] || ! printf '%s' "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "usage: tools/release.sh X.Y.Z, as tools/release.sh 0.2.0" >&2
  exit 2
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "Commit or set aside the changes first: a tag names a commit." >&2
  exit 1
fi
echo "The notes of v$1:"
echo
tools/notes.sh
echo "Then: git tag v$1 && git push origin v$1"
