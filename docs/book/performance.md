# Speed

This chapter gives what Cemacs costs in time and memory, how each number was measured, and why it is what it is. Cemacs
keeps four goals since its first version, for a file of 20,000 lines in a window of 1920 by 1080: a key to its frame under
16 ms, the time of one frame at 60 frames a second; scrolling at 60 lines a second; opening under 300 ms; and no frame at
all from an editor that waits. Each section puts Cemacs beside GNU Emacs 31.1, Neovim 0.12.6 and Vim 9.2 where the same
thing can be measured on them; [Cemacs and other editors](comparison.md) gathers the numbers and the features.

## How it was measured

- **The machine:** an Intel Core i7-4720HQ, 4 cores and 8 threads at 2.6 GHz, its frequency left to the system; 11 GB of
  memory; Arch Linux, Linux 7.2.11. Cesia 1.0.0+dev, at a548741 for the numbers that compare this version with the one
before, SDL3 3.4.18, SDL3_ttf 3.2.2, Mesa 26.2.6, tmux 3.8.
- **Alone:** each measure ran while no other heavy job of the machine did, under one lock that the heavy jobs share.
- **The window:** SDL's dummy driver, `SDL_VIDEODRIVER=dummy`, which draws into memory with SDL's software renderer and
  shows nothing. A real screen adds the work of the graphics driver and the compositor, and vsync, which this driver
  doesn't have. The other editors ran in a terminal of tmux, 160 characters by 50, which answers the questions they ask a
  terminal at their start as a real one does.
- **The numbers:** each measure was run n times, as said beside it, the editors taking turns. The number given is the
  median, the middle run, which one slow run can't move as it moves a mean. The 95 % interval after it, as [49.2, 50.3], is
  between two runs of the sorted list, chosen so that the true median lies between them with a probability of at least
  95 %, whatever the distribution of the times: with $n = 20$, the 6th and the 15th; with $n = 10$, the 2nd and the 9th. With
  $n = 5$, the fastest and the slowest are the best there is, at 93.75 %; with $n = 3$, only the median is given.
- **The scripts** are on this page or in `bench/`, so that anyone can run them again.

## Start-up

From the command to the first frame of the window, with one empty buffer, $n = 20$:

| Editor, as started | Start to the first frame |
|---|---|
| Cemacs, in its window, SDL's dummy driver | 51.1 ms [50.9, 51.9] |
| Cemacs, the version before this one | 49.8 ms [49.5, 50.8] |
| GNU Emacs 31.1, `emacs -Q -nw` | 89.1 ms [88.3, 92.9] |
| Neovim 0.12.6, `nvim --clean -n` | 13.8 ms [13.6, 13.9] |
| Vim 9.2, `vim --clean -n` | 9.3 ms [9.2, 9.4] |

