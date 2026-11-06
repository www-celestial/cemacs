# First steps

In this chapter you install Cemacs, open a file, and learn the few keys that get you going. Then you write Cesia in it: the
errors show in the lines, a key runs the file, and another runs it under the debugger. Last, you change Cemacs itself.

## Getting Cemacs

### Cesia

Cemacs runs on Cesia, so Cesia comes first: its book says how to install it, at
https://www-celestial.github.io/cesia-lang/install.html. `cesia` must be on your `PATH`, since Cemacs runs it to check and
to run your programs. The `cesia` line of Cemacs's `cesia.toml` says which version it needs: an older Cesia stops at once,
and says to run `cesia upgrade`.

### SDL3 and SDL3_ttf

The window of Cemacs is drawn with two C libraries, SDL3 and SDL3_ttf. Cesia doesn't bring them: install them with the
package manager of your system.

```bash
sudo pacman -S sdl3 sdl3_ttf     # Arch Linux
brew install sdl3 sdl3_ttf       # macOS
```

On a system whose packages don't have them yet, `tools/sdl-libs.sh` builds both from their sources into a folder, with
`cmake`; `LD_LIBRARY_PATH` then tells the system where they are:

```bash
tools/sdl-libs.sh ~/.sdl
export LD_LIBRARY_PATH=~/.sdl/lib
```

### The code

Cemacs is a Cesia project with a repository of its own. Clone it anywhere:

```bash
git clone https://github.com/www-celestial/cemacs
cd cemacs
```

## Starting it

`bin/cemacs` opens the files it is given, or an empty buffer:

```bash
bin/cemacs notes.ce
```

It gives Cemacs the permissions it needs, as a task of `cesia.toml` would: read and write files, run `cesia`, read three
environment variables, and load its two libraries. Link it into a folder of your `PATH` to start it from anywhere:

```bash
ln -s "$PWD/bin/cemacs" ~/.local/bin/cemacs
```

## Moving and editing

The keys are those of Emacs. `C-` is the Control key and `M-` the Alt key: `C-x C-s` is Control and `x`, then Control and
`s`. A few keys to start with:

| Keys | What they do |
|---|---|
| `C-f`, `C-b`, `C-n`, `C-p`, or the arrows | a character forward or back, a line down or up |
| `M-f`, `M-b` | a word forward or back |
| `C-a`, `C-e`, or Home and End | the start and the end of the line |
| `C-v`, `M-v`, or Page Down and Page Up | a screen down or up |
| `M-<`, `M->` | the start and the end of the file |
| `C-space`, then a move, or Shift and a move | select from there |
| `C-w`, `M-w`, `C-y` | cut, copy, paste |
| `C-k` | cut the end of the line |
| `C-/`, `C-?` | undo, redo |
| `C-g` | stop what the keys started |

## Files, buffers and panes

| Keys | What they do |
|---|---|
| `C-x C-f` | open a file |
| `C-x C-s` | save |
| `C-x b`, `C-x C-b` | the next buffer, the list of buffers |
| `C-x k` | close the buffer |
| `C-x d` | the folder of the current file, as a file manager |
| `C-x 2`, `C-x 3` | split the pane below, or to the right |
| `C-x o`, `C-x 0`, `C-x 1` | the next pane, close this one, keep only this one |
| `C-x C-c` | quit |

In a list, the buffers or the files of a folder, typing filters it, and Enter opens the line under the cursor. In the
folder, `/` goes into the folder under the cursor and Backspace goes up; `C-c n` makes a file or a folder, `C-c r` renames
it, and `C-c k` moves it to the trash.

## The groups under C-c

You don't need to learn the keys above. Under `C-c`, every key is in a group, as in Doom Emacs. Press `C-c` and wait half
a second: a band at the bottom shows each group. Press a group's letter and wait again: the band shows its keys.

| Group | Its keys |
|---|---|
| `C-c f`, files | `f` open, `s` save, `d` the folder, `c` the settings of Cemacs |
| `C-c b`, buffers | `b` the list, `n` the next one, `k` close |
| `C-c w`, windows | `s` split below, `v` split to the right, `o` the next pane, `d` close it, `m` keep only this one |
| `C-c c`, code | `r` run the file, `k` stop it, `o` its output, `n` and `p` the next and the previous error |
| `C-c d`, debug | `r` run under the debugger, `b` a breakpoint, `e` evaluate, `c` continue, `n` next, `s` step, `u` out |
| `C-c q`, quit | `q` quit |

So `C-c f f` opens a file, as `C-x C-f` does. `?` after the first keys lists everything that can follow them, with what each
key does: `C-x ?`, `C-c ?` or `C-c d ?`. Typing filters the list, and Enter runs the key under the cursor.

