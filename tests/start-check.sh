#!/usr/bin/env bash
# Cemacs starts both ways: through the task dev, which gives no arguments, and through bin/cemacs, which gives the home first and then the files.
# Under --watch a program that failed doesn't end, so the exit code alone says nothing: the output counts too.
set -uo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."

# The output goes to a file, and grep reads the file. Read from a pipe, grep -q stops at its first match, the writer dies of SIGPIPE, pipefail makes the
# test false and a flood of output passes.
output="$(mktemp)"
# *scratch* is kept in the folder of the person's data: here, in a new one, never the person's.
XDG_DATA_HOME="$(mktemp -d)"
export XDG_DATA_HOME
trap 'rm -f "$output"; rm -rf "$XDG_DATA_HOME"' EXIT

# Runs a command under the dummy driver and asks it to stop after half a second. SDL turns TERM into a quit event, the editor ends and main prints its Ok.
# So that line is the proof: it says that the window opened and that main ran to its end, where a program that hangs before any window, or that panics
# later than the half second, is only killed, in silence. Nothing else may be printed but the command of the task. KILL comes after TERM for a program
# that no longer answers.
started() {
  SDL_VIDEODRIVER=dummy timeout -s TERM -k 1 0.5 "$@" > "$output" 2>&1
  local status=$?
  if [ "$status" -ne 124 ] || ! grep -qxF 'Ok(missing)' "$output" || grep -qv -e '^> ' -e '^Ok(missing)$' -e '^$' "$output"; then
    printf 'FAILED: %s\nexit %s\n' "$*" "$status"
    head -c 2000 "$output"
    exit 1
  fi
}

started cesia do dev
started bin/cemacs
started bin/cemacs src/cemacs.ce core/text/text.ce

# An option that no app takes stops Cemacs before its window opens: one line on the standard error, the exit code 2, nothing else.
SDL_VIDEODRIVER=dummy timeout -s KILL 10 bin/cemacs --x core/text/text.ce > "$output" 2>&1
status=$?
if [ "$status" -ne 2 ] || [ "$(cat "$output")" != "cemacs: unknown option --x (known: --app)" ]; then
  printf 'FAILED: an unknown option\nexit %s\n' "$status"
  head -c 2000 "$output"
  exit 1
fi
# --app opens a file of cells as an app and runs its cells, silent. Its session is a process that Cemacs started, and Cesia then ends a program at the
# first TERM, as it would without a handler, where SDL would make it a quit event: so the proof is a second of silence, then the end by the timeout.
cells="$(mktemp -d)"
printf '(* %%%% One *)\n1 + 1\n' > "$cells/one.ce"
SDL_VIDEODRIVER=dummy timeout -s TERM -k 1 1 bin/cemacs --app "$cells/one.ce" > "$output" 2>&1
status=$?
if [ "$status" -ne 124 ] || grep -qv -e '^Ok(missing)$' -e '^$' "$output"; then
  printf 'FAILED: bin/cemacs --app\nexit %s\n' "$status"
  head -c 2000 "$output"
  exit 1
fi
rm -rf "$cells"
# -- ends the options, so a file may start with --.
started bin/cemacs -- core/text/text.ce

# user/, in a new folder of Cemacs as a clone gives it: bin/cemacs and cesia do dev make it from the template when it is missing, and never touch one that is
# there, even a link to nothing.
fresh="$(mktemp -d)"
trap 'rm -f "$output"; rm -rf "$fresh" "$XDG_DATA_HOME"' EXIT
cp -r bin core fonts src tests tools cesia.toml "$fresh"
cd "$fresh"
fail() {
  printf 'FAILED: %s\n' "$1"
  exit 1
}
[ ! -e user ] || fail "a copy of Cemacs has no user/"
started bin/cemacs
diff -r tools/user-template user > /dev/null || fail "bin/cemacs makes user/ from the template"
echo '(* mine *)' >> user/config/config.ce
before="$(cat user/config/config.ce)"
started bin/cemacs
[ "$(cat user/config/config.ce)" = "$before" ] || fail "bin/cemacs leaves user/ as it is"
rm -rf user
started cesia do dev
diff -r tools/user-template user > /dev/null || fail "cesia do dev makes user/ from the template"
rm -rf user
ln -s nowhere user
tools/user.sh
[ "$(readlink user)" = nowhere ] && [ ! -e nowhere ] || fail "a link named user is left as it is"
rm user
tools/user.sh
[ -z "$(find . -maxdepth 1 -name '.user.*')" ] || fail "the copy leaves nothing beside user/"

