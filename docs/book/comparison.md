# Cemacs and other editors

This chapter puts Cemacs beside the editors that most programmers know: GNU Emacs 31.1, Neovim 0.12.6 and Vim 9.2, which
were installed on the machine where Cemacs is measured, and Visual Studio Code, by its published documentation only. It says
plainly where they win, and why. Cemacs is young and small, about 7,200 lines; each of them is the work of many people over
years, decades for Emacs and Vim.

## In numbers

Measured on one machine, as [Speed](performance.md) tells, with the method there: each editor started with no
configuration of the user, the three others in a terminal of 160 by 50 characters, Cemacs in its own window drawn by SDL's
dummy driver, into memory, or, where a row says OpenGL, in a Wayland window. Each number is the median of n runs, with its
95 % interval. Opening, search, paste, undo, save and memory were measured with the four taking turns; the keys and the
scrolled lines in a series for Cemacs and one for the others, the same afternoon.

| Measure | n | Cemacs | GNU Emacs 31.1 | Neovim 0.12.6 | Vim 9.2 |
|---|---|---|---|---|---|
| start to the first frame, with the next version of Cesia | 21; 20 for the others | 51.4 ms [50.8, 51.9] | 89.1 ms [88.3, 92.9] | 13.8 ms [13.6, 13.9] | 9.3 ms [9.2, 9.4] |
| the same with Cesia 1.1.0 | 21 | 57.7 ms [56.7, 58.5] | | | |
| start to the first frame, in a Wayland window, before this version | 10 | 236 ms [232, 241] | | | |
| start and open 0.79 MB | 7 | 66.9 ms [66.2, 71.0] | 98.4 ms [97.7, 109] | 20.5 ms [20.4, 42.7] | 18.0 ms [17.4, 19.8] |
| start and open 15.9 MB | 7 | 97.8 ms [97.1, 139] | 145 ms [142, 149] | 53.2 ms [52.8, 61.9] | 51.5 ms [50.4, 52.0] |
| start and open 99.9 MB | 7 | 266 ms [262, 281] | 393 ms [392, 460] | 235 ms [231, 317] | 247 ms [241, 294] |
| a typed key at line 19,000, inside, with its redraw | 7 | 2.6 ms [2.6, 3.2], OpenGL | 1.06 ms [1.04, 1.08] | 0.045 ms [0.042, 0.063] | 0.059 ms [0.056, 0.068] |
| a scrolled line, inside, with its redraw | 7 | 2.6 ms [2.5, 3.1], OpenGL | 1.51 ms [1.49, 1.60] | 0.020 ms [0.018, 0.030] | 0.052 ms [0.051, 0.083] |
| a typed key at line 1,416,745 of 99.9 MB, inside | 7 | 1.57 ms [1.41, 1.97], no drawing | 1.05 ms [1.04, 1.10] | 0.042 ms [0.042, 0.053] | 0.057 ms [0.052, 0.060] |
| Enter that indents, in a function at the middle of a file of 52 KB, of Python's 107 KB for the others, inside | 30 | 0.734 ms [0.701, 0.819], no drawing | 0.197 ms [0.191, 0.211] | 18.8 ms [18.2, 19.2] | |
| the same at the middle of 100.5 MB, of Python's 104.7 MB for the others | 30 | 0.832 ms [0.812, 0.859], no drawing | 201 ms [200, 205] | 3.78 ms [3.70, 3.86] | |
| the words that complete `co`, middle of 52 KB, of Python's 107 KB for the others, inside | 30 | 0.81 ms [0.79, 0.83], Tab, no drawing | 4.07 ms [4.00, 4.12], `dabbrev` | 1.51 ms [1.15, 1.85], `Ctrl-N` | |
| the same in 100.5 MB, of Python's 104.7 MB for the others | 30; 3 and 7 for the others | 1.43 ms [1.39, 1.47], from 128 KB | 23.2 s, the whole buffer | 948 ms [918, 995], the whole buffer | |
| search 15.9 MB for a word on its last line, finding it | 7 | 7.6 ms [7.4, 7.9] | 7.6 ms [7.4, 7.9] | 28.3 ms [27.7, 29.6] | 33.6 ms [32.4, 36.8] |
| search 99.9 MB for a word on its last line, finding it | 7 | 48.8 ms [48.4, 53.5] | 48.4 ms [47.8, 51.6] | 181 ms [179, 265] | 300 ms [290, 315] |
| the same, to the place shown | 7 | 87.6 ms [86.7, 88.6] | | | |
| paste of 1 MB at the middle of 99.9 MB | 7 | 44.7 ms [44.5, 46.7] | 238 ms [234, 250] | 2.82 ms [2.77, 2.96] | 2.84 ms [2.80, 3.04] |
| its undo | 7 | 1.47 ms [1.45, 1.52] | 230 ms [228, 244] | 61.0 ms [60.6, 61.5] | 3.11 ms [3.07, 3.18] |
| save 15.9 MB, `fsync` before `Saved` but for Emacs | 7 | 64.0 ms [42.9, 102] | 131 ms [125, 131] | 85.6 ms [73.8, 107] | 83.4 ms [76.7, 127] |
| 288 prefixes of 41 queries, each ranked from 1,933 file names | 20 | 1,544 ms [1,537, 1,554] | 617 ms [604, 622], `flex` | 136 ms [135, 137], `matchfuzzy()` | 180 ms [179, 181], `matchfuzzy()` |
| the same queries: mean reciprocal rank of the file meant | – | 0.898 | 0.748, `flex` | 0.898 | 0.898 |
| memory at rest, empty, PSS | 5 | 41.8 MB [41.7, 41.9] | 49.0 MB [48.0, 49.1] | 10.1 MB [9.8, 10.2] | 7.8 MB [7.7, 8.0] |
| memory with 99.9 MB open, RSS of all its processes | 7 | 220 MB [220, 220] | 151 MB [151, 151] | 137 MB [137, 138] | 133 MB [133, 133] |
| processor at rest, % of one core | 5 | 0.0 % [0.0, 0.0], in a Wayland window | 0.0 % [0.0, 0.0] | 0.0 % [0.0, 0.0] | 0.0 % [0.0, 0.0] |

