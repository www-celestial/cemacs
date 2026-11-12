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
  if [ "$status" -ne 124 ] || ! grep -qxF 'Ok(missing)' "$output" || grep -qv -e '^> ' -e '^Ok(missing)$' -e '^$' "$output"; then
    printf 'FAILED: %s\nexit %s\n' "$*" "$status"
    head -c 2000 "$output"
    exit 1
  fi
}

started cesia do dev
started bin/cemacs
started bin/cemacs src/cemacs.ce core/text/text.ce

# user/, in a new folder of Cemacs as a clone gives it: bin/cemacs and cesia do dev make it from the template when it is missing, and never touch one that is
# there, even a link to nothing.
fresh="$(mktemp -d)"
trap 'rm -f "$output"; rm -rf "$fresh"' EXIT
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
echo ok
