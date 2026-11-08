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
| Cemacs, in its window | 49.5 ms [49.2, 50.3] |
| GNU Emacs 31.1, `emacs -Q -nw` | 86.4 ms [85.4, 87.3] |
| Neovim 0.12.6, `nvim --clean -n` | 13.6 ms [13.5, 14.2] |
| Vim 9.2, `vim --clean -n` | 9.2 ms [9.1, 9.4] |

Each editor started with no configuration of the user, and was told to draw its screen and quit: `--eval '(progn (redisplay
t) (kill-emacs))'` for Emacs, `'+redraw!' '+qa!'` for Neovim and Vim. Each run is the time of the process, from its start to
its end, as a program of Python inside the terminal timed it.

Loading every package of Cemacs and building its config, with no window, takes 30.1 ms [29.6, 30.9], n = 20, measured the
same way. These 30 ms hold Cesia's own start, and the reading and preparing of the 5,582 lines of Cemacs's code and of the
packages of Cesia they use. The rest is SDL3 and SDL3_ttf: the window, the three fonts, and the first frame drawn in pixels.
Vim and Neovim win here by far: programs of C compiled to machine code, which draw characters into a terminal.

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

Keys() = help.WithHelp(dict.Merge(dict.Merge(dict.Merge(dict.Merge(emacs.Keys(), buffers.Keys()), folders.Keys()), check.Keys()), output.Keys()))
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

