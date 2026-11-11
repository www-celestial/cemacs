#!/usr/bin/env bash
# The indent that Cemacs computes for Cesia, against cesia fmt, on every line of the files of Cesia under the folders given, and with --std on
# the packages of the std that the binary of Cesia carries: copies of the files go to a new folder, cesia fmt writes them in its style, the files
# it can't read are left out, and tools/indent-corpus.ce reads each line as Tab and Enter do. It prints the counts, with --typed also the lines
# where a line typed would land elsewhere, and it fails when Tab would move a line.
#   tools/indent-corpus.sh [--std] [--typed] FOLDER...
set -euo pipefail
home="$(dirname "$(dirname "$(readlink -f "$0")")")"
std=false
typed=""
folders=()
for a in "$@"; do
  case "$a" in
    --std) std=true ;;
    --typed) typed="--typed" ;;
    *) folders+=("$(readlink -f "$a")") ;;
  esac
done
copies="$(mktemp -d)"
trap 'rm -rf "$copies"' EXIT
k=0
for f in "${folders[@]}"; do
  k=$((k + 1))
  mkdir -p "$copies/$k"
  # The files of Cesia, without the dot folders, which cesia fmt leaves as they are.
  (cd "$f" && find . -mindepth 1 -name '.*' -prune -o -name '*.ce' -type f -print | while read -r p; do
    mkdir -p "$copies/$k/$(dirname "$p")"
    cp "$p" "$copies/$k/$p"
  done)
done
if $std; then
  (cd "$home" && cesia run --allow write tools/indent-corpus.ce --write-std "$copies/std")
fi
# cesia fmt names on its error output each file it can't read, which it leaves as it is: those are left out.
cesia fmt "$copies" > /dev/null 2> "$copies/refused.txt" || true
sed -n 's/^\(.*\.ce\):[0-9]*: .*fmt leaves the file as it is\.$/\1/p' "$copies/refused.txt" | while read -r p; do rm -f "$p"; done
rm -f "$copies/refused.txt"
cd "$home"
cesia run --allow read tools/indent-corpus.ce $typed "$copies"
