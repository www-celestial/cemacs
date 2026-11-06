#!/usr/bin/env bash
# The tests of src/sdl and src/ui in a window, under SDL's dummy driver: each NAME.cmd, or NAME.ce alone, runs in this folder,
# and what it writes, then "exit N", must be NAME.expected. Run from anywhere; prints the failures, then a count.
set -u
cd "$(dirname "$(readlink -f "$0")")"
failed=0
total=0
for want in *.expected; do
  name=${want%.expected}
  total=$((total + 1))
  if [ -f "$name.cmd" ]; then
    got=$( (source "./$name.cmd"; echo "exit $?") 2>&1)
  else
    got=$( (cesia run "$name.ce"; echo "exit $?") 2>&1)
  fi
  if [ "$got" != "$(cat "$want")" ]; then
    failed=$((failed + 1))
    echo "tests/sdl/$name failed:"
    diff <(echo "$got") "$want" | head -20
  fi
done
echo "tests/sdl: $((total - failed)) of $total passed"
[ "$failed" -eq 0 ]
