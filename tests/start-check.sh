#!/usr/bin/env bash
# Cemacs starts both ways: through the task dev, which gives no arguments, and through bin/cemacs, which gives the home first and then the files.
# Under --watch a program that failed doesn't end, so the exit code alone says nothing: the output counts too.
set -uo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."

# The output goes to a file, and grep reads the file. Read from a pipe, grep -q stops at its first match, the writer dies of SIGPIPE, pipefail makes the
# test false and a flood of output passes.
output="$(mktemp)"
trap 'rm -f "$output"' EXIT

# Runs a command under the dummy driver and asks it to stop after half a second. SDL turns TERM into a quit event, the editor ends and main prints its Ok.
# So that line is the proof: it says that the window opened and that main ran to its end, where a program that hangs before any window, or that panics
# later than the half second, is only killed, in silence. Nothing else may be printed but the command of the task. KILL comes after TERM for a program
# that no longer answers.
started() {
  SDL_VIDEODRIVER=dummy timeout -s TERM -k 1 0.5 "$@" > "$output" 2>&1
  local status=$?
  if [ "$status" -ne 124 ] || ! grep -qxF 'Ok(Value = missing)' "$output" || grep -qv -e '^> ' -e '^Ok(Value = missing)$' -e '^$' "$output"; then
    printf 'FAILED: %s\nexit %s\n' "$*" "$status"
    head -c 2000 "$output"
    exit 1
  fi
}

started cesia do dev
started bin/cemacs
started bin/cemacs apps/cemacs.ce src/text/text.ce
echo ok
