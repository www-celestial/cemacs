#!/usr/bin/env bash
# A binding changed while the editor runs applies at the next key. It runs tests/reload-run.k under --watch, on a copy, in a window of the dummy driver, and
# changes apps/emacs/emacs.k as a person would save it. Bindings and settings are functions for this: a reload reruns no file-level statement, so
# Keys = {...} would keep its old value until a restart.
set -uo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."

dir="$(mktemp -d)"
pid=""
cleanup() {
  if [ -n "$pid" ]; then
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
  fi
  rm -rf "$dir"
}
trap cleanup EXIT
cp -r apps fonts src tests kepler.toml "$dir"

failed() {
  printf 'FAILED: %s\n' "$1"
  tail -n 5 "$dir/out" | cut -c 1-200
  tail -n 10 "$dir/err" | cut -c 1-200
  exit 1
}

# Waits for an exact line of the output after its first lines, for two seconds at most.
seen() {
  local limit=$(($(date +%s%N) + 2000000000))
  until tail -n "+$(($2 + 1))" "$dir/out" 2>/dev/null | grep -qxF -- "$1"; do
    [ "$(date +%s%N)" -gt "$limit" ] && failed "never saw: $1"
    sleep 0.01
  done
}

# Changes the code of the running editor, and waits for what the change must do: a line from before the change proves nothing.
changed() {
  local before
  before="$(wc -l < "$dir/out")"
  sed -i "$1" "$dir/apps/emacs/emacs.k"
  seen "$2" "$before"
}

(cd "$dir" && SDL_VIDEODRIVER=dummy exec timeout -s TERM -k 1 20 kepler run --watch --allow read,write,exec=kepler,ffi=SDL3,ffi=SDL3_ttf tests/reload-run.k) > "$dir/out" 2> "$dir/err" < /dev/null &
pid=$!

seen "C-t alone: C-t is not bound." 0
seen "C-t in a pair: C-x C-t is not bound." 0
seen "C-t in a prompt: " 0
seen "tab: 2" 0
seen "wheel: 3 " 0

# A new key on an anonymous function, a key moved to a named one, a new pair.
changed 's/^Keys() = {$/Keys() = {\n  "C-t": s -> commands.Say("hi", s),/' "C-t alone: hi"
changed 's/^  "C-t": s -> commands.Say("hi", s),$/  "C-t": commands.Cancel,/' "C-t alone: Quit"
changed 's/^Keys() = {$/Keys() = {\n  "C-x C-t": s -> commands.Say("a pair", s),/' "C-t in a pair: a pair"
# A key of the prompt and an action of the mouse, bound the same way.
changed 's/^PromptKeys() = {$/PromptKeys() = {\n  "C-t": s -> commands.Say("in the prompt", s),/' "C-t in a prompt: in the prompt"
changed 's/^MouseKeys() = {"down": commands.Press, "move": commands.Drag, "up": commands.Release, "wheel": commands.Wheel}$/MouseKeys() = {"down": commands.Press, "move": commands.Drag, "up": commands.Release, "wheel": (event, s) -> commands.Say("rolled at $(event.X)", s)}/' "wheel: 0 rolled at 100"
changed 's/"wheel": (event, s) -> commands.Say("rolled at $(event.X)", s)}$/"wheel": commands.Wheel}/' "wheel: 3 "
# Settings.
changed 's/^TabText() = "  "$/TabText() = "    "/' "tab: 4"
changed 's/^WheelLines() = 3.0$/WheelLines() = 5.0/' "wheel: 5 "

if [ -s "$dir/err" ]; then
  failed "something went to the errors"
fi
echo ok