# The template loads and changes nothing; its examples, out of their comments, change what they name.
cesia run tests/user-check.ce template > "$output" 2>&1 && [ "$(cat "$output")" = ok ] || { cat "$output"; fail "the template"; }
sed -i 's/^  (\* \(c\..*\) \*)$/  \1/' user/config/config.ce
cesia run tests/user-check.ce examples > "$output" 2>&1 && [ "$(cat "$output")" = ok ] || { cat "$output"; fail "the examples of the template"; }

# Start runs once, after the files given opened.
cat > user/config/config.ce <<'END'
use std/io
use std/value

defn Changed(config)
  c = config
  c.Start = started
  c
end

defn started(s)
  io.Print("started on $(value.Len(s.Buffers)) buffers, in $(s.Buffers[s.Current].Path)")
  s
end
END
SDL_VIDEODRIVER=dummy timeout -s TERM -k 1 0.5 bin/cemacs src/cemacs.ce core/text/text.ce > "$output" 2>&1
[ "$(cat "$output")" = "$(printf 'started on 2 buffers, in src/cemacs.ce\nOk(missing)')" ] || { cat "$output"; fail "Start runs once after the files open"; }

# *scratch*, made by the Start of Cemacs before the person's: the first buffer with no file, after the files with some, its kept text back.
cat > user/config/config.ce <<'END'
use core/view
use src/rope
use std/io
use std/value

defn Changed(config)
  c = config
  start = config.Start
  c.Start = s -> shown(start(s))
  c
end

defn shown(s)
  last = s.Buffers[value.Len(s.Buffers)]
  io.Print("$(value.Len(s.Buffers)) buffers, in $(view.BufferName(s.Buffers[s.Current])), the last $(view.BufferName(last)): $(rope.Line(1, last.Rope))")
  s
end
END
SDL_VIDEODRIVER=dummy timeout -s TERM -k 1 0.5 bin/cemacs > "$output" 2>&1
grep -qE '^1 buffers, in \*scratch\*, the last \*scratch\*: \(\* Cemacs · [A-Z][a-z]+day [0-9]+ [A-Z][a-z]+ · Cesia [0-9.]+$' "$output" || { cat "$output"; fail "*scratch* is the buffer of a start with no file"; }
SDL_VIDEODRIVER=dummy timeout -s TERM -k 1 0.5 bin/cemacs src/cemacs.ce > "$output" 2>&1
grep -qE '^2 buffers, in cemacs.ce, the last \*scratch\*: \(\* Cemacs · ' "$output" || { cat "$output"; fail "*scratch* comes after the files"; }
mkdir -p "$XDG_DATA_HOME/cemacs"
printf 'x = 1\ny = 2\n' > "$XDG_DATA_HOME/cemacs/scratch.ce"
SDL_VIDEODRIVER=dummy timeout -s TERM -k 1 0.5 bin/cemacs > "$output" 2>&1
grep -qxF '1 buffers, in *scratch*, the last *scratch*: x = 1' "$output" || { cat "$output"; fail "the kept text of *scratch* comes back"; }
[ "$(cat "$XDG_DATA_HOME/cemacs/scratch.ce")" = "$(printf 'x = 1\ny = 2')" ] || fail "a start that changes nothing writes nothing"
echo ok
