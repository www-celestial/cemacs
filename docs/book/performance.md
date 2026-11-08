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

From the command to the first frame, with the file given, n = 10; the files are Cesia's standard library put end to end:

| File | Cemacs | GNU Emacs 31.1 | Neovim 0.12.6 | Vim 9.2 |
|---|---|---|---|---|
| 0.78 MB, 22,165 lines | 264 ms [262, 266] | 93.3 ms [91.9, 95.1] | 20.5 ms [20.2, 20.9] | 17.4 ms [17.0, 17.8] |
| 15.8 MB, 450,669 lines | 4,178 ms [4,128, 4,304] | 137 ms [135, 140] | 53.5 ms [52.9, 55.4] | 50.0 ms [49.6, 50.9] |
| 100 MB, 2,844,381 lines, n = 5 | refused: above 16 MiB | 384 ms [373, 405] | 224 ms [222, 233] | 231 ms [228, 237] |

The other editors don't know Cesia, so they show these files as plain text, where Cemacs colours the lines on the screen.
Emacs was told not to ask before a large file, `(setq large-file-warning-threshold nil)`; Neovim and Vim were started with
`-n`, which makes no swap file.

Opening a file costs Cemacs about a quarter of a second per megabyte, and nearly all of it is one step: [files.IsText],
which checks that the file is valid UTF-8 before it is opened. When the file holds a character outside ASCII, it checks each
byte with a loop of Cesia; a file of ASCII only is checked natively, at once. Measured alone on the file of 15.8 MB, n = 5:

| Step | Median of 5 | Fastest, slowest |
|---|---|---|
| reading the 15.8 MB from the disk, `sys.Read` | 10.8 ms | 10.4, 11.9 ms |
| the check of UTF-8, `files.IsText` | 4,044 ms | 3,961, 4,243 ms |
| the rope, `rope.Of` | 163 ms | 160, 190 ms |

So every editor here opens a large file far faster than Cemacs: they read the bytes, and decode them as they need, in C. The
check of UTF-8 is the place to make Cemacs faster. For the goal of its first version, a file of about 20,000 lines opened in
under 300 ms, the file of 0.78 MB and 22,165 lines takes 264 ms with the start, so about 215 ms for the file itself.

## Typing and scrolling

`bench/gate.ce` measures the core and the frame on a text of 20,000 lines, Cesia's standard library repeated, in a window
of 1920 by 1080 at 13 points, without vsync: 300 passes of one typed character at line 19,000, then 300 passes of one
scrolled line, each pass made of `view.FollowState`, `view.View` and `sdl.Frame`. It prints the median and the worst pass:

```bash
SDL_VIDEODRIVER=dummy cesia run --allow read,ffi=SDL3,ffi=SDL3_ttf bench/gate.ce
```

Three runs:

| Run | One typed character at line 19,000: median, worst | One scrolled line: median, worst | First jump to line 19,000 |
|---|---|---|---|
| 1 | 12.1 ms, 21.8 ms | 14.7 ms, 32.5 ms | 638 ms |
| 2 | 12.2 ms, 20.4 ms | 14.4 ms, 27.2 ms | 676 ms |
| 3 | 11.8 ms, 21.7 ms | 14.4 ms, 20.9 ms | 631 ms |

- A key costs about 12 ms from the state to the frame, under the 16 ms of one frame at 60 a second: 0.3 ms to follow the
  cursor, 3.1 ms to make the frame's commands, and about 8 ms for SDL to draw them in software. The size of the file doesn't
  count: only the lines on the screen are read.
- Scrolling at 14.4 to 14.7 ms a line is 68 to 69 lines a second, over the goal of 60. The worst of the 300 passes takes up
  to about twice the median; the gate doesn't tell which part made it slow.
- The first jump to line 19,000 costs 0.63 to 0.68 s, once: the colours of the lines before it are read then. After that,
  they are known.
- The gate's own opening, about 40 ms for 2.8 MB, makes the rope and the first frame from a text already in memory: it
  doesn't read a file, and doesn't check its UTF-8, which is what [opening a file](#opening-a-file) above costs.
- Making the rope of the whole text, `rope.Of`, takes 6.6 ms.

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

With the file of 15.8 MB open, 12 seconds after the start, n = 3:

| Editor | RSS | PSS |
|---|---|---|
| Cemacs | 633 MB | 624 MB |
| GNU Emacs 31.1 | 71.6 MB | 64.4 MB |
| Neovim 0.12.6 | 40.4 MB | 29.6 MB |
| Vim 9.2 | 36.3 MB | 33.5 MB |

Cemacs holds about 40 times the size of the file, where the others hold about twice. The text and its rope take about 120 MB:
a program of Cesia that only reads the file and makes its rope has an RSS of 120 MB. The check of UTF-8 raises it to 618 MB:
it makes an array of every byte of the file to walk through, and the process keeps that memory afterwards, as the editor
still held it 12 seconds after the start.

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

- A file larger than 16 MiB isn't opened.
- The undo history keeps 1,000 states per buffer, and the output of a program its last 1,000 lines.
- A frame holds at most 8,192 pieces of text.
- One check runs at a time, for one buffer.
