# Speed

This chapter gives what Cemacs costs in time and memory, how each number was measured, and why it is what it is. Cemacs
keeps four goals since its first version, for a file of 20,000 lines in a window of 1920 by 1080: a key to its frame under
16 ms, the time of one frame at 60 frames a second; scrolling at 60 lines a second; opening under 300 ms; and no frame at
all from an editor that waits. Each section puts Cemacs beside GNU Emacs 31.1, Neovim 0.12.6 and Vim 9.2 where the same
thing can be measured on them; [Cemacs and other editors](comparison.md) gathers the numbers and the features.

## How it was measured

- **The machine:** an Intel Core i7-4720HQ, 4 cores and 8 threads at 2.6 GHz, its frequency left to the system; 11 GB of
  memory; Arch Linux, Linux 7.2.11. Cesia 1.0.0+dev, SDL3 3.4.18, SDL3_ttf 3.2.2, tmux 3.8.
- **Alone:** each measure ran while no other heavy job of the machine did, under one lock that the heavy jobs share.
- **The window:** SDL's dummy driver, `SDL_VIDEODRIVER=dummy`, which draws into memory with SDL's software renderer and
  shows nothing. A real screen adds the work of the graphics driver and the compositor, and vsync, which this driver
  doesn't have. The other editors ran in a terminal of tmux, 160 characters by 50, which answers the questions they ask a
  terminal at their start as a real one does.
- **The numbers:** each measure was run n times, as said beside it, the editors taking turns. The number given is the
  median, the middle run, which one slow run can't move as it moves a mean. The 95 % interval after it, as [49.2, 50.3], is
  between two runs of the sorted list, chosen so that the true median lies between them with a probability of at least
  95 %, whatever the distribution of the times: with n = 20, the 6th and the 15th; with n = 10, the 2nd and the 9th. With
  n = 5, the fastest and the slowest are the best there is, at 93.75 %; with n = 3, only the median is given.
- **The scripts** are on this page or in `bench/`, so that anyone can run them again.

## Start-up

From the command to the first frame of the window, with one empty buffer, n = 20:

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
measured later beside the version before it, at 8ee42e7, taking turns, n = 11, 53.2 ms [52.7, 54.7] against 54.1 ms [53.7,
55.4], no slower.

Where the 51 ms go, with the dummy driver, each part timed from the one before by the program below with a mark after each part, n = 20,
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
program. `--no-spec` and `--no-jit` don't change it: 30.8 and 30.4 ms against 30.5 for the load alone, n = 20. Loaded alone,
with what each uses, n = 20: the packages of Cesia that Cemacs uses, 4.3 ms; `src/ui`, 5.1; `src/sdl`, 6.5; `core/commands`
and all it uses, 26.6; all of Cemacs, 31.1 ms. About 600 of the lines read are never used by the editor: widgets and kinds
of drawing of `src/ui` and `src/sdl` that only their tests use.

In a real window, the start costs far more, and most of it is not Cemacs's. Measured in a Wayland window of SDL's Wayland
driver, in GNOME's compositor run headless, `mutter --headless --wayland --no-x11 --virtual-monitor 1280x720`, which shows
nothing on a screen, n = 10: 236 ms [232, 241], 237 ms [229, 244] for the version before. Of these, SDL's video starts in
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