Each editor started with no configuration of the user, and was told to draw its screen and quit: `--eval '(progn (redisplay
t) (kill-emacs))'` for Emacs, `'+redraw!' '+qa!'` for Neovim and Vim. Each run is the time of the process, from its start to
its end, as a program of Python inside the terminal timed it. This version loads 1.3 ms more than the one before: the search,
the reader of the states of the colours and the search in the rope add about 475 lines of code, which Cesia reads at each
start. The check of UTF-8 of [Opening a file](#opening-a-file), one call of Cesia now, took 94 lines off what Cesia reads:
measured later beside the version before it, at 8ee42e7, taking turns, $n = 11$, 53.2 ms [52.7, 54.7] against 54.1 ms [53.7,
55.4], no slower.

This version against the one before it, `main` at b2ab23f, taking turns, $n = 15$: 53.7 ms [53.4, 55.3] against 54.7 ms [54.3,
55.0]. The steps of this version added about 200 lines of code, which made the start 1.9 ms longer, 56.6 ms [56.2, 57.4];
the widgets of `src/ui` that nothing in Cemacs used, a menu bar, a tool bar, sliders, lists and graph nodes of an earlier
design, about 290 lines, were taken out, and the start is now 1 ms shorter than before.

The indent of Cesia code, [core/indent], adds about 640 lines of code, and 980 with the changes it brings to the other
packages, which Cesia reads at each start. Measured beside `main` at 65ec91c, taking turns, $n = 15$: 56.9 ms [56.5, 59.9]
against 52.3 ms [50.8, 53.2]; again, $n = 21$: 59.4 ms [57.5, 66.7] against 53.6 ms [51.3, 60.4]. The load alone, the packages
that Cemacs uses and `io.Print(1)`, $n = 31$: 38.0 ms [37.4, 41.7] against 31.1 ms [29.6, 34.5]. That is about 5 ms for 640
lines, where the rest of Cemacs costs about 3.7 µs a line: Cesia's load grows faster than the code it reads, as the same 1,000
lines of small functions take 0.85 ms to load alone and 1.8 ms beside the packages of Cemacs. Completion adds about 270 lines
more, and 2 ms: in a later series, taking turns, $n = 31$, 62.0 ms [59.8, 64.6] against 59.9 ms [58.3, 62.4] with the indent
only and 55.0 ms [53.0, 60.6] for `main` at 65ec91c.

The cause was not Cesia's reading of the code, which costs the same for each line, but OCaml's collector: the trees of the
code live as long as the program, and the minor collection that came in the middle of the load copied the 740,000 words
young at that moment to the major heap, about 11 ms, wherever the young heap of 16 MB filled. Code added anywhere brought it
on. The next version of Cesia makes half the garbage while it loads, 1.84 million words for Cemacs instead of 3.38
million, so the load ends before the young heap is full and nothing is copied during the start. With it, taking turns, n =
21: the load alone 24.4 ms [24.2, 24.6] against 38.2 ms [37.7, 38.3]; the start to the first frame 51.4 ms [50.8, 51.9]
against 57.7 ms [56.7, 58.5], with the indent only 50.8 ms [49.7, 51.4], and `main` at 65ec91c 47.3 ms [47.2, 48.0]
against 51.1 ms [50.9, 51.7]. The 1,000 lines of small functions now cost the same beside Cemacs as alone, 0.9 ms.

Where the 51 ms went, with the dummy driver, before this version, each part timed from the one before by the program below with a mark after each part, $n = 20$,
medians:

| Part | Time | Whose |
|---|---|---|
| Cesia's own start, as for `io.Print(1)` | 3.2 ms | Cesia |
| reading and preparing the code: 6,977 lines of Cemacs and of the packages of Cesia it uses, 29 files | 25.9 ms | Cesia |
| SDL3's video, the window, its renderer, and SDL3_ttf with the first font | 4.0 ms | SDL |
| the two other fonts | 0.2 ms | SDL |
| the size of a character, the first texts measured | 2.8 ms | SDL |
| the state, its buffer and its screen | 0.3 ms | Cemacs |
| the frame: its commands, then SDL drawing them | 10.7 ms | Cemacs and SDL |
| closing the window, and the end of the process | 2.1 ms | SDL and Cesia |

Most of the frame is SDL3_ttf making the first images of the characters, which it keeps after. Loading the code costs Cesia
about 3.7 µs a line: [Cesia's book](https://www-celestial.github.io/cesia-lang/) tells how it reads, checks and compiles a
program. `--no-spec` and `--no-jit` don't change it: 30.8 and 30.4 ms against 30.5 for the load alone, $n = 20$. Loaded alone,
with what each uses, $n = 20$: the packages of Cesia that Cemacs uses, 4.3 ms; `src/ui`, 5.1; `src/sdl`, 6.5; `core/commands`
and all it uses, 26.6; all of Cemacs, 31.1 ms. These were measured before this version; the widgets of `src/ui`
are gone since, and about 300 lines of kinds of drawing of `src/sdl` that only its tests use are still read: rings, fades,
shadows, images, tiles, icons and curves.

In a real window, the start costs far more, and most of it is not Cemacs's. Measured in a Wayland window of SDL's Wayland
driver, in GNOME's compositor run headless, `mutter --headless --wayland --no-x11 --virtual-monitor 1280x720`, which shows
nothing on a screen, $n = 10$: 236 ms [232, 241], 237 ms [229, 244] for the version before. Of these, SDL's video starts in
about 80 ms and makes the window in about 60: on GNOME, whose compositor draws no title bar, SDL asks libdecor, a library that
draws the bar in the program, and libdecor's plugin for GTK starts GTK. With libdecor's plugin for cairo instead, a plainer
bar, the two take about 14 and 38 ms; with no libdecor, `SDL_VIDEO_WAYLAND_ALLOW_LIBDECOR=0`, 4 ms and 1 ms, and the window
has no title bar at all. The renderer, OpenGL here, takes about 40 ms more. Emacs, Vim and Neovim draw into a terminal that
is already open, and pay none of this.

Cemacs's start was measured with this program, which does what `bin/cemacs` does up to its first frame, then closes the
window and ends. It was run from the folder of Cemacs as
`cesia run --allow read,write,exec=cesia,env=HOME,env=PWD,env=XDG_DATA_HOME,ffi=SDL3,ffi=SDL3_ttf first-frame.ce . [FILE]`:

```cesia norun
use src/buffers
use src/check
use src/emacs
use src/folders
use src/help
use src/output
use src/project
use src/sdl
use src/ui
use core/commands
use core/text
use core/view
use std/dict
use std/io
use std/list
use std/result
use std/sys

Keys() = help.WithHelp(dict.Merge(dict.Merge(dict.Merge(dict.Merge(dict.Merge(emacs.Keys(), buffers.Keys()), folders.Keys()), project.Keys()), check.Keys()),
  output.Keys()))
Config() = check.Hooked(emacs.Config(Keys))

defn main()
  home = sys.Args[1]
  size = Config().FontSize()
  first = sdl.Open("Cemacs", 1280, 720, "$home/fonts/AdwaitaSans-Regular.ttf", size = size, light = true)?
  second = sdl.AddFont("strong", "$home/fonts/NotoSans-Medium.ttf", size, first, light = true)?
  window = sdl.AddFont("code", "$home/fonts/JetBrainsMono-Regular.ttf", size, second)?
  measured = sdl.Measure(window)
  look = ui.Look(ui.Dark, measured.Width, measured.Height)
  cell = {Width: look.Width("M", "code"), Height: sdl.TextSize("Ag", window, font = "code").Height + view.LineGap}
  empty = view.Start([text.Of("", missing)], look, cell, 1280, 720)
  empty.Window = window
  empty.Config = Config
  empty.Home = home
  state = commands.Settled(commands.OpenAll(list.Skip(1, sys.Args), empty))
  shown = sdl.Frame(view.View(state), window)
  sdl.Close(shown)
  result.Ok(state.Buffers[state.Current].Path)
end

io.Print(main())
```

## Opening a file

From the command to the first frame, with the file given, $n = 7$, this version, the version before it, `main` at b2ab23f, and
the three others taking turns; the files are Cesia's standard library put end to end, and the last line holds a word found
nowhere else, for [search](#search):

| File | Cemacs | Cemacs before | GNU Emacs 31.1 | Neovim 0.12.6 | Vim 9.2 |
|---|---|---|---|---|---|
| 0.79 MB, 22,490 lines | 66.9 ms [66.2, 71.0] | 68.5 ms [66.4, 83.9] | 98.4 ms [97.7, 109] | 20.5 ms [20.4, 42.7] | 18.0 ms [17.4, 19.8] |
| 15.9 MB, 449,762 lines | 97.8 ms [97.1, 139] | 123 ms [122, 125] | 145 ms [142, 149] | 53.2 ms [52.8, 61.9] | 51.5 ms [50.4, 52.0] |
| 99.9 MB, 2,833,490 lines | 266 ms [262, 281] | 416 ms [413, 500] | 393 ms [392, 460] | 235 ms [231, 317] | 247 ms [241, 294] |

The other editors don't know Cesia, so they show these files as plain text, where Cemacs colours the lines on the screen.
Emacs was told not to ask before a large file, `(setq large-file-warning-threshold nil)`; Neovim and Vim were started with
`-n`, which makes no swap file.

What opening 99.9 MB costs, measured alone, without the window, $n = 7$, the two versions taking turns:

| Step | This version | The version before |
|---|---|---|
| reading the file from the disk, `sys.Read` | 23.5 ms [22.4, 27.5] | 24.5 ms [22.6, 28.6] |
| the check of UTF-8 and of zero bytes, [files.IsText] | 63.4 ms [61.2, 74.4] | 62.4 ms [62.0, 68.9] |
| the rope, [rope.Of] | 105 ms [104, 118] | 258 ms [256, 352] |
| the peak of memory of the process, `VmHWM` | 193 MB | 245 MB |

What changed: the rope no longer copies the file. Its leaves were 97,540 pieces of 1,024 bytes, each a copy of its bytes and
a record of six fields, joined by as many nodes, about 195,000 records made in Cesia, at about a microsecond each; they are now
6,097 views of 16 KiB of the one text read, with no copy, and as many nodes: [Inside Cemacs](internals.md#the-rope). Cesia
itself now reads a file into one text of its size, where it filled a buffer then copied it, and counts line ends and checks
UTF-8 eight bytes at a time.

Cemacs now opens 99.9 MB in 0.68 of Emacs's time, and 15.9 MB in 0.68 too; Neovim and Vim still open a large file faster, in
0.88 and 0.93 of Cemacs's time at 99.9 MB, and in about half at 15.9 MB. What is left is mostly Cesia's: the start, about 55
ms, as [Start-up](#start-up) tells, which decides below about 20 MB; the check of the bytes, 63 ms, two passes eight bytes at
a time in OCaml where a library in C with the vector instructions of the processor, as simdutf, would take about a sixth; and
the 105 ms of the rope, of which counting the line ends of each view, on slices of 2 KiB, is about 70 ms measured alone, since
Cesia has no call that counts in a part of a text without a slice. Neovim and Vim fill blocks of lines in C, about 2.3 ns a
byte in all; beating them at 100 MB needs one of those two calls in Cesia.

## Typing and scrolling

`bench/gate.ce` measures the core and the frame on a text of 20,000 lines, Cesia's standard library repeated as the binary of
Cesia carries it, [cesia.Libraries], in a window of 1920 by 1080 at 13 points, without vsync: 300 passes of one typed
character at line 19,000, then 300 passes of one scrolled line, each pass made of `view.FollowState`, `view.View` and
`sdl.Frame`. It prints the median and the worst pass, and the median of each of the three parts:

```bash
SDL_VIDEODRIVER=dummy cesia run --allow read,ffi=SDL3,ffi=SDL3_ttf bench/gate.ce
```

Seven runs of this version, each in turn with one of the version before it, `main` at b2ab23f, and with each step between
them; the median of the seven runs' medians, and its interval:

| Version | One typed character | One scrolled line | The view of a pass | First jump to line 19,000 |
|---|---|---|---|---|
| before, b2ab23f | 11.7 ms [11.4, 11.8] | 18.5 ms [17.8, 19.5] | 2.9 ms | 30.6 ms [30.3, 49.0] |
| + text objects kept by their words | 11.3 ms [11.1, 11.4] | 11.4 ms [11.0, 11.8] | 2.8 ms | |
| + the rows of the screen kept | 9.5 ms [9.4, 10.0] | 9.2 ms [9.1, 9.7] | 0.7 ms | 32.6 ms [31.1, 41.0] |
| + the colours in chunks | 9.1 ms [9.0, 9.2] | 9.2 ms [9.0, 9.4] | 0.7 ms | 34.5 ms [31.7, 55.1] |
| this version | 9.2 ms [9.0, 9.7] | 9.1 ms [8.9, 9.5] | 0.7 ms | 30.0 ms [29.7, 36.9] |

The second line was measured in its own series, before Cesia changed its searches that afternoon, beside 11.4 ms [11.4,
12.0] and 18.6 ms [18.2, 18.9] for the version before. A scrolled line now costs what a key costs, 9.1 ms, 110 lines a
second: the goal of 60 is met, where it wasn't before (54 a second). Where the time went, and what changed:

- **Shaping.** SDL3_ttf shapes a text, with HarfBuzz, the first time it is drawn with new words. Its text objects belonged to
  places in the order of the frame, so when every line moved up one row, nearly every object got new words and was shaped
  again: 227 of the 232 texts of a scrolled frame, about 32 µs each. Kept by their words, they are shaped once, and a scrolled
  line shapes only the words of the line that comes in: the frame of a scroll, 14.6 → 7.9 ms.
- **The view.** It read each line on the screen from the rope, 55 reads, and coloured each one again; the rows kept by
  [view.Follow] spare both: 2.9 → 0.7 ms for a key.
- **What is left** is the frame of SDL's software renderer, about 7.8 ms: the raster of the whole window of 1920 by 1080, 8.3
  MB of pixels, at each frame. A real window draws with the graphics card: below.
- The first jump to line 19,000 reads the state of the colours of every line above it, once: 30.0 ms against 30.6 before.
  The gate times only `view.FollowState` there, which, since the rows are kept, also makes the tokens of the first screen,
  1 to 2 ms that the view no longer makes; the steps between measured 32.6 to 35.0 ms, with intervals that reach 41 to 58 ms
  at their top: the gate makes one jump a run, one sample, where a key or a scroll is the median of 300.

The same gate in a real Wayland window, with OpenGL: GNOME's compositor, `mutter --headless --wayland --no-x11
--virtual-monitor 1920x1080`, SDL without libdecor, and Mesa's llvmpipe, which draws OpenGL with the processor as this machine's
graphics are not reachable from the headless compositor, $n = 7$:

| Version | One typed character | One scrolled line | Its frame |
|---|---|---|---|
| before, b2ab23f | 5.3 ms [5.1, 5.8] | 11.9 ms [11.4, 13.4] | 1.3 ms, 7.8 ms |
| + the three steps of the frame, up to the colours in chunks | 2.6 ms [2.5, 3.2] | 2.5 ms [2.4, 2.8] | 1.1 ms, 1.3 ms |
| this version | 2.6 ms [2.6, 3.2] | 2.6 ms [2.5, 3.1] | 1.1 ms, 1.3 ms |

Beside the others, each timing its own key and its own scrolled line with its redraw, inside the program, in a terminal of tmux,
on the gate's text written to a file, $n = 7$, the three taking turns in a series of their own, the same afternoon:

| Editor | One typed character at line 19,000 | One scrolled line |
|---|---|---|
| Cemacs, OpenGL | 2.6 ms [2.6, 3.2] | 2.6 ms [2.5, 3.1] |
| Cemacs, SDL's software renderer | 9.2 ms [9.0, 9.7] | 9.1 ms [8.9, 9.5] |
| GNU Emacs 31.1, `(redisplay t)` | 1.06 ms [1.04, 1.08] | 1.51 ms [1.49, 1.60] |
| Neovim 0.12.6, `redraw` | 0.045 ms [0.042, 0.063] | 0.020 ms [0.018, 0.030] |
| Vim 9.2, `redraw` | 0.059 ms [0.056, 0.068] | 0.052 ms [0.051, 0.083] |

The others still win, and by far for Vim and Neovim: they write the few cells of a terminal that changed, in C, and the
terminal, another program, draws the pixels, which their time doesn't count; Neovim's terminal interface is even a process of
its own. Emacs, in a terminal too, compares the rows it wants with those on the screen, sends only what differs, and finds the
cheapest way to shift its lines by dynamic programming, in its `src/scroll.c`, the method of Gosling's redisplay of 1981.
Cemacs shapes and draws pixels itself, the whole frame at each event. A frame of the screen lasts 16.7 ms at 60 Hz: every one
of these times, the five, lands within the same frame, and the eye can't tell them apart. The honest time from a key to the
screen needs a camera, or a tool that watches the screen such as Typometer, and none was used.

### A key in a large file

A typed character at the middle line, 1,416,745, of the file of 99.9 MB, without drawing for Cemacs: 100 keys, each followed
by `view.FollowState` and `view.View`, as the update and the view do, the colours first read down to the screen; the others
with their redraw, $n = 7$, Cemacs's versions taking turns, and the others in a series of their own:

| Editor | Median of the runs' medians | The runs' worst key |
|---|---|---|
| Cemacs | 1.57 ms [1.41, 1.97] | 2.45 ms [2.23, 4.17] |
| Cemacs, with only the colours in chunks | 1.37 ms [1.20, 1.96] | 2.28 ms [1.65, 3.59] |
| Cemacs before, b2ab23f | 43.7 ms [40.8, 48.0] | 92.5 ms [70.9, 100.1] |
| GNU Emacs 31.1 | 1.05 ms [1.04, 1.10] | 23.3 ms [22.9, 23.3] |
| Neovim 0.12.6 | 0.042 ms [0.042, 0.053] | 0.25 ms [0.23, 0.33] |
| Vim 9.2 | 0.057 ms [0.052, 0.060] | 0.12 ms [0.09, 0.14] |

The colours kept the state at the start of each line in one flat list, cut and extended by copies at each edit: at line 1.4
million, two copies of 1.4 million states, 22 MB of garbage, at every key. In chunks of 1,024 lines, an edit copies the list of
1,384 chunks and one chunk: [Inside Cemacs](internals.md#the-colours). The size of the file no longer counts: the key costs about what it costs at line 19,000 of
the gate without its drawing, and the two Cemacs lines differ by less than their intervals. Emacs's median key is about two
thirds of Cemacs's, and its worst key ten times Cemacs's worst; Vim and Neovim, which change one line of their memline and
write a few cells of the terminal, stay 30 times faster.

### Enter and Tab in a file of Cesia

One key in a file of Cesia, without drawing: [commands.Update] of the key, which runs its command and [view.FollowState]
after it, from the same state each time, the colours of the screen exact; 15 keys a run, two runs of this version and two of
the version before, `main` at 65ec91c, taking turns, $n = 30$. The version before indented a new line as the line above and
typed two spaces with Tab. `small.ce` is `core/commands/commands.ce`, 52 KB; `big100.ce` the files of Cesia end to end, 100.5
MB, 2.47 million lines; the line is a statement in the body of a function.

| File, line | Enter, before | Enter | Enter again on the new line, before and now | Tab, before: two spaces | Tab | A letter typed, before and now |
|---|---|---|---|---|---|---|
| `small.ce`, 692 | 0.712 ms [0.469, 0.876] | 0.734 ms [0.701, 0.819] | 0.291, 0.323 ms | 0.616 ms [0.367, 0.692] | 0.677 ms [0.651, 0.695] | 0.585, 0.451 ms |
| `small.ce`, 1,375, near its end | 0.299 ms [0.290, 0.313] | 0.596 ms [0.579, 0.605] | 0.193, 0.228 ms | 0.265 ms [0.258, 0.275] | 0.553 ms [0.537, 0.568] | 0.265, 0.292 ms |
| `big100.ce`, 1,237,251 | 0.551 ms [0.536, 0.562] | 0.832 ms [0.812, 0.859] | 0.305, 0.358 ms | 0.468 ms [0.452, 0.484] | 0.790 ms [0.779, 0.810] | 0.435, 0.500 ms |
| `big100.ce`, 2,474,497 | 0.449 ms [0.439, 0.471] | 0.660 ms [0.654, 0.694] | 0.352, 0.415 ms | 0.407 ms [0.386, 0.425] | 0.499 ms [0.488, 0.522] | 0.393, 0.447 ms |

The place of a line costs 0.1 to 0.3 ms more than copying the indent of the line above: the reading from the anchor, the
lines of the function above the cursor. Enter again on the new line goes on from the reading that the first Enter kept, and
costs 0.03 to 0.06 ms more than before. A letter typed checks whether it makes a word that moves the line: at the start of a
line only, so in the middle of a line it costs 0.03 to 0.06 ms more. The size of the file doesn't count: a line is read from
its anchor, a few lines up.

Beside Emacs and Neovim, which have no mode for Cesia, on files of Python of about the same sizes: `small.py`, Python's
`argparse.py`, 107 KB, and `big100.py`, Python's standard library end to end, 104.7 MB; a statement in the body of a function,
at the middle of the file and at its end; Emacs 31.1's python-mode, `newline-and-indent` and `indent-for-tab-command`, in
batch, and Neovim 0.12.6's `A<CR>` and `==`, its indent of Python, `python#GetIndent()`, headless, each from the same state
again and again, one call first to warm it, $n = 30$. Their numbers have no redraw; Cemacs's hold the follow of the screen.

| File, place | Cemacs, Enter | Emacs, Enter | Emacs, Tab | Neovim, Enter | Neovim, `==` |
|---|---|---|---|---|---|
| small, middle | 0.734 ms [0.701, 0.819] | 0.197 ms [0.191, 0.211] | 0.148 ms | 18.8 ms [18.2, 19.2] | 18.3 ms |
| small, end | 0.596 ms [0.579, 0.605] | 0.290 ms [0.283, 0.328] | 0.248 ms | 19.1 ms [18.9, 19.5] | 16.0 ms |
| 100 MB, middle | 0.832 ms [0.812, 0.859] | 201 ms [200, 205] | 218 ms | 3.78 ms [3.70, 3.86] | 3.49 ms |
| 100 MB, end | 0.660 ms [0.654, 0.694] | 409 ms [406, 411] | 441 ms | 15.8 ms [15.2, 16.6] | 15.5 ms |

Emacs wins on the small file, two to four times faster than Cemacs, with no redraw in its number. In the file of 100 MB,
its key costs 0.2 to 0.4 s, more the farther the line is in the file, and its first key 5 to 10 s, while the states of its
parser, `syntax-ppss`, are read from the start of the file. Neovim's indent of Python, a function of Vimscript that looks up
to 50 lines back for the bracket a line is in, and tests the syntax colours at each bracket it meets, costs 3.5 to 19 ms a
key; its plain edits cost 0.02 ms. Cemacs's key costs under a millisecond at every
size: its reading starts at the anchor, the line at the margin above.

### Completion

Tab at the end of a word in a file of Cesia, [Editing](editing.md#completion), measured as the keys above, from the same state
each time: a new line opened in a function and a start of a word typed on it, `s`, `co` or `val`; $n = 30$, two runs of this
version and of the version before taking turns. Before, Tab typed two spaces.

| File, start | Words | Tab that opens the list | Tab, before | `C-n` | Tab that puts the word | A letter, the list open | The first Tab |
|---|---|---|---|---|---|---|---|
| `small.ce`, `s` | 100 | 4.47 ms [2.98, 5.24] | 0.25 ms | 0.21 ms | 0.40 ms | 1.49 ms | 14.3 ms |
| `small.ce`, `co` | 40 | 0.81 ms [0.79, 0.83] | 0.25 ms | 0.14 ms | 0.30 ms | 0.63 ms | 8.8 ms |
| `small.ce`, `val` | 3 | 0.69 ms [0.64, 0.70] | 0.22 ms | 0.14 ms | 0.31 ms | 0.59 ms | 8.7 ms |
| `big100.ce`, `s` | 100 | 3.66 ms [3.61, 3.75] | 0.26 ms | 0.16 ms | 0.47 ms | 1.11 ms | 10.4 ms |
| `big100.ce`, `co` | 74 | 1.43 ms [1.39, 1.47] | 0.29 ms | 0.15 ms | 0.42 ms | 0.85 ms | 8.8 ms |
| `big100.ce`, `val` | 6 | 1.16 ms [1.04, 1.23] | 0.27 ms | 0.18 ms | 0.49 ms | 0.83 ms | 8.5 ms |

Most of a completion is finding the words: each place where the start typed begins a word, in the 128 KB around the cursor,
found by [text.ByteFind], and the word read after it, so a start of one letter, found at a thousand places, costs most. A
letter typed with the list open finds the words again for the longer start. The first Tab of a session also reads the names
of Cesia, [complete.Names], 8 to 10 ms, once. A letter typed with no list costs what it cost before, within 0.03 ms.

Beside Emacs and Neovim, on the files of Python of the indent above, at the middle line: Emacs 31.1's
`dabbrev--find-all-expansions`, the words of the whole buffer that `dabbrev-completion` lists, and `dabbrev-expand`, `M-/`,
which puts the nearest word in place with no list; Neovim 0.12.6's `o`, the start and `Ctrl-N`, its completion of the words of
its buffers, with the indent of Python turned off, as it costs more than the completion; $n = 30$, and $n = 3$ for Emacs and 7 for
Neovim in the file of 100 MB.

| File, start | Cemacs, Tab | Emacs, every word | Emacs, `M-/` | Neovim, `Ctrl-N` |
|---|---|---|---|---|
| small, `s` | 4.47 ms [2.98, 5.24] | 15.3 ms [15.0, 26.4] | 0.035 ms | 2.49 ms [2.46, 2.55] |
| small, `co` | 0.81 ms [0.79, 0.83] | 4.07 ms [4.00, 4.12] | 0.114 ms | 1.51 ms [1.15, 1.85] |
| small, `val` | 0.69 ms [0.64, 0.70] | 2.91 ms [2.76, 3.05] | 0.040 ms | 0.63 ms [0.62, 0.65] |
| 100 MB, `co` | 1.43 ms [1.39, 1.47] | 23.2 s | 0.147 ms | 948 ms [918, 995] |
| 100 MB, `val` | 1.16 ms [1.04, 1.23] | 13.2 s | 0.227 ms | 379 ms [348, 477] |

Neovim wins on a start of one letter, 2.5 ms against 4.5, and is as fast on three; Emacs's `M-/`, which looks for one word
only, wins everywhere. In the file of 100 MB, Emacs and Neovim read the whole buffer, and so find more words, 686 for `co`
where Cemacs offers its first 100 from 128 KB, but they take 0.4 to 23 s; Cemacs's Tab stays under 1.5 ms.

## Search

One search of a word found only on the last line of the file, from its start: the others in one process each, the file
loaded, Emacs's `search-forward` in `emacs --batch`, Neovim's `search()` in `nvim --headless`, Vim's `search()` in `vim -es`;
Cemacs without a window, the file opened, then `C-s` and the word typed as one text through [commands.Update], up to the
state that shows the place; $n = 7$, all taking turns:

| Measure | 15.9 MB | 99.9 MB |
|---|---|---|
| GNU Emacs 31.1, `search-forward` | 7.6 ms [7.4, 7.9] | 48.4 ms [47.8, 51.6] |
| Neovim 0.12.6, `search()` | 28.3 ms [27.7, 29.6] | 181 ms [179, 265] |
| Vim 9.2, `search()` | 33.6 ms [32.4, 36.8] | 300 ms [290, 315] |
| Cemacs, finding the place, [rope.Find] alone | 7.6 ms [7.4, 7.9] | 48.8 ms [48.4, 53.5] |
| Cemacs before, b2ab23f, the same | 92.5 ms [89.7, 144] | 583 ms [573, 596] |
| Cemacs, `C-s` and the word, to the place shown | 45.9 ms [45.2, 49.4] | 87.6 ms [86.7, 88.6] |
| Cemacs before, the same | 767 ms [762, 816] | 5,457 ms [5,302, 5,823] |
| Cemacs, the same typed one letter at a time | 293 ms [288, 306] | 341 ms [338, 348] |
| Cemacs before, the same | 767 ms [758, 831] | 5,591 ms [5,419, 5,864] |

The word has no capital, so every search here folds case. Finding the place costs Cemacs what one call of Cesia's
[text.ByteFind] costs on the file's text, in place, eight bytes at a time, with the case folded in the same pass: [Search and
lists](search.md#how-it-finds). It joined each window of the rope into one text, put it in lower case, then searched it, a
byte at a time. Emacs searches its buffer in place, in C, with a Boyer–Moore search whose tables fold the case: it compares
the word from its end and skips ahead by the tables, so that most bytes are never looked at; Neovim and Vim run their
regular expression engine over their lines. Cemacs now finds the word as fast as Emacs, within the intervals, and 4 and 6 times faster than
Neovim and Vim. To go under Emacs, the search itself would have to read more than eight bytes a step, with the vector
instructions of the processor, SIMD, which OCaml doesn't give: a version in C with SSE2, 16 bytes a step, took 8.8 ms for
99.9 MB when Cesia's search was designed. Typing the word one letter at a time costs more than typing it at once: each of its nine
letters searches again from where the search started, as Emacs's incremental search does, and each search that finds its
place far down reads the text up to there again.

Showing the place took far more than finding it: the colours of the screen depend on the state of every line before it, 1.3
µs a line. A far place is now shown at once with its colours guessed, and they become exact over the ticks after,
[view.ColorBatch] lines a tick: [Inside Cemacs](internals.md#a-far-place-first-its-exact-colours-after). `M->` alone, the
place shown with its frame's commands, then the ticks of 16 ms until the colours are exact, each with its commands, $n = 7$:

| Measure | 15.9 MB | 99.9 MB |
|---|---|---|
| Cemacs, `M->`, the place shown | 38.5 ms [37.7, 129] | 36.1 ms [35.4, 41.7] |
| Cemacs, the colours exact | 673 ms [637, 1,173], 17 ticks | 4,072 ms [3,957, 4,259], 113 ticks |
| Cemacs, the slowest tick of a run | 40.6 ms [38.2, 114] | 60.0 ms [45.0, 69.2] |
| Cemacs before, b2ab23f, the place shown, its colours exact | 699 ms [671, 737] | 4,615 ms [4,518, 4,800] |

A tick reads 25,000 lines in about 36 ms with its frame's commands, the time of a run divided by its ticks; its slowest, about
60 ms, stays under the tenth of a second. A key typed meanwhile reads a batch too, so it waits up to that much more until the
colours are exact; and a comment or a text opened far above can colour the screen wrong for those seconds. Emacs, Neovim and
Vim showed these files without colours, as they don't know Cesia. In a language they know, Vim colours from a guess a few
lines above the screen, its `syntax sync`; Emacs colours only what is shown, its jit-lock, from the state of its parser,
which `syntax-ppss` reads from the nearest place where it kept one.

## Paste, undo and save

A paste of 1 MB at the middle line of the file, its undo, then a save over the file, which then holds the text it had; Cemacs
without a window, the frame's commands made after each step, the colours first read to the screen; the others in a terminal of
tmux, each step timed inside with its redraw; $n = 7$, all taking turns:

| Step | Cemacs | Cemacs before | GNU Emacs 31.1 | Neovim 0.12.6 | Vim 9.2 |
|---|---|---|---|---|---|
| paste of 1 MB, 15.9 MB | 52.4 ms [52.2, 69.8] | 67.2 ms [62.4, 67.6] | 42.9 ms [41.9, 44.1] | 2.71 ms [2.64, 2.81] | 2.57 ms [2.46, 2.72] |
| its undo, 15.9 MB | 1.60 ms [1.52, 1.72] | 14.5 ms [13.8, 14.8] | 46.5 ms [45.4, 47.3] | 13.4 ms [13.3, 13.9] | 2.92 ms [2.68, 4.04] |
| save, 15.9 MB | 64.0 ms [42.9, 102] | 30.8 ms [29.2, 31.8] | 131 ms [125, 131] | 85.6 ms [73.8, 107] | 83.4 ms [76.7, 127] |
| paste of 1 MB, 99.9 MB | 44.7 ms [44.5, 46.7] | 93.6 ms [89.3, 125] | 238 ms [234, 250] | 2.82 ms [2.77, 2.96] | 2.84 ms [2.80, 3.04] |
| its undo, 99.9 MB | 1.47 ms [1.45, 1.52] | 49.1 ms [47.9, 57.1] | 230 ms [228, 244] | 61.0 ms [60.6, 61.5] | 3.11 ms [3.07, 3.18] |
| save, 99.9 MB | 274 ms [250, 636] | 599 ms [380, 887] | 584 ms [578, 589] | 764 ms [449, 1,424] | 851 ms [580, 901] |

This version calls `fsync` before it says `Saved`, as Neovim and Vim do and Emacs doesn't, where the version before didn't:
[Files and buffers](files.md#never-losing-the-text). The same version without it saved the 15.9 MB in 7.4 ms [6.8, 7.6], so
the disk takes the rest; its time varies with what the file system has still to write, as the wide intervals of the four
that wait for it show. It is still faster than the others, because the text saved here is the text read, after the undo:
the rope's views still cover the file's one text, so it is written as it is, where the version before joined its 97,540
leaves into a new text first. A buffer that was edited is joined once, then written.

- **Undo** is about 1.5 ms at both sizes, the fastest of the four: the history keeps whole states, values that never change,
  so taking one back is $O(1)$, 0.1 ms; the rest is the frame's commands. It cost the copies of the colour states before, 49 ms
  at 99.9 MB. Vim deletes the lines the paste added; Emacs deletes the region, moving its gap, a copy of up to the whole file.
- **A paste** of 1 MB costs about 45 ms at both sizes, a third of what it cost at 99.9 MB, and Emacs's time at 15.9 MB is
  still lower. Most of it is the colours of the pasted lines down to the cursor, 28,000 of them, of which the first
  25,000 are read at once and the rest at the next tick, and the cut of the pasted text into its lines to place the cursor
  after it, `str.Split`; the edit of the rope itself and the cut take 11 to 15 ms. Vim and Neovim append the
  lines to their blocks in C: 2.7 ms.

## The folder manager

A folder of 10,000 files, the first file's buffer current, medians of 21 passes, each with `commands.Settled` as the editor
calls it after each event:

| Step | Median of 21 | Fastest, slowest |
|---|---|---|
| opening the folder, `C-x d` | 105 ms | 96, 127 ms |
| the first letter typed, `9`, which keeps 3,439 rows | 7.4 ms | 5.8, 23.0 ms |
| a second letter, `9` again, filtering the rows shown | 8.4 ms | 7.6, 14.8 ms |

The script made the folder, 10,000 files named `file-1.ce` to `file-10000.ce`, then timed [folders.Open] with
[commands.Settled], and two text events through [commands.Update], as the window sends them. Opening reads the folder once:
one listing and one look at each of the 10,000 entries, then the rows and their colours. A letter filters the rows read then,
from those already shown when the filter only grew. These times are from before the filter found each letter natively;
[A case: finding a file from a few letters](finding.md#speed-each-letter-answers-at-once) measures the filter since, on
1,933 rows: 288 letters typed in 210 ms against 402 before.

## The check

`cesia check --json --stdin` of `core/commands/commands.ce`, 1,160 lines, as Cemacs runs it, $n = 10$: 28.8 ms [26.7, 31.5].
So the marks of an error come about 30 ms after the half second of pause that starts the check. It runs in its own process,
from a fiber: the editor doesn't wait for it, and typing goes on.

## At rest

An editor at rest, one empty buffer, 3 seconds after its start; the memory of every process of the editor, $n = 5$:

| Editor | RSS | PSS |
|---|---|---|
| Cemacs, `bin/cemacs`, dummy driver | 46.5 MB [46.4, 46.6] | 41.8 MB [41.7, 41.9] |
| GNU Emacs 31.1, `emacs -Q -nw` | 55.8 MB [55.7, 56.0] | 49.0 MB [48.0, 49.1] |
| Neovim 0.12.6, `nvim --clean -n` | 20.3 MB [20.3, 20.4] | 10.1 MB [9.8, 10.2] |
| Vim 9.2, `vim --clean -n` | 10.6 MB [10.5, 10.8] | 7.8 MB [7.7, 8.0] |

RSS, the resident set size, is the memory of a process that is in RAM, the libraries it shares with other programs counted
whole; PSS, the proportional set size, counts a shared page divided by the number of processes that share it, which is fairer
between programs. Cemacs holds the Cesia runtime, SDL3, SDL3_ttf, its three fonts and the window.

With a large file open, 8 seconds after the start, $n = 7$, the editors taking turns: the RSS of the editor's own process, and
of all its processes, which for Cemacs counts the check, `cesia check`, when the file is one of Cesia; then the processor over
the 10 seconds after:

| Editor, file of 99.9 MB | RSS, its own process | RSS, all its processes | Processor |
|---|---|---|---|
| Cemacs, the file named `.txt`, no check | 219.5 MB [219.4, 219.6] | 219.5 MB | 2.9 % [1.8, 3.2] |
| Cemacs before, b2ab23f, `.txt` | 269.6 MB [269.5, 269.8] | 269.6 MB | 2.6 % [2.4, 2.9] |
| Cemacs, the file named `.ce` | 220.0 MB [219.8, 220.1] | 220.0 MB | 2.7 % [2.6, 2.9] |
| Cemacs with only the limit of the check, `.ce` | 270.0 MB [269.8, 270.1] | 270.0 MB | 2.6 % [2.5, 2.7] |
| Cemacs before, `.ce` | 463.0 MB [462.9, 463.1] | 475.3 MB [475.3, 475.5] | 48.1 % [46.1, 51.4] |
| GNU Emacs 31.1 | 151.4 MB [151.1, 151.5] | 151.4 MB | 0.0 % [0.0, 0.0] |
| Neovim 0.12.6 | 9.7 MB [9.6, 9.8] | 137.4 MB [137.1, 137.6] | 0.0 % [0.0, 0.0] |
| Vim 9.2 | 133.0 MB [132.9, 133.0] | 133.0 MB | 0.0 % [0.0, 0.0] |

Two things went, both measured on the same file under its two names:

- **The check of the large file**, which held the whole text once more for `cesia check`, whose process grew as it read
  it, and kept a core half busy, 48 % over the 10 seconds: a Cesia buffer over 1 MB is no longer checked, [Errors in the
  lines](check.md#when-it-runs). 475 → 270 MB, and the processor as for a plain text.
- **The copy of the file in the rope**: its leaves are views of the text read, so the 99.9 MB are held once, where 97,540
  leaves held a copy of them, beside the text read that the collector had not freed yet. 270 → 220 MB.

The others still hold less: Vim and Neovim about the file and a few bytes a line, 133 and 137 MB, Emacs the file in its gap
buffer, 151 MB. Neovim's own process is its terminal interface; its editor is a second process, which holds the file. Of
Cemacs's 220 MB, about 46 MB is the empty editor (Cesia's runtime, the code it prepared, SDL and its fonts) and about 100 MB
the file; the rest is the rope's 12,000 records, and memory that OCaml's collector has freed or will free but the process
keeps: Cesia's memory is managed by that collector, which frees little at a time, at a pace set by what the program makes,
and an editor at rest makes almost nothing. The processor of Cemacs at rest is that of SDL's dummy driver, which looks for an
event every millisecond; in a real window, the editor sleeps, as the table below tells.

The processor at rest, over 10 seconds, 3 seconds after the start, one empty buffer, in percent of one core, $n = 5$. The time
is what the system counted for every process of the editor, in hundredths of a second, so 0.0 % is less than 0.1 %:

| Editor, where | Processor at rest | Before Cemacs slept in SDL |
|---|---|---|
| Cemacs, in a Wayland window | 0.0 % [0.0, 0.0] | 1.4 % [0.9, 1.5] |
| Cemacs, SDL's dummy driver | 0.8 % [0.8, 1.2] | 0.7 % [0.7, 0.8] |
| GNU Emacs 31.1, in tmux | 0.0 % [0.0, 0.0] | |
| Neovim 0.12.6, in tmux | 0.0 % [0.0, 0.0] | |
| Vim 9.2, in tmux | 0.0 % [0.0, 0.0] | |

A still Cemacs now sleeps in SDL until the next event, 250 ms at most, as [Inside Cemacs](internals.md#the-loop-of-events)
tells; it looked for one every 5 milliseconds before, and slept between. The Wayland window was a real one, of SDL's Wayland
driver, in a compositor of its own that showed nothing on a screen: `mutter --headless --wayland --no-x11
--virtual-monitor 1280x720`, GNOME's compositor, in a session bus of its own, `dbus-run-session`. SDL's dummy driver can't
wait for an event, so SDL looks for one every millisecond there, in C: the tests use it, a person never does. The others
sleep until the system wakes them with an event, and cost nothing while you read. Cemacs draws a frame at each pass while a
program runs, a check runs or is due, or a prefix key waits for its band of hints.

From a key to the editor, in that Wayland window, $n = 120$ keys, 40 in each of 3 runs, a key every 0.25 to 0.5 seconds:

| From the key sent to | This version | Before |
|---|---|---|
| its event read by the update | 0.72 ms [0.71, 0.74] | 3.08 ms [2.45, 3.48] |
| the commands of its frame made | 1.13 ms [1.12, 1.14] | 3.39 ms [2.83, 3.91] |

The keys were sent as a remote desktop sends them, through the `RemoteDesktop` interface of mutter over D-Bus, and the time
of each starts just before that call, so it holds the call, mutter, Wayland and SDL. The editor wakes as soon as the key
comes, where it could sleep up to 5 ms before. The buffer was empty, so making the frame's commands was short; drawing them
then takes SDL's renderer, as in [Typing and scrolling](#typing-and-scrolling).

## Limits

- A file larger than 1 GiB isn't opened: one of 1 GiB takes about twice its size in memory at its peak.
- The undo history keeps 1,000 states per buffer, and the output of a program its last 1,000 lines.
- SDL keeps at most 8,192 shaped texts; past that, it forgets them all and shapes again what the next frames draw.
- A Cesia buffer over 1,000,000 bytes is not checked: see [Errors in the lines](check.md#when-it-runs).
- One check runs at a time, for one buffer.
