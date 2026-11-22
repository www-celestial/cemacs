# Changelog

## Unreleased

No release yet: this is what `main` holds. Cemacs needs Cesia 1.3, and its first release takes its number here.

Cemacs is a text editor for Cesia, written in Cesia, with the keys of Emacs and the colours of Cesia's code. A band shows
what a key can lead to, so no key has to be learnt before the start.

### Editing

- The keys of Emacs, and groups of keys under `C-c`, as in Doom Emacs: `C-c f` files, `C-c s` search, `C-c c` code, `C-c t`
  tests, `C-c g` Git, `C-c e` cells; a band of hints shows what can follow a key, and `?` after a first key lists its pairs.
- Buffers and panes, a buffer list, and a manager of folders on `C-x d`, with the trash.
- The manager of folders takes the keys of Emacs's Dired: letters are commands, `m` marks and `d` flags, `C` copies a tree
  whole and `R` moves it across disks too, `D` and `x` delete, to the trash or for good as `DeleteToTrash` says, `S`, `Y`
  and `H` link, `M` and `T` give a mode and a time, `!` and `&` run the shell on the files, `Z` and `c` compress, `=` shows a
  diff, `A` and `Q` search and replace, `C-x C-q` edits the names as a text, a copy goes first to the folder of the other
  pane; `/` filters as letters did, and each program runs with the permission to run it alone.
- Incremental search, `C-s` and `C-r` as in Emacs; a list's filter matches its words apart, in any order, ranked by fzy's
  score as Vim and Neovim do; `C-x p f` lists the files of the project's Git repository and `C-x p g` searches its lines.
- In a file of Cesia, Enter starts the new line where `cesia fmt` puts it, Tab puts a line at its place or completes the
  word from the words around, the other buffers and the names of Cesia; a file is saved as `cesia fmt` writes it, in one
  step of undo; `C-c i` writes the forms of Cesia, a function, a struct, a loop, a match, a test and a cell. A do block
  after the `)` of a call opens a block for Enter and Tab.
- The prompt keeps the answers to each question, which `M-p` and `M-n` bring back; Tab completes a file's name in Find
  file and Save as.
- The screen keeps 3 rows between the cursor and its top or its bottom, as `scroll-margin` in Emacs, `ScrollMargin` in the
  config; the wheel takes the cursor along, so that it stays on the screen, and a click leaves the screen where it is.
- The screen moves a row at a time through the graphs of the cells, by the keys and by the wheel, a graph cut at the top
  showing its lower part, instead of showing or hiding a whole graph at once.

### Cesia in the editor

- Errors in the lines: `cesia check` runs in the background after a pause or a save, its marks move with their lines, and
  `M-g n` and `M-g p` go from one to the next. A buffer over 1 MB is not checked, and its mode line says so.
- Names, from `cesia lsp`: `M-.` goes to a definition and `M-,` back, `M-?` lists every place that reads a name, `C-c c m`
  renames it across the project, `C-c c i` shows its documentation.
- Running: `C-c c r` runs the file, as the task of `cesia.toml` that names it with its permissions; `C-c c o` opens the
  output, where Enter goes to the place an error names. `C-c d` sets breakpoints, steps and evaluates under the debugger.
- Tests: `C-c t t` runs the test at the cursor or the folder's, `C-c t a` all of them, `C-c t r` the last ones again.
- Git, a small Magit: `C-x g` lists the state of the repository, where `s` stages, `u` unstages, `c` commits, `d` shows a
  diff and `l` the log.
- A shell: `C-c o t` opens a buffer where the commands typed run in the person's shell.

### Cells

- A file of Cesia cut by `(* %% Title *)` runs as a notebook, `C-c e`, in a session of std/cells: results under their
  cells, the cells that read what one defines run again, `*variables*`, `*repl*`, and the page of a file.
- Each result of a cell starts with its label, `Out[3]:` as in Jupyter, numbered by the runs of the session.
- `cells.Show` of Cesia 1.3 gives a cell more than one result: each graph, table or text it shows under the cell at its
  place among what the cell printed, each graph drawn and redrawn on its own, in `*repl*` and the page too.
- A graph of std/plot under its cell, drawn from its scene; sliders under their lines in a cell of sliders, moved by the
  mouse or by `C-c e f` and the arrows, their number written in the buffer; animations played by Space on their bar; 3D
  graphs turned by a drag or by the arrows, each view asked of the session.

### Changing Cemacs

- `user/`, the person's folder, which git ignores: the config gives the theme, the size of the window and a function run
  after the files opened; keys, commands and apps of one's own, in Cesia, reloaded while Cemacs runs.

### Speed

Measured on the same machine as the rest, in the book's chapter on performance:

- A file opens in pieces, its rope cut once with no copy: 15.8 MB in 206 ms instead of 4,280, 99.9 MB in 266 ms (Emacs
  393).
- `C-s` finds a word at the end of 99.9 MB in 48.8 ms instead of 583 (Emacs 48.4, Neovim 181, Vim 300).
- The colour states kept in chunks of 1,024 lines: a key at line 1,416,745 of 99.9 MB in 1.4 ms instead of 43.7, beside
  Emacs's 1.05; `M->` at the end of 99.9 MB shows in 40 ms instead of 4.6 s.
- A still window sleeps until the next event: 0.0 % of a core at rest instead of 1.4 %, a key read 0.7 ms after it was
  sent instead of 3.1.
- The start, to the first frame: 51.3 ms with Cesia 1.2 against 57.4 with Cesia 1.1.0; Emacs 89.1, Neovim 13.8, Vim 9.3.

