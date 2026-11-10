# Install

Cemacs needs three things: Cesia, the two C libraries that draw its window, and its own code. It has no build step: Cesia
runs its source as it is.

## What runs it

Cemacs is tried on Linux: on Arch Linux under Wayland by hand, and on Ubuntu 22.04 by its CI, with SDL's dummy driver,
which draws into memory instead of on a screen. Nothing in its code is specific to Linux, but no other system is tried:
macOS may work with the libraries of Homebrew, and Windows has no `bash` for `bin/cemacs`.

## Cesia

Cemacs is a Cesia program, so Cesia comes first: its book says how to install it, at
https://www-celestial.github.io/cesia-lang/install.html. `cesia` must be on your `PATH`, since Cemacs runs it to check your
code (`cesia check`), and to run your programs (`cesia run` and `cesia do`). `git`, 2.31 or later, on the `PATH` gives the list of a
project's files, `C-x p f`; without it, that list says that git can't run, and the rest works.

The `cesia` line of Cemacs's `cesia.toml` names the oldest Cesia it needs:

```toml
[project]
name = "cemacs"
cesia = "1.1"
src = ["core", "src"]
native = ["SDL3", "SDL3_ttf"]
```

An older Cesia stops at once, with `This project needs Cesia 1.1 or later, and this is ...: run cesia upgrade.` `cesia
version` tells which one you have.

## SDL3 and SDL3_ttf

The window of Cemacs is drawn by two C libraries: [SDL3](https://www.libsdl.org/), which opens the window, reads the keys
and the mouse and draws rectangles, and [SDL3_ttf](https://github.com/libsdl-org/SDL_ttf), which draws text from TrueType
fonts. A C library here is a shared object, a file such as `libSDL3.so.0` that a program loads while it runs; Cesia loads it
through [std/c](https://www-celestial.github.io/cesia-lang/c.html), its way of calling C, and Cemacs then calls its
functions. Cesia doesn't bring these two, so install them with the package manager of your system:

```bash
sudo pacman -S sdl3 sdl3_ttf     # Arch Linux
brew install sdl3 sdl3_ttf       # macOS, untried
```

SDL must be 3.2 or later: an older one opens nothing and Cemacs says `This program needs SDL 3.2 or later.`

On a system whose packages don't have them yet, `tools/sdl-libs.sh` builds both from their sources, SDL 3.2.24 and SDL3_ttf
3.2.2 with FreeType and HarfBuzz inside, into a folder. It needs `curl`, `git`, `cmake` and a C compiler, and on Linux the
development files of X11 and Wayland, the two display systems; the CI of Cemacs installs these on Ubuntu with:

```bash
sudo apt-get install -y cmake libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev libxss-dev \
  libxkbcommon-dev libwayland-dev wayland-protocols libegl1-mesa-dev libgl1-mesa-dev libdrm-dev libgbm-dev
```

Then build them, and tell the system where they are with `LD_LIBRARY_PATH`, the list of folders where Linux looks for
shared objects before its own:

```bash
tools/sdl-libs.sh ~/.sdl
export LD_LIBRARY_PATH=~/.sdl/lib
```

The licenses of both libraries are copied into `~/.sdl/lib/licenses/`.

## The fonts

Cemacs brings its three fonts in `fonts/`, so nothing is to install: Adwaita Sans for the mode line and the messages, Noto
Sans Medium for titles, and JetBrains Mono for the code, a monospaced font, one where every character has the same width, so
that columns line up. All three are under the SIL Open Font License 1.1, whose texts are beside them. The window reads them
from the folder of Cemacs when it opens, at the size of [emacs.FontSize].

## The code

Cemacs is a Cesia project with a repository of its own. Clone it anywhere:

```bash
git clone https://github.com/www-celestial/cemacs
cd cemacs
```

`git pull` brings the newest code. A release of Cemacs is to be a tag, such as `v0.2.0`, with its notes, which
`tools/release.sh` prepares: there is no binary to download, since Cesia runs the code of the tag as it is. No release is
tagged yet.

## Starting it

`bin/cemacs` opens the files it is given, or one empty buffer:

```bash
bin/cemacs notes.ce
```

It is a small `bash` script. It finds the folder of Cemacs from its own place, even through a symbolic link, and runs:

```bash
cesia run --allow read,write,exec=cesia,exec=git,env=HOME,env=PWD,env=XDG_DATA_HOME,ffi=SDL3,ffi=SDL3_ttf \
  "$home/src/cemacs.ce" "$home" "$@"
```

A Cesia program has no permission until it is given one: the `--allow` list names each, as Cesia's chapter on
[permissions](https://www-celestial.github.io/cesia-lang/permissions.html) explains. Cemacs asks for these:

| Permission | Why Cemacs needs it |
|---|---|
| `read`, `write` | to open and save any file you choose, and to list folders |
| `exec=cesia` | to run `cesia check` on your code and `cesia run` or `cesia do` on your programs |
| `exec=git` | to list the files of a project, `git ls-files`, for `C-x p f`: no other program |
| `env=HOME` | `~/` in the folder manager, and the trash |
| `env=PWD` | the folder you started in: a relative path, and the `cesia.toml` whose task runs a file |
| `env=XDG_DATA_HOME` | the place of the trash, as the freedesktop.org specification says |
| `ffi=SDL3`, `ffi=SDL3_ttf` | to load the two libraries of the window |

Link the script into a folder of your `PATH` to start Cemacs from anywhere:

```bash
ln -s "$PWD/bin/cemacs" ~/.local/bin/cemacs
```

A relative path you give it is read from the folder you are in, not from the folder of Cemacs.

### From its folder, with reload

`cesia do dev`, from the folder of Cemacs, runs the task `dev` of its `cesia.toml`: the same program and permissions, under
`--watch`, so that a change of Cemacs's code reloads in the window that runs. It opens one empty buffer, and reads its fonts
from `./fonts`, so it must start from that folder. See [Changing Cemacs](customising.md#reloading-cemacs-while-it-runs).

```toml
[tasks.dev]
file = "src/cemacs.ce"
watch = true
allow = ["read", "write", "exec=cesia", "exec=git", "env=HOME", "env=PWD", "env=XDG_DATA_HOME"]
```

`ffi=SDL3` and `ffi=SDL3_ttf` are not in that list: the `native` line of `[project]` gives them to every task that runs a
file.

## Checking the install

`cesia do test` runs the whole suite of Cemacs, `tests/run.sh`: the tests of every package on both paths of Cesia, with
and without its versions of a function by type, then the tests that open real files, run real programs and open real
windows. With SDL's dummy driver no window shows:

```bash
SDL_VIDEODRIVER=dummy cesia do test
```

It stops at the first failure and names it. One of its tests, `tests/color-std.ce`, colours every package of Cesia's
standard library, whose sources the binary of Cesia carries, so the suite needs nothing beside Cemacs and an installed Cesia.
`tests/start-check.sh` alone checks only that Cemacs starts, both through `bin/cemacs` and through `cesia do dev`.

If Cemacs doesn't start, [Troubleshooting](troubleshooting.md#at-start) lists what it prints and what to do.
