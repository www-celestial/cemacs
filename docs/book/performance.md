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

From the command to the first frame of the window, with one empty buffer. Cemacs as it is now and `main` at 65ec91c, before
the indent and the completion, each with the next version of Cesia and with Cesia 1.1.0, the four taking turns, $n = 62$, in
two series of 31; the others in a series of their own, $n = 20$:

| Editor, as started | Start to the first frame |
|---|---|
| Cemacs, in its window, SDL's dummy driver, with the next version of Cesia | 51.3 ms [50.8, 51.9] |
| the same with Cesia 1.1.0 | 57.4 ms [57.0, 58.0] |
| Cemacs before the indent and the completion, `main` at 65ec91c, with the next version of Cesia | 47.9 ms [47.4, 48.3] |
| the same with Cesia 1.1.0 | 51.3 ms [50.8, 51.6] |
| GNU Emacs 31.1, `emacs -Q -nw` | 89.1 ms [88.3, 92.9] |
| Neovim 0.12.6, `nvim --clean -n` | 13.8 ms [13.6, 13.9] |
| Vim 9.2, `vim --clean -n` | 9.3 ms [9.2, 9.4] |

Each editor started with no configuration of the user, and was told to draw its screen and quit: `--eval '(progn (redisplay
t) (kill-emacs))'` for Emacs, `'+redraw!' '+qa!'` for Neovim and Vim. Each run is the time of the process, from its start to
its end, as a program of Python inside the terminal timed it. The version that brought the search loaded 1.3 ms more than the
one before it, 51.1 ms [50.9, 51.9] against 49.8 ms [49.5, 50.8], $n = 20$: the search, the reader of the states of the
colours and the search in the rope add about 475 lines of code, which Cesia reads at each start. The check of UTF-8 of
[Opening a file](#opening-a-file), one call of Cesia now, took 94 lines off what Cesia reads: measured later beside the
version before it, at 8ee42e7, taking turns, $n = 11$, 53.2 ms [52.7, 54.7] against 54.1 ms [53.7, 55.4], no slower.

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
million, so the load ends before the young heap is full and nothing is copied during the start. With it, taking turns,
$n = 21$: the load alone 24.4 ms [24.2, 24.6] against 38.2 ms [37.7, 38.3], and the 1,000 lines of small functions now cost
the same beside Cemacs as alone, 0.9 ms. The start to the first frame, in the table above, $n = 62$: 51.3 ms [50.8, 51.9]
against 57.4 ms [57.0, 58.0] with Cesia 1.1.0, and for `main` at 65ec91c 47.9 ms [47.4, 48.3] against 51.3 ms [50.8,
51.6]. With the next version of Cesia, the indent and the completion cost 3.4 ms at the start, and Cemacs starts in the same
time as it did with Cesia 1.1.0 before them.

The folder of the person, `user/`, adds to the start a package of 21 lines, the template's `user/config`, three reads of
the config with a `match` each, and a test of the shell in `bin/cemacs`, `[ -e "$home/user" ]`, which starts no process.
Measured beside `main` at 158205b, the program below with the code of each, the two taking turns, $n = 62$ in two series of
31: 54.5 ms [53.5, 55.5] against 54.8 ms [53.8, 55.9], the same time. `main` itself took 54.8 ms that day against 51.3 in
the table, on the same machine: two versions are compared only within one series. `src/cemacs.ce` now calls the `Changed`
of `user/config` each time the editor reads its config, two or three times for a key: a pause of about 100 µs put in
`Config()` made `C-f` 220 to 270 µs longer. `Config()` alone, 1,000 calls a pass, 300 passes, $n = 21$ runs taking
turns: 1.26 µs [1.25, 1.27] against 0.83 µs [0.82, 0.85], the call of `Changed` and the copy of the record that puts `?`
after the prefix keys. A key through [commands.Update], on a buffer of 1,000 lines, without drawing, the median of 3,000
passes in each run, $n = 21$: `C-f` 815.2 µs [801.1, 831.1] against 810.9 µs [794.2, 834.0], a typed letter 816.8 µs
[809.2, 828.0] against 818.0 µs [811.1, 827.1]. The 1 µs or so that a key spends in `Changed` is below what the runs can
tell apart.

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

### A key on a very long line

A key on a line of 100 KB and of a megabyte in a file of Cesia, after its first character, at its middle and at its end:
`press.Press` of the key, which follows the screen, then `view.View`, from the same state each time, in a window of 800 by
600, 90 columns; $n = 21$, this version and the version before, `main` at 48311e8, taking turns. `hello` is five letters
typed. The line is one word, `a` repeated and then ` b`, as a data URI is, or code, `f(a, "b c", 12) + x.y (* z *) `
repeated, as a minified file is. The version before could take the line of code once, at 100 KB only: a key at its end took
21 s there, and the time grows with the square of the line. Medians in milliseconds, before → now; the slowest of the 21 runs
is within 1.2 times the median, but for a few runs of up to 1.6 times:

| Line, place | `C-e` | `x` | backspace | `hello` |
|---|---|---|---|---|
| one word of 100 KB, start | 41.3 → 9.3 | 113 → 3.2 | 2.8 → 1.1 | 571 → 12.3 |
| one word of 100 KB, middle | 41.1 → 8.6 | 22.7 → 7.1 | 21.7 → 5.4 | 111 → 31.4 |
| one word of 100 KB, end | 1.0 → 0.5 | 43.7 → 10.2 | 43.3 → 11.2 | 216 → 50.7 |
| one word of 1 MB, start | 490 → 81.8 | 1,344 → 19.6 | 11.2 → 12.0 | 6,853 → 89.6 |
| one word of 1 MB, middle | 499 → 79.6 | 247 → 55.0 | 245 → 53.1 | 1,186 → 260 |
| one word of 1 MB, end | 10.9 → 6.4 | 478 → 88.6 | 477 → 89.5 | 2,394 → 427 |
| code of 100 KB, start | 22,302 → 18.1 | 143 → 10.1 | 75.2 → 9.3 | 644 → 46.8 |
| code of 100 KB, middle | 21,124 → 21.7 | 5,196 → 18.9 | 5,163 → 19.2 | 26,164 → 88.6 |
| code of 100 KB, end | 3.8 → 0.6 | 20,934 → 26.2 | 21,501 → 25.6 | 107,533 → 128 |
| code of 1 MB, start | 167 | 84.3 | 77.1 | 410 |
| code of 1 MB, middle | 167 | 163 | 160 | 797 |
| code of 1 MB, end | 6.3 | 238 | 239 | 1,197 |

The backspace at the start of a line of a megabyte took 12.3, 13.1 and 12.3 ms before and 11.8, 12.5 and 12.0 now in three
more series of 41 runs: the same. What changed, in [Inside Cemacs](internals.md#the-colours):

- The lexer made a text of each character of the line, 0.2 s for a megabyte before the first token, and joined each plain word
  to the one before it by a copy of the list of tokens and of the words: a line of code cost the square of its words. It walks
  the bytes now, and slices a run of plain words once.
- The screen makes the tokens of its own columns only, from the byte where the first one starts: the line before is crossed by
  its comments and texts, each found natively, and its code is not read. At the end of the megabyte of code, the 64,500
  comments and texts before the screen take 147 ms; the state at the end of the line, for the lines under it, 63 ms; the rest
  is the key and its frame. A word of a megabyte is walked a byte at a time, 65 ms: a call of [text.Byte] costs 56 ns, the
  floor of a walk by bytes in Cesia.
- The state at the end of a line, [color.StateAfter], looked again from each text for a backslash a line of code didn't have,
  reading the rest of the line each time: 6.9 s for the megabyte of code, 63 ms now.
- A letter typed at the start of a line split the whole line into characters, to know whether its first word moves it: it
  reads the start of the line now, 1,344 ms → 19.6 ms on the line of a megabyte.

On a file of usual lines nothing is slower: the tokens of the 1,065 lines of `core/view/view.ce` take 11.1 and 11.5 ms
instead of 28.7 and 29.3, a key at its line 500 with its view 0.5 to 2.9 ms in both versions, and at line 19,000 of the text
of the gate, a typed key with its view 1.55 ms in both (three series of 301), a scrolled line 2.2 ms instead of 2.9.

The row of a line on the screen now also keeps the stops of its crossing, [Inside Cemacs](internals.md#the-colours), so a key
at the far end of a line of code crosses only what follows the last stop before its edit. The keys of the table above on the
lines of code, this version and `main` at 02a2baf taking turns, $n = 21$, medians in milliseconds, before → now; the other
lines and places take what they took:

| Line, place | `C-e` | `x` | backspace | `hello` |
|---|---|---|---|---|
| code of 100 KB, end | 0.5 → 0.6 | 25.7 → 15.7 | 25.5 → 15.6 | 125 → 75.0 |
| code of 1 MB, start | 165 → 169 | 83.6 → 80.7 | 75.6 → 76.8 | 404 → 398 |
| code of 1 MB, middle | 168 → 96.8 | 162 → 91.3 | 160 → 90.9 | 797 → 447 |
| code of 1 MB, end | 6.3 → 7.5 | 242 → 93.4 | 238 → 98.0 | 1,182 → 452 |

`C-e` at the end, where the cursor already is, takes 7.3 to 7.7 ms before and 7.3 to 7.8 now when it is measured alone, three
series of 41 taking turns: the same. At the middle, `C-e` crosses from the last stop of the row it leaves. At the end of the
megabyte of code, what a letter still takes is the state at the end of the line, for the lines under it, 63 ms, the 64 KB at
most crossed from the last stop, and the key and its frame. On a file of 99.9 MB of lines of a megabyte of code, the 28 rows of
the screen keep 392 stops, 36 KB, under 0.01 % of the 595 MB that the process holds after 20 letters there, 644 MB with the
version before.

Enter, Tab, `C-j` and `end` typed on lines of the same two kinds, indented two spaces inside a block, `if a` above them and
`end` below, so that `end` moves its line and Enter and Tab read the block; measured as the keys above, this version and
`main` at 02a2baf taking turns, $n = 21$, medians in milliseconds, before → now:

| Line, place | Enter | Tab | `C-j` | `end` |
|---|---|---|---|---|
| one word of 100 KB, start | 79.2 → 10.2 | 17.4 → 9.9 | 0.5 → 0.5 | 18.4 → 14.7 |
| one word of 100 KB, middle | 72.1 → 10.7 | 17.6 → 10.0 | 0.5 → 0.5 | 19.5 → 20.0 |
| one word of 100 KB, end | 62.2 → 11.0 | 21.7 → 14.1 | 0.5 → 0.5 | 33.3 → 30.2 |
| one word of 1 MB, start | 1,065 → 86.9 | 174 → 88.5 | 5.2 → 5.3 | 159 → 115 |
| one word of 1 MB, middle | 930 → 91.0 | 169 → 84.7 | 5.0 → 5.5 | 158 → 155 |
| one word of 1 MB, end | 813 → 89.9 | 193 → 95.2 | 5.0 → 5.4 | 267 → 255 |
| code of 100 KB, start | 133 → 9.4 | 62.7 → 39.9 | 0.5 → 0.5 | 83.1 → 27.8 |
| code of 100 KB, middle | 147 → 28.9 | 63.6 → 39.4 | 0.5 → 0.5 | 52.8 → 52.3 |
| code of 100 KB, end | 116 → 46.0 | 63.9 → 39.4 | 0.5 → 0.5 | 76.3 → 45.7 |
| code of 1 MB, start | 1,540 → 80.1 | 581 → 374 | 5.4 → 5.4 | 757 → 250 |
| code of 1 MB, middle | 1,625 → 269 | 577 → 373 | 5.7 → 5.3 | 478 → 268 |
| code of 1 MB, end | 1,279 → 436 | 581 → 366 | 5.3 → 5.2 | 705 → 268 |

`C-j` had no command in Cemacs when this was measured, before it became Enter's, as in Emacs: it was the follow and the frame of a key that changes nothing. On the lines of a megabyte it is
the median of five more series of 41, taking turns, as the series of 21 had runs of 3 ms and of 6 ms in both versions; in the
middle and at the end of the word of a megabyte, it takes 0.4 to 0.5 ms more in each of the five. What changed, in [Inside Cemacs](internals.md#the-indent):

- Enter split the line into its characters, one text each, to cut it at the cursor, and read them again for the place of the
  new line: 1.5 s on the megabyte of code. It cuts the line at the byte of the cursor now and reads it by its bytes, and the
  place of the new line reads its first two tokens only. What is left at the start of the line of code is the state of the
  colours at the end of the line, which moves down, 63 ms; at the start of the word, its first token, a name of a megabyte,
  walked a byte at a time. Before the cursor, the indent reads the line whole, for the brackets, texts and comments open
  there and the blocks the line opens and closes: at the end of the megabyte of code, its 233,000 tokens take 0.3 s, at
  about 300 ns a byte, and the blocks 0.08 s.
- Tab read its statement twice when the cursor was at the end of a word, once to know whether to complete it, and by its
  characters; once now, by its bytes. It reads the whole statement wherever the cursor is, as `cesia fmt` places a statement
  as a whole: 0.37 s on the megabyte of code. On a line of 10,000 ifs, each if looked for the arrows in the rest of the line,
  seconds; the line is looked through once now.
- `end`: each letter typed in the first columns of a line read all the characters of the rest of the line, twice, to know
  whether its first word moves the line; it reads them now only as far as its spaces and six characters. At the end of the
  line of code, the letters take what letters take there, above.

At line 500 of `core/view/view.ce`, at its first column and at its tenth, three series of 41 taking turns, Enter takes 1.0 to
1.1 ms, Tab 1.0 to 1.2 ms, `C-j` 0.5 ms and `end` 1.6 to 2.0 ms, in both versions; `x` and backspace 0.8 to 0.9 ms, `C-e` 0.5
ms and `hello` 2.5 to 2.6 ms, in both too. The tokens of its 1,065 lines take 11.2 to 11.4 ms before and 11.4 to 11.6 now in
those series, and 11.4 to 11.8 ms in both versions in three series of 201 of the tokens alone.

The colours now keep stops for the state at the end of a long line too, [Inside Cemacs](internals.md#the-colours): after a
key, the state that the lines under the line start from is read from the last stop before the edit, where the whole line was
read again. The keys on the line of a megabyte of code inside a block, as in the table above, `x` and backspace too, this
version and `main` at 03e7a09 taking turns, $n = 21$, three series, the middle of their medians in milliseconds, before → now:

| Place on the code of 1 MB | `x` | backspace | `end` | Enter | Tab |
|---|---|---|---|---|---|
| start | 80.3 → 80.5 | 75.7 → 76.0 | 244 → 245 | 80.6 → 16.5 | 377 → 376 |
| middle | 94.0 → 66.1 | 94.0 → 65.5 | 278 → 191 | 267 → 238 | 374 → 375 |
| end | 94.8 → 27.1 | 94.9 → 27.2 | 279 → 74.6 | 443 → 379 | 374 → 374 |

At the far end, the state at the end of the line reads 64 KB at most, 2.5 ms instead of 67, and the stops of the row and those
of the colours are looked at from the first and the last, which holds there: two slices of the line instead of four. What a
letter takes there now is the crossing of the row from its last stop, the key and its frame. Enter at the start moves the line
down as it is, and its stops hold: 16.5 ms instead of 80.6. In the middle, the state at the end reads the half of the line
after the edit. At the start, a letter and backspace change the first bytes of the line, and `end` and Tab move it, so no stop
holds and the line is read whole for the state at its end, as before; Enter and Tab at the far end are the indent, which reads
the whole line.

On a file of usual lines nothing is slower: at line 500 of `core/view/view.ce`, the keys of both tables take what they took,
0.5 to 2.5 ms, and the tokens of its lines 11.8 to 12.2 ms in both versions. The states of 45,650 lines of Cesia, read by
[color.ColoredTo] from none known, as a jump to the end of a large file reads them, take 60 to 62 ms at the fastest in
both versions, the two modules in one process taking turns; [color.StateAfter] alone on each of them takes 2 to 3 % more, one
call more, and only a screen whose colours are guessed reads its lines with it. On the file of 99.9 MB of lines of a
megabyte of code, the colours keep one line, with its text, and 14 stops: the process holds 562 MB after 20 letters at the
far end of its line 50, 589 MB with the version before, as each letter left a reading of the whole line behind it.

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

A save of a file of Cesia goes through `cesia fmt`, as [Files and buffers](files.md#saved-as-cesia-fmt-writes-it) tells. A file
of 2,000 lines, a key typed in its line 1,000, then `C-x C-s`, $n = 21$, taking turns: 60.3 ms through `cesia fmt`, 56.6 at
the fastest, against 8.1 ms, 6.5 at the fastest, for the same save without it. The 52 ms are the start of `cesia fmt` and
its reading of the file twice, once to place each line and once to check that the program reads the same: under the tenth
of a second where a key still feels at once, and only at a save.

## The folder manager

A folder of 10,000 files, the first file's buffer current, medians of 21 passes, each with `commands.Settled` as the editor
calls it after each event, this version and `main` at 3cc0974, before the keys of Dired, taking turns:

| Step | This version: median of 21 | Fastest, slowest | Before |
|---|---|---|---|
| opening the folder, `C-x d` | 102 ms | 100, 114 ms | 98 ms |
| `/` then the first letter, `9`, which keeps 3,439 rows; before, the letter alone | 9.4 ms | 8.8, 11.2 ms | 11.3 ms |
| a second letter, `9` again, filtering the rows shown | 4.2 ms | 3.9, 5.3 ms | 4.0 ms |
| `m`, the first mark, which makes the row of each name | 10.8 ms | 8.4, 19.3 ms | |
| `m`, a second mark | 5.2 ms | 4.7, 11.8 ms | |
| `t`, 10,000 marks at once | 63 ms | 50, 82 ms | |
| `s`, the rows sorted by date, from the entries read | 68 ms | 63, 73 ms | |

The script made the folder, 10,000 files named `file-1.ce` to `file-10000.ce`, then timed [folders.Open] with
[commands.Settled], and the keys through [commands.Update], as the window sends them. Opening reads the folder once: one
listing and one look at each of the 10,000 entries, then the rows and their colours. The mode, which the rows show since
this version, costs 4 ms of the 102: [folders.Rows] makes the part of each mode, size and age once, for the first row that
has it, and the rows share it, where a part made for each row cost 20 ms more. A letter filters the rows read then, from
those already shown when the filter only grew; [A case: finding a file from a few letters](finding.md#speed-each-letter-answers-at-once)
measures the filter on 1,933 rows: 288 letters typed in 210 ms against 402 before it found each letter natively. A mark
makes its row again, and the list its text, without reading the folder.

The keys of Dired add about 1,900 lines to `src/folders`, which Cemacs loads at its start: the start to the first frame,
SDL's dummy driver, the packages of `src/cemacs.ce`, $n = 21$, taking turns, 30.0 ms [29.8, 30.3] against 29.0 ms [28.9,
29.3] for `main` at 3cc0974. The bodies of their functions are read at their first call only, as
[How Cesia works](https://www-celestial.github.io/cesia-lang/internals.html#the-cache-of-loaded-packages) tells, so the
1 ms is the reading of their names and parameters.

## The check

`cesia check --json --stdin` of `core/commands/commands.ce`, 1,160 lines, as Cemacs runs it, $n = 10$: 28.8 ms [26.7, 31.5].
So the marks of an error come about 30 ms after the half second of pause that starts the check. It runs in its own process,
from a fiber: the editor doesn't wait for it, and typing goes on.

## The questions of src/ide

The keys of [Names](names.md), of [the search of a project](search.md#searching-a-project), of [Git](git.md) and of
[the tests](running.md#tests) each ask `cesia lsp`, which runs from the first of them, or a program, which Cesia starts,
loads and runs: the cost of a key is that message or that process, in the background, never a key that types. Each
question as Cemacs asks it, on Cemacs's own code, the name `text.Place` in the line `b = text.Place(at.Line, at.Column,
current(s))` of `core/commands/commands.ce`, a file of 1,636 lines, $n = 21$, taking turns, the median and the fastest:

| Question | Asked of | Median | Fastest |
|---|---|---|---|
| `M-.`, the definition | `cesia lsp`, running | 0.80 ms | 0.71 ms |
| `C-c c i`, the documentation, and the signature of a call | `cesia lsp`, running | 0.70 ms | 0.65 ms |
| the same after the text of the buffer changed: the server reads it again | `cesia lsp`, running | 8.79 ms | 2.97 ms |
| the first question of the session, the start of the server included | `cesia lsp` | 20.6 ms, once | |
| `M-?`, the references: 33 places in 13 files | `cesia lsp`, then `tools/lookup.ce` | 154.6 ms | 123.8 ms |
| `C-x p g`, the lines that hold `text.Place` | `tools/grep.ce` | 11.2 ms | 9.7 ms |
| `C-x g`, the state of Git | `tools/git.ce` | 11.6 ms | 10.5 ms |
| `C-c g l`, the log | `tools/git.ce` | 15.6 ms | 14.1 ms |
| `C-c t t`, what to test, before `cesia test` runs | `tools/testing.ce` | 4.8 ms | 4.4 ms |

Asked as a program at each key, a definition took 17.2 ms, 16.0 at the fastest: `cesia lsp`, which runs for the session,
answers twenty times faster, and is Cesia's own way to tell where a name is defined. About 3 ms of each program is the
start of Cesia, and most of the rest the load of its package. The references read every file of the project that holds the name, and each top-level definition that holds it
once more for each of its reads, as [Names](names.md#the-references) tells: that is where their time goes, a sixth of a
second for a name read in 13 files.

These programs and their packages hold about 2,000 lines of Cesia, which none of the editor loads at its start. Built first
as apps loaded at the start, they made it 8.7 ms longer, the fastest of 21 starts 96.5 ms against 87.9 ms for the version
before them, as Cesia's load grows faster than the code it reads. Asked at each key, they leave at the start their keys and
the app that asks, [src/ide], 460 lines, with the history and the completion of the prompt, 130 lines of
[core/commands]: the fastest start 82.0 ms against 79.1 ms, the median 88.7 ms against 85.1 ms, $n = 21$, taking turns, the
heavy lock held on a machine shared with other work. A key typed in a file of Cesia of 2,000 lines, the update, the view and
the frame of a window of 1280 by 720 with no vsync, 21 samples of 50 keys: 5.72 ms against 5.86 ms, the same.

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
- A key at the far end of a line of a megabyte takes 0.03 s when the line is code and 0.09 s when it is one word: the
  colours of a line are read from its start to the screen, as a comment or a text opened before changes them, by its comments
  and texts, from the last place kept before the edit, and a long word a byte at a time; the state at the end of the line is
  read from the last place kept before the edit too, so a letter at the start of a line of code, which changes the line from
  its start, reads the line whole for it, 0.08 s; see [A key on a very long line](#a-key-on-a-very-long-line). At the start
  of a line of one word, a key takes what it takes on a short line, under 20 ms with the frame, and `M-f` crosses a word of
  32,000 letters in 25 ms instead of 36 s. In a file of Cesia, Enter there takes 0.02 s at the start of a line of code, 0.09 s at the start of a
  word, and up to 0.38 s at its end, and Tab 0.09 to 0.37 s: the indent reads the line by its bytes, up to the cursor for
  Enter and whole for Tab, as `cesia fmt` places a statement as a whole, at about 300 ns a byte of code.