With n = 5 the interval is that of the fastest and the slowest run, at 93.75 %; with n = 3, only the median is given.

The inside times of Emacs, Neovim and Vim don't count the terminal's drawing, which another program does; Cemacs's count its
own. The others show these files as plain text, where Cemacs colours them. Neovim and Vim call `fsync` before they say a file
is written, Emacs 31 doesn't; Cemacs does since this version.

What they say:

- **Vim and Neovim start several times faster than Cemacs.** They are programs of C compiled to machine code, which start
  in a few milliseconds and draw characters into a terminal. Cemacs is a Cesia program: Cesia reads and prepares about
  8,000 lines of code at each start, Cemacs's and the packages of Cesia it uses, about 24 ms with the next version of Cesia
  and 38 ms with 1.1.0, then SDL3 opens a window, and
  SDL3_ttf loads three fonts and draws the first frame in pixels. In a real window on GNOME, SDL's start of its title bar
  through GTK and of OpenGL brings it to 236 ms. Emacs, which loads its own Lisp at the start, takes 89 ms in a terminal.
- **Cemacs opens a file faster than Emacs at every size measured, 99.9 MB in 0.68 of its time, but Vim and Neovim open a
  large file faster still**, 0.9 of Cemacs's time at 99.9 MB, half at 15.9 MB. Cemacs's rope no longer copies the file: its
  leaves are views of the one text read. What is left is the start, the check of UTF-8 in OCaml, and the count of line ends
  for each view, where Vim and Neovim fill blocks of lines in C.
- **Cemacs finds a word in a large file as fast as Emacs**, 48.8 against 48.4 ms for 99.9 MB, within the intervals, and four
  to six times faster than Neovim and Vim: one call of Cesia that searches the file's text in place, eight bytes at a time,
  with the case folded in the same pass. Emacs's Boyer–Moore skips bytes; Neovim and Vim run a regular expression over their
  lines. A far place is shown at once, its colours exact a few seconds later.
- **Undo is fastest in Cemacs**: 1.5 ms for the paste of 1 MB at either size, where Vim takes 3 ms, Neovim 13 to 61 and Emacs
  46 to 230, as Cemacs keeps whole states, values that never change, and takes one back in O(1). **A paste** costs Cemacs
  about 45 ms, mostly the colours of the pasted lines, against 2.8 ms for Vim and Neovim, which append lines in C; Emacs takes
  238 ms at 99.9 MB, as it moves its gap.
- **A save of 15.9 MB that waits for the disk**, `fsync`, takes Cemacs less than Vim and Neovim, which wait too, when the text
  is the one read: its views still cover the file's text, written as it is. Emacs, which doesn't wait, takes more, 131 ms, and
  makes a backup of the file at its first save, `FILE~`.