### Fixes

- The config of a Git repository runs no program of its own on `=`, `C-x p f`, `C-x g`, `C-c g d`, the log, a commit shown,
  the blame or `C-x p g`: no fsmonitor, external diff, textconv, filter, hook, signature program or fetch helper of a
  `.git/` that came with a folder; `=` runs out of any repository.
- A save keeps the mode of the file, a private one private and a script one to run, through a new file that is the
  person's alone until it gets that mode; a symbolic link stays a link and the file it points to is saved, as in Emacs;
  the copy of a file of Cesia that `cesia fmt` formats is the person's alone.
- A zero byte in the output of a program or of a cell, or in any text drawn, is shown as `␀`, and copied so, instead of
  ending the editor and losing every buffer not saved.
- `C-c e h` asks before it replaces a page that is there, and writes the page as a save does, through a new file and a
  rename, so a symbolic link named as the page is replaced, never written through.
- `M-f` and `M-b` read each line they cross once, so a word of 32,000 letters is crossed in 25 ms instead of 36 s, and one
  of a million in under a second instead of never; Tab, typing and backspace at the start of a line of a megabyte take 7
  to 16 ms instead of 220, as the screen and the completion take a slice of the line instead of all its characters.
- A name with a line end or another control character is written as `ls -b` writes it, `a\nb`, in the rows of a folder,
  in the names to edit and on the prompt line, so that a row is always the file it shows: the row of the cursor could
  take the file under it; and `C-x C-q` then `C-c C-c` with no edit keeps each name byte for byte, where a name that ended
  with a line end lost it.
- `!` and `&` run their command in `/bin/sh`, whose quoting the names get, instead of `$SHELL`: in fish, a name that ended
  with a backslash closed no quote, and the next name could run as a command.
- The trash, its `files/` and its `info/` are made the person's alone, 700, and each `.trashinfo` 600, as GIO makes
  them, instead of 755 and 644.
- A press on a slider runs cells only in a session that `C-c e e` or `C-c e a` started: in a file just opened, it writes
  its number and runs nothing, where it started a session and ran every cell.
- A deletion for good, `D` and `x` with `DeleteToTrash` false, and the end of a move across disks are Cesia's
  `sys.RemoveTree`, which walks by the folders it holds open: someone who can write the folder above, as in `/tmp` or a
  shared folder, and swaps the folder for a link while it runs no longer leads it into the folder the link points to,
  where it deleted what that one held; the first file that can't be deleted stops it.
- A copy, a move across disks and the links of `S`, `Y` and `H` write first at a name that no one can know before it is
  made, `.#cemacs-` and 32 digits of the randomness of the kernel, instead of `.#cemacs-NAME`, where someone who could
  write the folder could put a link in time for the copy to write through it; a failure names the file, never that name.
- A path that goes while the folders ask whether it is a folder, as one that someone else removes from a shared folder
  during a copy, a move or a deletion, is taken for no folder, instead of a failure that ended the editor.
- A letter typed at the start of a line of a megabyte of a file of Cesia takes 20 ms instead of 1.3 s: to know whether
  its first word moves the line, as `end` typed there does, only the start of the line is split into characters.
- After a pause in a file of Cesia, the tick that asks whether a signature can be shown slices the line of the cursor,
  9 ms instead of 238 on a line of a megabyte, and the rows of a list, the lines of the output and the value of an eval
  are cut to the screen with a slice, 10 ms for the frame of a row of a megabyte instead of 217, where all their characters
  were split.
- `C-e`, typing and backspace at the far end of a line of a megabyte take 0.09 s instead of 0.48 when the line is one
  word, and 0.24 s when it is code, where a line of 100 KB of code took 21 s, the colours shown the same: the lexer walks
  the bytes of the line instead of a text for each character, slices a run of plain words once instead of copying the
  tokens at each word, and makes only the words of the screen, crossing the line before them by its comments and texts;
  the state at the end of a line of code no longer looks again from each text for a backslash it doesn't hold, 63 ms for
  a megabyte instead of 6.9 s.
- `C` and a move across disks copy a folder with Cesia's `sys.CopyTree`, which walks both trees by the folders it holds
  open: someone who can write the folder above, who swaps a folder of the tree copied for a link, or the copy for one,
  while it runs, no longer leads it to copy their files or to write over another's, where a copy of 3,000 files took
  2,837 files of the other folder, or wrote over 2,856; it copies 2,000 files in 120 ms instead of 240. The first entry
  that fails stops the copy, as Emacs's `copy-directory` does, and the prompt line says what was copied before stays,
  where the copy went on after a failure; a special file in the tree stops it, where it was left out.
- The copy of a file through a name of its own makes that name only new, with `sys.Copy(..., new = true)`, as a save
  does: a link or a file put there first is never written through, stays as it was, and another name is drawn.
- A save gives the new file the mode and the group of the old one as soon as it is open, before the words are in, with
  nothing done to it by its name before the rename, where it set the mode by the name after the words, and the group of a
  file was lost: a file of a team, `rw-rw----`, stays the team's. A group the person can't give is left, and the save works
  as before. The new file is made only new, with `sys.Write(..., new = true)`, its owner's alone until it has its group
  and its mode: a link or a file put at its name first is never written through, stays as it was, and another name is
  drawn, so the name, `.#cemacs-` and 32 digits as a copy's, needs no randomness of the kernel, and a save under a grant
  of its folder alone, as the blocks of the book run, reads nothing out of it. A file of a name of 250 bytes is saved
  too, where `PATH.cemacs-` and a time was too long for the system.