From the command to the first frame, with the file given, n = 11, this version and the one before it, `main` at 8ee42e7,
taking turns with the three others; the files are Cesia's standard library put end to end, and the last line holds a word
found nowhere else, for [search](#search):

| File | Cemacs | Cemacs before | GNU Emacs 31.1 | Neovim 0.12.6 | Vim 9.2 |
|---|---|---|---|---|---|
| 0.79 MB, 22,490 lines | 66.0 ms [64.3, 71.0] | 69.3 ms [68.0, 72.0] | 96.5 ms [94.2, 97.5] | 21.2 ms [20.8, 21.8] | 17.4 ms [17.1, 17.8] |
| 15.9 MB, 449,762 lines | 125 ms [124, 126] | 199 ms [198, 202] | 141 ms [139, 147] | 53.4 ms [53.0, 55.4] | 50.0 ms [49.7, 52.5] |
| 99.9 MB, 2,833,490 lines | 414 ms [409, 422] | 849 ms [843, 931] | 377 ms [375, 378] | 228 ms [225, 253] | 236 ms [234, 253] |

The other editors don't know Cesia, so they show these files as plain text, where Cemacs colours the lines on the screen.
Emacs was told not to ask before a large file, `(setq large-file-warning-threshold nil)`; Neovim and Vim were started with
`-n`, which makes no swap file. Two versions before, Cemacs took 281 ms for a file of 0.79 MB and 4,280 ms for one of 15.8
MB, on the files of then, and refused one of 100 MB.

What opening costs, measured alone, without the window, n = 11, this version and the one before taking turns:

| Step | 15.9 MB | 99.9 MB | 99.9 MB, the version before |
|---|---|---|---|
| reading the file from the disk, `sys.Read` | 10.2 ms [10.1, 10.4] | 43.8 ms [43.4, 44.4] | 44.3 ms [44.2, 44.8] |
| the check of UTF-8 and of zero bytes, [files.IsText] | 10.3 ms [9.5, 10.3] | 59.9 ms [58.8, 61.6] | 255 ms [253, 267] |
| the rope, [rope.Of] | 33.7 ms [32.7, 35.4] | 230 ms [229, 233] | 458 ms [456, 473] |
| the peak of memory of the process, `VmHWM` | 69.7 MB | 246 MB | 263 MB |

What changed:

- [files.IsText] is two calls of Cesia's standard library on the whole text, in place: [text.Count] of its zero bytes, 34.5
  ms [34.3, 35.2] for 99.9 MB, and [text.IsUtf8], 24.2 ms [24.2, 25.4], both working eight bytes at a time, as
  [Files and buffers](files.md#encodings) tells: 0.6 ns a byte. The version before had no function of Cesia that checks
  UTF-8: it gave the text, one piece of 1 MiB at a time, to Cesia's lexer, which checks UTF-8 before it reads a program,
  copying each piece twice on the way: 2.6 ns a byte. [text.ByteFind] of the zero byte, which the version before used,
  takes 87.3 ms [86.8, 90.4] for the same text: it looks at one byte at a time.
- [rope.Of] counts the line ends of each leaf with [text.Count], where it cut each leaf into its lines with [text.Split]
  and counted them. What is left of its 230 ms is the making of the tree itself: 97,540 leaves of 1,024 bytes, each a slice
  of the text and a record of six fields, then as many nodes, joined two by two, all in Cesia.

The others still open a large file faster: Emacs 99.9 MB in 0.91 of Cemacs's time, Neovim and Vim in 0.55 and 0.57; at
15.9 MB Cemacs is now ahead of Emacs, and Neovim and Vim take 0.43 and 0.40 of its time. All four test UTF-8 as they read a file
([Files and buffers](files.md#encodings) says how the others differ on a file that fails), so that is no longer where the
time goes: Neovim and Vim fill blocks of lines in C, and Emacs copies the text into one gap buffer and keeps no index of
lines, where Cemacs makes a tree of records in Cesia. On a small file, the start is the difference, as
[Start-up](#start-up) tells: Cesia reads and prepares about 7,000 lines of Cemacs's code at each start.

## Typing and scrolling

`bench/gate.ce` measures the core and the frame on a text of 20,000 lines, Cesia's standard library repeated as the binary of
Cesia carries it, [cesia.Libraries], in a window
of 1920 by 1080 at 13 points, without vsync: 300 passes of one typed character at line 19,000, then 300 passes of one
scrolled line, each pass made of `view.FollowState`, `view.View` and `sdl.Frame`. It prints the median and the worst pass:

```bash
SDL_VIDEODRIVER=dummy cesia run --allow read,ffi=SDL3,ffi=SDL3_ttf bench/gate.ce
```

Three runs of this version, each after a run of the version before it, `main` at c8c6dda, on the same machine and on the
same text:

| Run | One typed character at line 19,000: median, worst | One scrolled line: median, worst | First jump to line 19,000 |
|---|---|---|---|
| 1 | 13.6 ms, 22.7 ms | 22.1 ms, 34.2 ms | 27.4 ms |
| 2 | 13.7 ms, 23.2 ms | 22.0 ms, 37.7 ms | 25.1 ms |
| 3 | 14.1 ms, 27.2 ms | 21.8 ms, 37.0 ms | 25.0 ms |
| before, 1 to 3 | 14.7, 14.6, 15.0 ms | 23.3, 22.9, 23.3 ms | 667, 660, 658 ms |

The text changed with this version: the gate read the files of a clone of Cesia's repository beside Cemacs, which the
machines that test Cemacs don't have, and now reads the packages that the binary of Cesia carries. They lack two files of
the repository that are nearly all comments, so the lines on the screen at line 19,000 hold more code, more words to draw:
on the text of the files, a key took 10.3 ms with this version and 11.4 before, a scrolled line 15.4 and 16.3 ms.

- A key costs about 13.7 ms from the state to the frame, under the 16 ms of one frame at 60 a second: 0.2 ms to follow the
  cursor, 3.7 ms to make the frame's commands, and about 9.1 ms for SDL to draw them in software. The size of the file doesn't
  count: only the lines on the screen are read. The frame's commands took 4.8 ms before: reading a line of the rope made new
  nodes, two splits and their joins, where it now only reads the leaves; see [Inside Cemacs](internals.md).
- Scrolling at 22 ms a line is 45 lines a second on this text, under the goal of 60, as before: drawing the lines in
  software takes 17.5 ms of it, a new line on the screen making new images of its words. The worst of the 300 passes takes
  up to about twice the median; the gate doesn't tell which part made it slow.
- The first jump to line 19,000 costs 25 ms, once: the state of the colours at the start of each line before it is read
  then, and kept. It took 0.66 s before: each line was read alone from the rope, 13 µs a line, and each line holding a quote
  or a comment mark went through the whole lexer of colours. Now the lines come 100,000 at a time, from one slice of the rope,
  and [color.StateAfter] reads only the state, jumping from one quote or comment mark to the next with [text.ByteFind]: 1.2
  µs a line in all. A test checks that it gives the state of the lexer on 2,000 random lines from every kind of state.
- The gate's own opening, about 28 ms for the standard library four times over, 35 ms before, makes the rope and the first
  frame from a text already in memory: it doesn't read a file, and doesn't check its UTF-8, which is what
  [opening a file](#opening-a-file) above costs.
- Making the rope of the whole text, `rope.Of`, takes 2.8 ms, 6.5 ms before.

Measured again later with Cesia at a56fdd0, whose standard library, the text of the gate, has changed since: three runs of
the version that counts the line ends of each leaf with [text.Count], each after a run of the one before it, `main` at
8ee42e7: `rope.Of` 1.0, 1.0, 1.0 ms against 2.7, 2.7, 2.7; a key at line 19,000 11.5, 11.4, 11.8 ms against 11.4, 11.4,
11.4; a scrolled line 17.7, 18.4, 18.0 ms against 18.1, 17.9, 18.2, about 55 lines a second for both, still under the goal
of 60; the first jump 25.2, 25.7, 25.9 ms against 26.4, 25.4, 25.3. Only the making of the rope changed.

The time from a key to the screen is not compared with the other editors: measuring it honestly needs a camera, or a tool
that watches the screen, such as Typometer, and none was used. These numbers are Cemacs's own, inside the program.

## Search

One search of a word found only on the last line of the file, from its start: the others in one process each, the file
loaded, Emacs's `search-forward` in `emacs --batch`, Neovim's `search()` in `nvim --headless`, Vim's `search()` in `vim -es`;
Cemacs without a window, the file opened, then `C-s` and the word typed as one text through [commands.Update], up to the
state that shows the place, n = 10 for 15.8 MB and n = 5 for 100 MB:

| Measure | 15.8 MB | 100 MB |
|---|---|---|
| GNU Emacs 31.1, `search-forward` | 7.8 ms [7.4, 8.4] | 47.2 ms [46.7, 47.9] |
| Neovim 0.12.6, `search()` | 27.8 ms [27.7, 29.6] | 178 ms [173, 179] |
| Vim 9.2, `search()` | 34.0 ms [32.9, 40.2] | 233 ms [225, 239] |
| Cemacs, finding the place, [rope.Find] alone | 101 ms [99.6, 103] | 629 ms [626, 634] |
| Cemacs, `C-s` and the word, to the place shown | 692 ms [687, 722] | 4,754 ms [4,731, 4,782] |
| Cemacs, the same typed one letter at a time | 699 ms [695, 708] | 4,883 ms [4,845, 4,887] |
| Cemacs, `M->` alone, the colours down to the last line | 598 ms [590, 704] | 4,169 ms [4,163, 4,215] |

The word has no capital, so every search here folds case. Finding the place costs Cemacs about 6 ns a byte: each window of
the rope is joined into one text, put in lower case, then searched natively; Emacs searches its buffer in place, in C, with
the case folded in its tables, about 0.5 ns a byte. Most of the time to the place shown is not the search: it is the state of
the colours of every line before the last one, which a jump to a line far down reads once, as `M->` does, 1.3 µs a line,
then keeps; a second search there costs only its finding. Typing the word one letter at a time costs little more, as each
letter looks again from the place found, and only the last letters go far. The others don't colour these files, or colour
only the lines on the screen from a guess of the state a little above them, as Vim does with its `syntax sync`.

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

`cesia check --json --stdin` of `core/commands/commands.ce`, 1,160 lines, as Cemacs runs it, n = 10: 28.8 ms [26.7, 31.5].
So the marks of an error come about 30 ms after the half second of pause that starts the check. It runs in its own process,
from a fiber: the editor doesn't wait for it, and typing goes on.

## At rest

An editor at rest, one empty buffer, 3 seconds after its start; the memory of every process of the editor, n = 5:

| Editor | RSS | PSS |
|---|---|---|
| Cemacs, `bin/cemacs`, dummy driver | 46.5 MB [46.4, 46.6] | 41.8 MB [41.7, 41.9] |
| GNU Emacs 31.1, `emacs -Q -nw` | 55.8 MB [55.7, 56.0] | 49.0 MB [48.0, 49.1] |
| Neovim 0.12.6, `nvim --clean -n` | 20.3 MB [20.3, 20.4] | 10.1 MB [9.8, 10.2] |
| Vim 9.2, `vim --clean -n` | 10.6 MB [10.5, 10.8] | 7.8 MB [7.7, 8.0] |

RSS, the resident set size, is the memory of a process that is in RAM, the libraries it shares with other programs counted
whole; PSS, the proportional set size, counts a shared page divided by the number of processes that share it, which is fairer
between programs. Cemacs holds the Cesia runtime, SDL3, SDL3_ttf, its three fonts and the window.

With a large file open, 8 seconds after the start, the RSS, n = 3, the editors taking turns:

| Editor | 15.9 MB open | 99.9 MB open |
|---|---|---|
| Cemacs | 125 MB | 444 MB |
| Cemacs, the version before, at 8ee42e7 | 128 MB | 391 MB |
| GNU Emacs 31.1 | 71.4 MB | 152 MB |
| Neovim 0.12.6 | 40.4 MB | 137 MB |
| Vim 9.2 | 36.3 MB | 133 MB |

Cemacs holds about four times the file beside the 46 MB it takes empty: its rope, the leaves and nodes, two small records of
six fields for each 1,024 bytes; the whole text once more, which [the check](check.md#what-runs) gives to
`cesia check`; and the memory that the collector has freed but the process keeps for its next allocations. The others hold
the file once, about, with a little for each line.

With 99.9 MB open, this version holds 53 MB more at rest than the one before, though it makes less: up to its first frame
it holds less, 267 MB against 276, and the 53 MB come in the next two seconds. They are garbage of the open, not yet freed.
Cesia's memory is managed by the collector of OCaml, which frees what is no longer used a little at a time, at a pace set by
what the program makes; this version makes much less garbage as it opens a file, so the collector is less far in its work
when the editor goes quiet, and an editor at rest makes almost nothing to drive it on. Three measures, n = 3 each, show it:
a version with only the new check holds 447 MB, one with only the new rope 487 MB, which a cost of either change would not
give; and with the collector told to work harder, `OCAMLRUNPARAM=o=40` (the space overhead 40 % instead of OCaml's 120 %),
this version holds 380 MB and the one before 385. Cesia has no call that asks its collector to finish its work. With 15.9
MB open, the collector had finished, and this version holds 3 MB less.

The processor at rest, over 10 seconds, 3 seconds after the start, one empty buffer, in percent of one core, n = 5. The time
is what the system counted for every process of the editor, in hundredths of a second, so 0.0 % is less than 0.1 %:

| Editor, where | Processor at rest | Before this version |
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

From a key to the editor, in that Wayland window, n = 120 keys, 40 in each of 3 runs, a key every 0.25 to 0.5 seconds:

| From the key sent to | This version | Before |
|---|---|---|
| its event read by the update | 0.72 ms [0.71, 0.74] | 3.08 ms [2.45, 3.48] |
| the commands of its frame made | 1.13 ms [1.12, 1.14] | 3.39 ms [2.83, 3.91] |

The keys were sent as a remote desktop sends them, through the `RemoteDesktop` interface of mutter over D-Bus, and the time
of each starts just before that call, so it holds the call, mutter, Wayland and SDL. The editor wakes as soon as the key
comes, where it could sleep up to 5 ms before. The buffer was empty, so making the frame's commands was short; drawing them
then takes SDL's renderer, as in [Typing and scrolling](#typing-and-scrolling).

## Limits

- A file larger than 1 GiB isn't opened: one of 1 GiB takes about three times its size in memory at its peak.
- The undo history keeps 1,000 states per buffer, and the output of a program its last 1,000 lines.
- A frame holds at most 8,192 pieces of text.
- One check runs at a time, for one buffer.