From the command to the first frame, with the file given, n = 10; the files are Cesia's standard library put end to end, and
the last line holds a word found nowhere else, for [search](#search):

| File | Cemacs | GNU Emacs 31.1 | Neovim 0.12.6 | Vim 9.2 |
|---|---|---|---|---|
| 0.79 MB, 22,430 lines | 66.5 ms [64.8, 68.7] | 96.6 ms [94.2, 102] | 21.6 ms [20.7, 28.2] | 17.6 ms [17.1, 18.6] |
| 15.8 MB, 448,562 lines | 206 ms [203, 214] | 142 ms [140, 150] | 54.4 ms [53.4, 59.1] | 50.4 ms [49.5, 54.3] |
| 100 MB, 2,840,882 lines | 904 ms [886, 955] | 380 ms [379, 395] | 229 ms [227, 231] | 237 ms [234, 238] |

The other editors don't know Cesia, so they show these files as plain text, where Cemacs colours the lines on the screen.
Emacs was told not to ask before a large file, `(setq large-file-warning-threshold nil)`; Neovim and Vim were started with
`-n`, which makes no swap file. Before this version, Cemacs took 281 ms [277, 298] for the 0.79 MB and 4,280 ms [4,213,
4,368] for the 15.8 MB, measured the same way on the same files, and refused the 100 MB.

What opening costs, measured alone, without the window, n = 5 (median, then fastest and slowest):

| Step | 15.8 MB | 100 MB |
|---|---|---|
| reading the file from the disk, `sys.Read` | 11.6 ms (10.1, 15.3) | 45.0 ms (44.5, 45.2) |
| the check of UTF-8 and of zero bytes, [files.IsText] | 52.2 ms (48.2, 70.0) | 296 ms (288, 303) |
| the rope, [rope.Of] | 75.3 ms (70.6, 109) | 458 ms (451, 465) |
| the peak of memory of the process, `VmHWM` | 62 MB | 269 MB |

Before this version, the check took 3,962 ms (3,883, 3,984) for the 15.8 MB, the rope 159 ms, and the memory went up to 540
MB: the check made a list of every byte of the file, each byte a value of its own, and walked it with a loop of Cesia. Now:

- [files.IsText] reads the file one piece of 1 MiB at a time, and has each piece checked by Cesia's lexer, in OCaml, as
  [Files and buffers](files.md#encodings) tells: about 3 ns a byte, and a few MiB of memory whatever the size.
- [rope.Of] cuts the leaves one after the other, so that each byte is copied once, where it cut the text in halves and
  copied all of it again at each level. Most of its time is counting the line ends of each leaf, with [text.Split]: about
  3.2 ns a byte, 320 ms of the 458 for 100 MB.

The other editors still open a large file faster: they read the bytes and find the line ends in C, at memory speed, and
Neovim and Vim don't check UTF-8 before they show the file. Cesia has no function yet that checks UTF-8 or counts the line
ends of a text in one call. Written in OCaml, eight bytes at a time, each takes about 25 to 35 ms for 100 MB, measured on this
machine: with both, opening 100 MB would take about 300 ms, between Neovim and Emacs.

## Typing and scrolling

`bench/gate.ce` measures the core and the frame on a text of 20,000 lines, Cesia's standard library repeated, in a window
of 1920 by 1080 at 13 points, without vsync: 300 passes of one typed character at line 19,000, then 300 passes of one
scrolled line, each pass made of `view.FollowState`, `view.View` and `sdl.Frame`. It prints the median and the worst pass:

```bash
SDL_VIDEODRIVER=dummy cesia run --allow read,ffi=SDL3,ffi=SDL3_ttf bench/gate.ce
```

Three runs of this version, each after a run of the version before it, `main` at c8c6dda, on the same machine:

| Run | One typed character at line 19,000: median, worst | One scrolled line: median, worst | First jump to line 19,000 |
|---|---|---|---|
| 1 | 10.5 ms, 26.2 ms | 15.5 ms, 20.3 ms | 344 ms |
| 2 | 10.2 ms, 14.5 ms | 15.5 ms, 23.1 ms | 338 ms |
| 3 | 10.3 ms, 17.7 ms | 15.4 ms, 21.4 ms | 340 ms |
| before, 1 to 3 | 11.7, 11.3, 11.4 ms | 16.4, 16.0, 16.2 ms | 631, 626, 632 ms |

- A key costs about 10.3 ms from the state to the frame, under the 16 ms of one frame at 60 a second: 0.2 ms to follow the
  cursor, 2.4 ms to make the frame's commands, and about 7.2 ms for SDL to draw them in software. The size of the file doesn't
  count: only the lines on the screen are read. The frame's commands took 3.5 ms before: reading a line of the rope made new
  nodes, two splits and their joins, where it now only reads the leaves; see [Inside Cemacs](internals.md).
- Scrolling at 15.4 to 15.5 ms a line is 64 to 65 lines a second, over the goal of 60. The worst of the 300 passes takes up
  to about twice the median; the gate doesn't tell which part made it slow.
- The first jump to line 19,000 costs 0.34 s, once: the colours of the lines before it are read then, 19,000 lines read from
  the rope. After that, they are known.
- The gate's own opening, about 38 ms for 2.8 MB, makes the rope and the first frame from a text already in memory: it
  doesn't read a file, and doesn't check its UTF-8, which is what [opening a file](#opening-a-file) above costs.
- Making the rope of the whole text, `rope.Of`, takes 2.7 ms, 6.5 ms before.

The time from a key to the screen is not compared with the other editors: measuring it honestly needs a camera, or a tool
that watches the screen, such as Typometer, and none was used. These numbers are Cemacs's own, inside the program.

## Search

Cemacs has no search in a buffer. The others, measured in one process each, the file of 15.8 MB loaded and the cursor at its
start, for one search of a word found only on its last line, n = 10: Emacs's `search-forward` in `emacs --batch`, 7.7 ms
[7.4, 7.9]; Neovim's `search()` in `nvim --headless`, 29.3 ms [28.2, 30.3]; Vim's `search()` in `vim -es`, 35.5 ms
[32.9, 38.6].

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
from those already shown when the filter only grew.

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

With a large file open, 8 seconds after the start, the RSS, n = 3:

| Editor | 15.8 MB open | 100 MB open |
|---|---|---|
| Cemacs | 127 MB | 401 MB |
| GNU Emacs 31.1 | 71.3 MB | 152 MB |
| Neovim 0.12.6 | 40.2 MB | 137 MB |
| Vim 9.2 | 36.3 MB | 133 MB |

Before this version, Cemacs held 631 MB with the 15.8 MB open, and refused the 100 MB. It now holds about four times the
file beside the 46 MB it takes empty: the rope, the text as read, which the collector has freed but the process keeps for
its next allocations, and its leaves and nodes, two small records of six fields for each 1,024 bytes. The others hold the
file once, about, with a little for each line.

The processor at rest, over 10 seconds, in percent of one core, n = 3:

| Editor | Processor at rest |
|---|---|
| Cemacs | 2.1 % |
| GNU Emacs 31.1 | 0.0 % |
| Neovim 0.12.6 | 0.0 % |
| Vim 9.2 | 0.0 % |

The time is what the system counted for every process of the editor, in hundredths of a second, so 0.0 % is less than
0.1 %. A still Cemacs draws no frame, but its loop looks for events every 5 milliseconds, and sleeps between: that is its
2 %. The others sleep until the system wakes them with an event, and cost nothing while you read. Cemacs draws a frame at
each pass while a program runs, a check runs or is due, or a prefix key waits for its band of hints.

## Limits

- A file larger than 1 GiB isn't opened: one of 1 GiB takes about three times its size in memory at its peak.
- The undo history keeps 1,000 states per buffer, and the output of a program its last 1,000 lines.
- A frame holds at most 8,192 pieces of text.
- One check runs at a time, for one buffer.