- **Enter that indents a line of code** costs Cemacs under a millisecond at every size of file, where Emacs's python-mode,
  two to four times faster in a small file, takes 0.2 s in a file of 100 MB, and Neovim's indent of Python 3.8 to 19 ms:
  Cemacs reads a line from the nearest line at the margin above it, which [Speed](performance.md#enter-and-tab-in-a-file-of-cesia)
  tells. The two others have no mode for Cesia, so they were measured on Python.
- **Completion** of a start of two or three letters takes Cemacs 0.7 to 1.4 ms at any size of file; Neovim's `Ctrl-N` is as
  fast or faster in a small file, and wins on a start of one letter, but reads the whole buffer, 0.4 to 1 s in 100 MB; Emacs's
  `dabbrev` 3 to 15 ms, and 13 to 23 s, while its `M-/`, which looks for one word only, takes 0.04 to 0.2 ms.
- **A key and a scrolled line** take Cemacs 2.6 ms inside, with OpenGL, against 1.1 to 1.5 ms for Emacs and 0.02 to 0.06 ms for
  Neovim and Vim, which write a few cells of a terminal in C and let the terminal draw them. All of them land within one
  frame of the screen, 16.7 ms at 60 Hz. In a file of 99.9 MB, at its middle line, a key costs Cemacs 1.6 ms without drawing,
  Emacs 1.05.
- **At rest, Cemacs uses memory of the order of Emacs empty, and four to five times that of Vim and Neovim**, which hold a
  terminal's characters where Cemacs holds a window, its fonts and the Cesia runtime. With a file of 99.9 MB open, Cemacs
  holds 220 MB, 1.5 times Emacs and 1.6 times Vim and Neovim, which hold the file about once: Cemacs holds it once too now,
  its rope's leaves viewing the text read, beside the 46 MB of the empty editor and memory that OCaml's collector has not
  given back, as [Speed](performance.md#at-rest) tells. It held 475 MB with a Cesia file before, whose check held the text
  once more and kept a core half busy.
- **At rest, none of them uses the processor**: each sleeps until an event wakes it, Cemacs in SDL, the others on their
  terminal. Cemacs also wakes four times a second, for the fibers of Cesia.
- Typing is compared inside each program only: the honest measure of the time from a key to the screen needs a camera or a
  tool that reads the screen, such as Typometer, and none was used.

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
| Finding a file of a project | `C-x p f`: the files of `git ls-files`, ranked by fzy's score, words in any order | `C-x p f`, `project-find-file`, from `git ls-files`; by default matched as a substring and sorted alphabetically, ranked by its cost when the `flex` style is chosen | none for file names: `:find` searches `'path'` by wildcards; `'findfunc'` can plug in `matchfuzzy()`, which ranks by fzy's score | as Neovim |
| Search and replace | incremental search, `C-s` and `C-r`, with Emacs's case folding; no regular expression, no replace | incremental search, by regular expression, replace | `/`, `:s` | `/`, `:s` |
| Errors of the code | Cesia's, from `cesia check`, half a second after a key; a file over 1 MB is not checked, and its mode line says so | Flymake, built in, with a checker for each language | diagnostics of its LSP client | by plugins |
| Language servers (LSP) | no client; Cesia's errors come from `cesia check` | Eglot, built in | a client built in, `vim.lsp` | channels that speak LSP's encoding; the client is a plugin |
| Debugger | built in, for Cesia, with breakpoints, steps, evals, fix and continue | GUD, built in, for gdb and other debuggers | none built in: plugins | Termdebug, built in, for gdb; channels that speak DAP's encoding |
| Indentation | for Cesia, by `cesia fmt`'s rule: Enter, Tab, and `end`, `else`, `then` and closing brackets at the start of a line | for each language, by its mode: `indent-for-tab-command`, and `electric-indent-mode` at a line end and the characters each mode adds | for each kind of file, by its `'indentexpr'`, at the keys of its `'indentkeys'`, such as `0=end` | as Neovim |
| Completion | in Cesia files, Tab at the end of a word: the words around the cursor, of the other buffers and the names of Cesia, in a list under the cursor | `completion-at-point` and `dabbrev-expand` (`M-/`), built in; `tab-always-indent` set to `complete` | `Ctrl-N` and `Ctrl-P` in insert mode: the words of the buffers; LSP completion | `Ctrl-N` and `Ctrl-P` |
| Undo | linear, with redo, 1,000 states | an undo is recorded as an edit, so an undo can be undone; `undo-redo` | a tree of every state | a tree of every state |
| Encodings | UTF-8 only | many | many | many |
| Large files | opens up to 1 GiB | asks above 10 MB, then opens | opens | opens |
| Saves of its own | none: no autosave, backup or swap file | autosave files and backups | swap files | swap files, and backups if asked |

The features of Emacs, Neovim and Vim were checked on the installed programs: Eglot, Flymake, GUD and `which-key` load in
Emacs 31.1 with no package added, and `large-file-warning-threshold` is 10,000,000; `vim.lsp` is in Neovim 0.12.6; Vim 9.2
has the `lsp` and `dap` modes of its channels and the Termdebug package in its runtime. For the files of a project, Emacs
31.1's `completion-category-defaults` gives `project-file` the `substring` style, and `completions-sort` is `alphabetical`;
the `'wildoptions'` of Vim 9.2 and Neovim 0.12.6 say that fuzzy completion "is not supported for file and directory names".
[A case: finding a file from a few letters](finding.md) measures the ranking of the four on the same files.

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

- **Search by regular expression and replace, completion from a language server, a command by name, other languages and
  encodings, a terminal inside.** Cemacs has none yet, beside its incremental search and its completion of words: it is a young editor for one language, and grows when its
  use asks.
- **Speed at the start and on large files.** Native code that reads and scans the bytes of a file at the speed of memory.
- **Safety of the text.** Emacs, Vim and Neovim keep a copy of what you type on disk, so a crash loses little; Cemacs keeps
  it in memory only.
- **Maturity.** Their code has run for decades, on many systems; Cemacs is tried on Linux, by its author and its tests.
