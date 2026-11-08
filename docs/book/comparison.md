# Cemacs and other editors

This chapter puts Cemacs beside the editors that most programmers know: GNU Emacs 31.1, Neovim 0.12.6 and Vim 9.2, which
were installed on the machine where Cemacs is measured, and Visual Studio Code, by its published documentation only. It says
plainly where they win, and why. Cemacs is young and small, about 5,600 lines; each of them is the work of many people over
years, decades for Emacs and Vim.

## In numbers

Measured on one machine, as [Speed](performance.md) tells, with the method there: each editor started with no
configuration of the user, the three others in a terminal of 160 by 50 characters, Cemacs in its own window drawn by SDL's
dummy driver, into memory. Each number is the median of n runs, with its 95 % interval.

| Measure | n | Cemacs | GNU Emacs 31.1 | Neovim 0.12.6 | Vim 9.2 |
|---|---|---|---|---|---|
| start to the first frame | 20 | 49.5 ms [49.2, 50.3] | 86.4 ms [85.4, 87.3] | 13.6 ms [13.5, 14.2] | 9.2 ms [9.1, 9.4] |
| start and open 0.79 MB | 10 | 66.5 ms [64.8, 68.7] | 96.6 ms [94.2, 102] | 21.6 ms [20.7, 28.2] | 17.6 ms [17.1, 18.6] |
| start and open 15.8 MB | 10 | 206 ms [203, 214] | 142 ms [140, 150] | 54.4 ms [53.4, 59.1] | 50.4 ms [49.5, 54.3] |
| start and open 100 MB | 10 | 904 ms [886, 955] | 380 ms [379, 395] | 229 ms [227, 231] | 237 ms [234, 238] |
| search 15.8 MB for a word on its last line, finding it | 10 | 101 ms [99.6, 103] | 7.8 ms [7.4, 8.4] | 27.8 ms [27.7, 29.6] | 34.0 ms [32.9, 40.2] |
| search 100 MB for a word on its last line, finding it | 5 | 629 ms [626, 634] | 47.2 ms [46.7, 47.9] | 178 ms [173, 179] | 233 ms [225, 239] |
| the same, to the place shown, its colours read | 5 | 4,754 ms [4,731, 4,782] | | | |
| memory at rest, empty, PSS | 5 | 41.8 MB [41.7, 41.9] | 49.0 MB [48.0, 49.1] | 10.1 MB [9.8, 10.2] | 7.8 MB [7.7, 8.0] |
| memory with 15.8 MB open, RSS | 3 | 127 MB | 71.3 MB | 40.2 MB | 36.3 MB |
| memory with 100 MB open, RSS | 3 | 401 MB | 152 MB | 137 MB | 133 MB |
| processor at rest, % of one core | 5 | 0.0 % [0.0, 0.0], in a Wayland window | 0.0 % [0.0, 0.0] | 0.0 % [0.0, 0.0] | 0.0 % [0.0, 0.0] |

With n = 5 the interval is that of the fastest and the slowest run, at 93.75 %; with n = 3, only the median is given.

What they say:

- **Vim and Neovim start several times faster than Cemacs.** They are programs of C compiled to machine code, which start
  in a few milliseconds and draw characters into a terminal. Cemacs is a Cesia program: Cesia reads and prepares about
  5,600 lines of code at each start, then SDL3 opens a window, and SDL3_ttf loads three fonts and draws the first frame in
  pixels. Emacs, which loads its own Lisp at the start, is slower than Cemacs.
- **Cemacs opens a file of 0.79 MB faster than Emacs, but Vim and Neovim open a large file two to four times faster.**
  Cemacs checks that a file is valid UTF-8 before it opens it and counts the line ends of each leaf of its rope, both
  through functions of Cesia that copy the text on the way; the others read the bytes and find the line ends in C, at the
  speed of memory. Cemacs opens files of up to 1 GiB.
- **Every one of them searches a large file faster than Cemacs**: Emacs 13 times, Neovim and Vim 3 to 4 times, for the
  finding alone. Cemacs reads its rope a window at a time, joins it into one text, folds its case, then searches it; the
  others search their text in place, in C. To show a place far down, Cemacs also reads the state of the colours of every
  line above it, once: 4.8 s to the last line of 100 MB.
- **At rest, Cemacs uses memory of the order of Emacs, and four to five times that of Vim and Neovim**, which hold a
  terminal's characters where Cemacs holds a window, its fonts and the Cesia runtime. With a large file open, Cemacs holds
  about four times the file, the others about once: Cemacs's rope gives each 1,024 bytes two records, and the process keeps
  the memory of the text as it was read.
- **At rest, none of them uses the processor**: each sleeps until an event wakes it, Cemacs in SDL, the others on their
  terminal. Cemacs also wakes four times a second, for the fibers of Cesia.
