#!/usr/bin/env bash
# The task dev of cesia.toml: Cemacs from its folder under --watch, so that a change of its code, or of user/, loads into the window that runs. It makes
# user/ first when it is missing, as bin/cemacs does, then shows the command it runs and runs it, with the permissions of bin/cemacs.
set -eu
[ -e user ] || tools/user.sh
command=(cesia run --allow ffi=SDL3,ffi=SDL3_ttf,read,write,exec=cesia,exec=git,env=HOME,env=PWD,env=XDG_DATA_HOME --watch src/cemacs.ce)
echo "> ${command[*]}"
exec "${command[@]}"