You can always find a key from its group, without knowing it: `C-c`, then look.

## Writing Cesia

Cemacs colours Cesia's code with `std/syntax`, as Cesia's own book does.

### Errors in the lines

Cemacs checks a Cesia file while you write it, as `cesia check` does, without running it. Half a second after your last
key, and at each save, it reads the buffer, even before it is saved. An error is underlined in red, a warning in amber,
their line number takes the same colour, and the words of the message show at the end of the line. The mode line counts
them.

| Keys | What they do |
|---|---|
| `M-g n`, or `C-c c n` | the next error, from the cursor; after the last one, the first |
| `M-g p`, or `C-c c p` | the previous error |

A warning is about a result whose `Err` would go unseen, such as a `sys.Read` used as a plain value: Cesia's book explains
each kind, in its chapter on errors.

### Running a file

`C-c c r` runs the file of the current buffer, as saved, as `cesia run` would, and as fast. What it prints shows in a pane
below the others. `C-c c o` hides or shows that pane, and `C-c c k` stops a program that keeps running, as a server.

The program runs with no permission, as `cesia run file.ce` does: it computes and prints. A program that reads files or
listens on a port runs in a terminal, with its `--allow`, or as a task of its `cesia.toml`.

### Seeing changes live

To see a program change while you write it, keep a terminal beside Cemacs with `--watch`. Cesia loads your changes each
time you save, and a program that has ended runs again:

```bash
cesia run --watch notes.ce
```

## Debugging

`C-c d r` runs the file under the debugger. It runs as fast as without it until it reaches a breakpoint.

- `C-c d b` puts a breakpoint on the line of the cursor, a dot in the margin, or takes it away. A program that runs takes it
  at once.
- When the program stops, at a breakpoint or on an error, its line takes a band of colour, and the pane below shows the
  variables of the function where it stopped, with their values.
- `C-c d e` evaluates the line of the cursor, or the selection, in the program run by `C-c d r`, and shows its value at the
  end of the line, in grey: it is not part of the file. At a stop, the code sees the variables there; while the program
  runs, it runs at the top of its main file.
- `C-c d c` continues to the next stop. `C-c d n` runs one line, a call as a whole; `C-c d s` runs one line and goes into a
  call; `C-c d u` runs on to the end of the function.

While the program is stopped, you can change its code and save it. When it goes on, the code that changed is loaded: the
function that was running finishes with its old code, and its next call runs the new one.

The debugger of Cemacs is a small Cesia program, `tools/debugger.ce`, which talks with the window over the program's input
and output. Cesia's book shows the same debugger in a terminal, in its chapter on the prompt and the debugger.

## Changing Cemacs

Cemacs is a Cesia project, and its settings are Cesia code. `C-c f c` opens `src/cemacs.ce`, where the apps of Cemacs and
their keys come together. `src/emacs/emacs.ce` holds the keys of Emacs and the settings:

| Setting | What it says |
|---|---|
| `FontSize` | the size of the font, read when the window opens |
| `TabText` | what Tab types |
| `HintDelay` | the seconds before the band of hints shows |
| `CheckDelay` | the seconds without a key before a buffer is checked |
| `WheelLines` | the lines that one notch of the mouse wheel moves |

Each setting is a function, which any code of Cemacs can call. Here are two of them, as this page was built:

```cesia
use src/emacs
emacs.FontSize() -->
emacs.HintDelay() -->
```

To change one, change its function, and save. Being functions, they give the new value at the next key:

```cesia norun
(* in src/emacs/emacs.ce *)
FontSize() = 17
HintDelay() = 0.3
```

### Your own keys

A key runs any function from the state of the editor to a new state, and a group is a key bound to its name, a text. An app
of Cemacs lives in a folder of `src/` and brings its keys. Here is one of your own, with a group `t` and a key in it:

```cesia norun
(* src/mine/mine.ce *)
use core/commands
Keys() = {"C-c t": "tools", "C-c t s": commands.Save}
```

In `src/cemacs.ce`, add `use src/mine`, and `mine.Keys()` to the keys that `Keys` merges. The band shows the new group at
once.

### Reloading Cemacs itself

Start Cemacs with `cesia do dev` from its folder. Each save of one of its files then reloads it, without closing the window,
so a change of a key or a setting works at the next key.

### Its tests

`cesia do test` runs the suite of Cemacs: the tests of each package, on both paths of Cesia, and the tests of the window.
`SDL_VIDEODRIVER=dummy cesia do test` runs them without showing a window. Run it before you share a change.