- Typing is not compared: the honest measure of the time from a key to the screen needs a camera or a tool that reads the
  screen, such as Typometer, and none was used. Cemacs's own time from a key to a frame, inside the program, is in
  [Speed](performance.md#typing-and-scrolling).

## In features

Two words first. A language server is a program that knows one language and tells any editor the errors, the completions
and the definitions of its code, over the Language Server Protocol, LSP; a debug adapter does the same for a debugger, over
the Debug Adapter Protocol, DAP. An editor that speaks both gets every language that has a server and an adapter.

| | Cemacs | GNU Emacs 31.1 | Neovim 0.12.6 | Vim 9.2 |
|---|---|---|---|---|
| Where it runs | its own window, through SDL3 | a terminal, or its own window | a terminal; other programs can draw it through its API | a terminal, or its own window (gVim) |
| Keys | those of Emacs, with groups under `C-c` | its own | modal: one mode moves, another types | modal |
| Written in, changed in | Cesia, both | C and Emacs Lisp; changed in Emacs Lisp | C and Lua; changed in Lua or Vimscript | C; changed in Vim9 script or Vimscript |
| Change while it runs | its code reloads at each save under `cesia do dev`; a new package needs a restart | any Lisp, at any time, changes the running editor | `:source` and `:lua` run new code in the running editor | `:source` runs new code in the running editor |
| Finding a key | the band of hints after half a second, and `?` after any prefix key | `which-key-mode`, built in, off until turned on; `C-h k`, `C-h b` | none built in: plugins | none built in: plugins |
| A command by its name | none | `M-x` | `:` commands | `:` commands |
| Search and replace | incremental search, `C-s` and `C-r`, with Emacs's case folding; no regular expression, no replace | incremental search, by regular expression, replace | `/`, `:s` | `/`, `:s` |
| Errors of the code | Cesia's, from `cesia check`, half a second after a key | Flymake, built in, with a checker for each language | diagnostics of its LSP client | by plugins |
| Language servers (LSP) | no client; Cesia's errors come from `cesia check` | Eglot, built in | a client built in, `vim.lsp` | channels that speak LSP's encoding; the client is a plugin |
| Debugger | built in, for Cesia, with breakpoints, steps, evals, fix and continue | GUD, built in, for gdb and other debuggers | none built in: plugins | Termdebug, built in, for gdb; channels that speak DAP's encoding |
| Undo | linear, with redo, 1,000 states | an undo is recorded as an edit, so an undo can be undone; `undo-redo` | a tree of every state | a tree of every state |
| Encodings | UTF-8 only | many | many | many |
| Large files | opens up to 1 GiB | asks above 10 MB, then opens | opens | opens |
| Saves of its own | none: no autosave, backup or swap file | autosave files and backups | swap files | swap files, and backups if asked |

The features of Emacs, Neovim and Vim were checked on the installed programs: Eglot, Flymake, GUD and `which-key` load in
Emacs 31.1 with no package added, and `large-file-warning-threshold` is 10,000,000; `vim.lsp` is in Neovim 0.12.6; Vim 9.2
has the `lsp` and `dap` modes of its channels and the Termdebug package in its runtime.

**Visual Studio Code**, by its documentation, is a window of its own, extended by extensions written in TypeScript or
JavaScript against its extension API, and it debugs through debug adapters that speak the Debug Adapter Protocol, so that
one interface serves any debugger that has an adapter. Cemacs's debugger, by contrast, speaks a small protocol of its own
with one debugger, Cesia's: [Running and debugging](running.md#how-cemacs-speaks-with-the-debugger).

## Where Cemacs stands

What Cemacs does that they don't do out of the box:

- **It is changed in the language it edits.** A Cesia programmer changes Cemacs with what they already know, and the
  examples of this book run against its real code. Emacs is the model here, with Lisp.
- **Its debugger and its errors need nothing to set up.** Under the others, a debugger for a new language needs an adapter
  or a plugin; Cemacs knows Cesia's.
- **Its keys show themselves.** The band of hints is on from the start, and `?` after any prefix key lists what follows.

What they do that Cemacs doesn't, and why it matters:

- **Search by regular expression and replace, completion, a command by name, other languages and encodings, a terminal
  inside.** Cemacs has none yet, beside its incremental search: it is a young editor for one language, and grows when its
  use asks.
- **Speed at the start and on large files.** Native code that reads and scans the bytes of a file at the speed of memory.
- **Safety of the text.** Emacs, Vim and Neovim keep a copy of what you type on disk, so a crash loses little; Cemacs keeps
  it in memory only.
- **Maturity.** Their code has run for decades, on many systems; Cemacs is tried on Linux, by its author and its tests.
