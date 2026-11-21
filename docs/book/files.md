# Files and buffers

A buffer is a text that Cemacs holds in memory, most often the text of a file. You edit the buffer; saving writes it to the
file, and until then the file on disk doesn't change. Each buffer has its own cursor, mark, undo history and checked errors.
This chapter tells how files are opened and saved, which files open, how line ends are kept, how to go from one buffer to
another, and the folder manager. The commands are in [core/commands], the folder manager in [src/folders].

## Opening a file

| Keys | Command | What it does |
|---|---|---|
| `C-x C-f`, `C-c f f` | [commands.FindFile] | asks `Find file: ` on the prompt line, then opens the file named |

The answer starts with the folder of the current file, so that a file beside it takes only its name. It is a path as the
system reads it: from the folder where Cemacs started for a relative one; `~` is only a name there, not your home. The
prompt line takes letters, Backspace, `C-y`, which pastes the first line of the clipboard, Enter and `C-g`, and you edit only
at the end of the answer. Tab completes the name, from the entries of its folder, as Emacs does: the names that start with
the last part of the answer complete it as far as they agree, a folder with its `/`; when several are left, they show after
the answer, as `{color/ | commands/ | complete/}`, ten at most. With none that starts so, the names that hold its letters in
order match, as the filter of a list does: `nms` and Tab give `names/`. `M-p` and `M-n` go back and on through the files
answered before, as [The prompt line](windows.md#the-prompt-line) tells.

A file opens in a new buffer, which becomes the current one, the buffer you edit. A file that is open already isn't read
again: Cemacs goes to its buffer. Two paths name the same file when they are the same once `.` and `..` and doubled slashes
are taken out, as [files.Normal] does; a symbolic link is not followed, so a file opened through a link and through its target
gets two buffers.

```cesia
use core/files
files.Normal("./src/../src//main.ce") --> "src/main.ce"
```

Emacs calls opening a file visiting it. `bin/cemacs a.ce b.ce` opens each file it is given, in order, and stays in the
first one.

### Which files open

A file that doesn't exist opens as an empty buffer, and is made at the first save. Else [files.ReadFile] reads it, unless it
is one of these, which stay closed with a message on the prompt line and the file untouched:

| The file | The message |
|---|---|
| a folder | `PATH is a folder.` |
| not a regular file: a device, a FIFO (a named pipe), a socket | `PATH is not a regular file: it may be a device, a pipe or a socket.` |
| larger than 1 GiB, 1,073,741,824 bytes | `PATH is too large to open: SIZE bytes, and the limit is 1073741824.` |
| not valid UTF-8, or holding a zero byte | `PATH is not valid UTF-8 text, or holds a zero byte.` |
| unreadable, such as without the permission of the system | the reason that Cesia gives |

A device or a FIFO says it has the size 0, and reading one may never end or fill the memory, so Cemacs asks the system what
a file is before it reads it. The limit of size keeps a file too large for memory from stopping the editor, with every
buffer's unsaved text: a file takes about twice its size in memory for a moment as it is opened, 193 MB at the peak for
99.9 MB, and [Speed](performance.md#opening-a-file) has what a large file costs.

### Encodings

An encoding is the way the characters of a text become bytes in a file. Cemacs reads and writes UTF-8 only, the encoding of
Cesia's code and of most text today, where a character takes one to four bytes. A file is valid UTF-8 when each of its byte
sequences is one that RFC 3629 allows: [files.IsText] refuses an overlong form, a character written in more bytes than it
needs; a surrogate, a code from U+D800 to U+DFFF that UTF-16 uses in pairs and that is no character; and a code above
U+10FFFF, the last one of Unicode. A file in Latin-1 breaks these rules as soon as it holds a character outside ASCII, and a
file in UTF-16 holds zero bytes, so such a file stays closed instead of showing wrong characters and being saved broken.

[files.IsText] makes two checks of the whole text, each one call of Cesia's standard library, written in OCaml, that reads
the text where it is, without a copy: [text.Count] counts its zero bytes, which must be none, and [text.IsUtf8] tells whether
it is valid UTF-8 as RFC 3629 defines it. The zero byte needs its own check because it is valid UTF-8, the character U+0000,
which no text file holds. Both read eight bytes at a time: a word of 64 bits holds eight bytes, and a few operations on the
whole word answer for the eight at once, a method called SWAR, SIMD within a register (SIMD, single instruction, multiple
data, is a processor's way of doing one operation on several values together; SWAR gets it from the plain operations on
integers). [text.IsUtf8] decodes a character only where a byte isn't ASCII. On 99.9 MB of Cesia's code, measured as
[Speed](performance.md#opening-a-file) tells: 34 ms to count the zero bytes, 24 ms to check the UTF-8, 60 ms for
[files.IsText].

```cesia
use std/text
files.IsText("café") --> true
files.IsText(text.FromBytes([0x63, 0x61, 0x66, 0xE9])) --> false
files.IsText(text.FromBytes([0x61, 0, 0x62])) --> false
```

The second text is `café` in Latin-1, where `é` is the one byte `E9`. A file that starts with the byte order mark of UTF-8,
the bytes `EF BB BF` that some programs write first, is valid UTF-8: it opens, the mark stays the first character of the
buffer, and a save writes it back.

GNU Emacs, Neovim and Vim test UTF-8 too as they read a file, but where the test fails they take another encoding: the four
bytes of `café` in Latin-1 open in GNU Emacs 31.1 with the coding system `iso-latin-1-unix`, and in Neovim 0.12.6 and Vim
9.2 with the `fileencoding` `latin1`, the last of their default list `ucs-bom,utf-8,default,latin1` (each checked on this
machine). Their way opens any file, at the risk of a wrong guess: a file in another encoding of one byte a character, such as
Windows-1252, shows wrong characters as Latin-1. Cemacs keeps one encoding and refuses what isn't in it rather than guess.

### Line ends

A line end is the character, or the two, that end a line: `\n`, a line feed, on Linux and macOS, and `\r\n`, a carriage
return and a line feed, on Windows. Cemacs keeps each line's own:

- A `\r` just before a `\n` belongs to the line end: the cursor never goes between them, and columns don't count it.
- Enter inserts the line end of the line it is on: `\r\n` in a line that ends so, else `\n`. The last line, which has none,
  takes the one of the line above.
- A `\r` anywhere else is an ordinary character.
- Saving writes the text as it is: a file of `\r\n` stays one, a mix stays a mix, and no line end is added at the end of the
  file or taken away.

## Saving

| Keys | Command | What it does |
|---|---|---|
| `C-x C-s`, `C-c f s` | [commands.Save] | saves the current buffer to its file; a buffer with no file asks `Save as: ` first |

After a save the prompt line says `Saved PATH`, the star of the mode line goes away, and every Cesia buffer is checked again,
since another file may use the one just saved: see [Errors in the lines](check.md).

### Never losing the text

Saving is built so that no failure loses text, neither the text on disk nor the one in the buffer:

1. The new text goes to a new file beside the old one, named `PATH.cemacs-` and the time in microseconds, with `-1`, `-2` and
   so on up to `-20` when that name is taken, after which the save stops with `No free name next to PATH for a new file.`
   The new file is the only one Cemacs ever removes. When PATH is a symbolic link, a file that only points to another one,
   PATH here is the file it points to, its links followed one after the other, as Emacs's `file-truename` does: the link
   stays a link, and the file it leads to gets the text.
2. The new file is written with `sys.Write(..., sync = true, private = true)`, which makes it with `O_EXCL`, so that no file
   or link put at its name first takes the text, and yours alone, `rw-------`, so that no one can open it while it holds
   the text; and which gives its answer only once the system has put the file on the disk, and then its folder, with
   `fsync`: the call that asks the system to write what it holds in its caches, so that a loss of power can't take it back.
3. The new file gets the mode of the old one, its rights to read, write and run, then, once it is on the disk in full, a
   rename puts it in place of the old file. On Linux, a rename within one file system, as here, is atomic: at every instant
   the name leads to the whole old file or to the whole new one, never to a part of either.
4. If writing or renaming fails, the new file is removed, the old one stays whole, the buffer keeps its text and its star,
   and the prompt line tells the reason, naming your file, not the new one.

This protects the file from a failure of Cemacs, of the disk being full, of a permission, and of a loss of power: once the
prompt line says `Saved`, the whole new text is on the disk, under the name of your file, or, if the power went in the
instant of the rename before the system wrote the folder again, under the new file's name `PATH.cemacs-...` beside the old
file, which is then whole. Vim and Neovim do the same by default (their option `'fsync'`); GNU Emacs 31 doesn't, as its
`write-region-inhibit-fsync` is on. The cost is the time the disk takes: [Speed](performance.md#paste-undo-and-save) has it.

The saved file is a new one with the mode of the old one: a private file stays `rw-------`, a script keeps its right to run,
a read-only file stays read-only. Its setuid and setgid bits don't pass, as the new file is yours, not the old one's
owner's, and its group is the one a new file gets in that folder. A file that wasn't there gets what the system gives a new
file, `rw-rw-rw-` less the `umask`, the mask by which the system takes rights away from every new file, as Linux tells it in
`/proc/self/status`; `rw-------` where it doesn't. A hard link, a second name of the same file, no longer shares the text.
The folder must let you write in it, for the new file.

### A file changed by another program

When Cemacs reads a file, it notes its size and the time of its last change. A save first looks again: if another program,
`git` for instance, changed the file since, or made a file there since Cemacs saw none, nothing is written and the prompt line
asks `File changed on disk. Overwrite? (y or n)`. `y` writes your text over it, in the same safe way; `n` says `Not saved.`
and leaves both texts as they are. [files.SaveFile] does the check:

```cesia allow=read,write
use std/result
use std/sys
sys.Write("notes.txt", "one")
read = result.Unwrap(files.ReadFile("notes.txt"))
result.IsOk(files.SaveFile("notes.txt", "second", read.Disk)) --> true
files.SaveFile("notes.txt", "third", read.Disk) --> result.Err({Kind: "changed", Message: "notes.txt changed on disk since it was read."})
```

The second save gives the size and the time of the first reading, and the file has changed since: the save in between made
it a new file. Cemacs looks only when it saves: it doesn't reload a file that changes while it is open, as Emacs's
`auto-revert-mode` would, and it has no command to read it again.

### Saved as cesia fmt writes it

A file of Cesia, a `.ce` file, is saved as [`cesia fmt`](https://www-celestial.github.io/cesia-lang/commands.html) writes it:
each line at the indent of its blocks, no spaces at the end of a line, no two blank lines in a row. The text goes to a file
of its own in `.cesia/fmt/` of the folder of Cemacs, yours alone, `rwx------`, as the copy is, `rw-------`, since the file
may be a private one, `cesia fmt` formats it, and the formatted text is what is saved; the
buffer takes it too, as one step of undo, so that `C-/` gives back what you typed, the cursor on its line. The file in
`.cesia/fmt/` is removed at once. A text that doesn't read, as one with a bracket left open, is saved as typed, and the
prompt line says `Saved PATH as typed:` and why `cesia fmt` left it. A save of a file of 2,000 lines takes 60 ms through
`cesia fmt`, 8 ms without: [Speed](performance.md#paste-undo-and-save).

### Save as

A buffer with no file asks `Save as: ` and saves to the path given, which becomes its file only once the save worked. An
empty answer says `No file name.`; a file open in another buffer is refused with `PATH is open in another buffer.`, since one
file would then have two buffers with two texts; and a file that exists there already is asked about with
`File changed on disk. Overwrite? (y or n)`, as above. A list, such as the list of buffers, has no file: saving it says
`A list has no file.`

### What Cemacs doesn't write

Cemacs makes no backup file, as Emacs's `notes.ce~`, no autosave file, and no lock file. Text that isn't saved lives only in
memory: quitting asks first, but a crash of the editor loses it. Save often.

## Buffers

| Keys | Command | What it does |
|---|---|---|
| `C-x b`, `C-c b n` | [commands.NextBuffer] | goes to the next buffer, from the last one to the first |
| `C-x C-b`, `C-c b b` | [buffers.Open] | opens the list of buffers |
| `C-x k`, `C-c b k` | [commands.CloseBuffer] | closes the current buffer, asking first if its text isn't saved |
| `C-x C-c`, `C-c q q` | [commands.Quit] | ends Cemacs, asking first if any text isn't saved |

A buffer's name is the last part of its path, as the mode line and the title of the window show it, `untitled` for a buffer
with no file, or the name of a list. Two files of the same name in two folders show the same name: the list of buffers
gives their paths.

The list of buffers has a row for each buffer, with a star for a text not saved, its name, and its path. It is a list: a
buffer of rows that typing filters, read only, where Enter on a row goes to that buffer and closes the list. See
[Search](search.md#lists) for how a filter matches.

Closing a buffer whose text isn't saved asks `Text not saved. Close anyway? (y or n)`. Closing the last buffer leaves one
empty buffer, so that there is always one. A pane that showed the closed buffer shows the one that takes its place.

Quitting asks `Text not saved. Quit anyway? (y or n)` when some buffer isn't saved, and so does closing the window, and the
TERM or INT signal, as `Ctrl-C` in the terminal that started Cemacs sends: a question that was open gives its place to this
one.

## The folder manager

| Keys | Command | What it does |
|---|---|---|
| `C-x d`, `C-c f d` | [folders.Open] | opens the folder of the current file, or the folder Cemacs started in |

The folder manager is a list of the files and folders of a folder, as Emacs's Dired is, and it takes Dired's keys: each
letter you type is a command, `n` the next row, `m` a mark, `C` a copy, `D` a deletion, and `?` says the main ones on the
prompt line. A command acts on the rows marked with `*`, or, with none, on the row under the cursor. The list is named by
the folder's absolute path. The prompt line shows that path, ending with `/`, then what the list holds besides: the count
of the rows marked and flagged, the sort when it isn't by name, `hidden shown`, or, with none of these, `? lists the keys`.
The state of a list, its folder, its marks and the way it shows them, is a record, the view, that [folders.NewView] starts
and [folders.ViewOf] reads.

### The rows

Here are the rows of a folder, as [folders.Rows] makes them from its entries, two hours after the last change of each, with
`LICENSE` marked:

```cesia
use src/folders
use std/io
entries = [{Name: "cesia.toml", IsDir: false, Size: 262, Modified: 0, Mode: 420}, {Name: "src", IsDir: true, Size: 0, Modified: 0, Mode: 493},
  {Name: ".git", IsDir: true, Size: 0, Modified: 0, Mode: 493}, {Name: "LICENSE", IsDir: false, Size: 1069, Modified: 0, Mode: 420},
  {Name: "run", IsDir: false, IsLink: true, Size: 120, Modified: 0, Mode: 493, Target: "bin/cemacs"}]
for row in folders.Rows(entries, false, 7200, marks = {"LICENSE": "*"})
  io.Print(row.Words)
end
```

Each row starts with its mark, in a column of its own: `*` marked, `D` flagged for deletion, a space for none. Then come
its details: the mode, its size and its age; `(` hides them, and shows them again. The mode is written as `ls -l` writes
it, as [folders.ModeText] does: the kind, `d` for a folder, `l` for a symbolic link, `-` for a file, then three letters
for each of the owner, the group and the others, `r` to read, `w` to write and `x` to run, or enter a folder; `s` and `t`
stand for the bits of set-id and of the sticky folder. A link shows `lrwxrwxrwx`, as Linux gives every link, then the size
and the age of what it points to, and its name ends with `->` and its target. A mode is a number from 0 to 4095, which
Cesia writes in decimal: 420 is `644` in octal, `rw-r--r--`.

A name, and the target of a link, is written as `ls -b` writes it, by [folders.NameText]: a backslash doubled, and each
control character, a byte from 1 to 31 or 127, escaped as C writes it in a text, `\n`, `\t`, `\r`, or by its number in octal,
`\033` for ESC. Anyone who can write in a folder can make a name with a line end in it, and a row that broke there would
show the next file on the line of the cursor while a key acted on the one above: here a row is always one file, the one it
shows. The prompt line writes the control characters of what it shows in the same way, by [lists.Escaped], and so does
every list for a row that holds a line end.

```cesia
folders.PermissionText(420) --> "rw-r--r--"
folders.OctalText(493) --> "755"
folders.SizeText(3250) --> "3.3 kB"
folders.AgeText(7200, 0) --> "2 h"
```

A file shows its size, counted by 1000: `B` for bytes up to 999, then `kB`, `MB`, `GB` and `TB`, with one decimal below 10,
as [folders.SizeText] does. Its age says when it last changed: `now` under a minute, then minutes, hours, and days up to
30, then the date, as [folders.AgeText] does. The date is in UTC, the time of Greenwich, and a row shows no hour of the
day; `y` tells the hour, on the clock of this machine. The ages are those of the moment the folder was read: `g` reads it
again.

Folders come first, each with a `/` after its name, then files, each in the order of their names. `s` sorts them by date
instead, the newest first, then by size, the largest first, then by name again, as [folders.Sorted] does; folders stay
first in each. Names take the colours of the code by what they are: a folder as a name, a hidden one faint as a comment,
code as a text (`.ce`, `.ml`, `.c`, `.py`, `.sh`, `.el` and other languages), settings and data as a keyword (`.toml`,
`.json`, `.yaml`, `.csv`, `.lock` and others), pictures, fonts and archives as a field (`.png`, `.svg`, `.ttf`, `.pdf`,
`.zip`, `.tar` and others), anything else plain. The name of a row marked takes the colour of its mark. A name that starts
with a dot is hidden, as most file managers do on Linux: `.` or `C-c .` shows the hidden names, or hides them again.

### Moving and opening

| Keys | Command | What it does |
|---|---|---|
| `n`, Space, `C-n`, `down` | [folders.Next] | the next row |
| `p`, `C-p`, `up` | [folders.Previous] | the row before |
| `>`, `<` | [folders.NextFolder], [folders.PreviousFolder] | the next row of a folder, or the one before |
| `^` | [folders.Up] | the folder above, the cursor on the one just left |
| `enter`, `e`, `f`, `v` | [folders.Visit] | a folder opens in the list; a file opens in a buffer, and the list closes |
| `o` | [folders.OpenOther] | opens the row in the other pane, which a split makes when there is one pane, and goes there |
| `C-o` | [folders.ShowOther] | shows the row in the other pane, and stays in the list |
| `j` | [folders.Jump] | asks `Jump to file: `, the folder shown first, and puts the cursor on the name; Tab completes it |
| `g` | [folders.Refresh] | reads the folder again, the marks of the names still there kept |
| `q` | [folders.Quit] | closes the list, back to the buffer it was opened from |
| `C-g` | | takes away a filter kept, or with none closes the list, as in every list |

The other pane is the next one, as `C-x o` goes to it. A pane is split side by side, or, when it is too narrow, one above the
other. `o` and `C-o` on a folder show its list there: two folders side by side, which is what a copy or a move uses first,
as [Acting on files](#acting-on-files) tells. `j` takes a path too: a name in another folder shows that folder, the cursor on
it, and a name that a filter or the dot hid is shown again. `^` at the root says `This is the root.`.

### Filtering and paths

| You type | What it does |
|---|---|
| `/` | starts the filter: what you type next goes on the path of the prompt line |
| letters, after `/` | filter the names, as in any list |
| part of a folder's name, then `/` | goes into the folder under the cursor if it is one, else into the first folder shown, or says `No folder matches.` |
| `/` with nothing typed | goes to the root, `/` |
| `~`, then `/` | goes to your home folder, from `HOME`, or says `HOME is not set.` |
| `backspace` | takes back the last letter, or with none goes to the folder above, the cursor on the one just left |
| `enter` | keeps the filter, and gives the letters back to the commands |
| `C-g` | takes the filter away, and gives the letters back to the commands |
| `C-y` | goes to the path in the clipboard: a folder opens, a file shows its folder with the cursor on it |

[folders.StartFilter] is the `/` that starts it. The filter is Cemacs's own: Dired has none, and its letters are commands.
A filter kept with Enter shows on the prompt line after a `/`, and the commands then act on the rows it shows, the marked
ones among them: a row the filter hides is never copied or deleted. `backspace` at the root says `This is the root.` A
pasted path may start with `/`, with `~`, or be relative to the folder shown; one that leads nowhere says
`No file or folder at PATH.` `C-y` works without `/` too.

### Marks

| Keys | Command | What it does |
|---|---|---|
| `m`, `* m` | [folders.Mark] | marks the row under the cursor with `*`, and goes to the next |
| `u`, `* u` | [folders.Unmark] | takes its mark away, and goes to the next |
| `backspace` | [folders.UnmarkBack] | goes to the row above, and takes its mark away, as `DEL` in Dired |
| `d` | [folders.Flag] | flags the row for deletion with `D`, and goes to the next |
| `U`, `* !` | [folders.UnmarkAll] | takes every mark away |
| `t`, `* t` | [folders.ToggleMarks] | marks the rows with no mark, and unmarks those marked with `*`; a `D` stays |
| `* /` | [folders.MarkFolders] | marks every folder, a link to one not |
| `* @` | [folders.MarkLinks] | marks every symbolic link |
| `* *` | [folders.MarkPrograms] | marks every file that someone may run, by the `x` of its mode |
| `* .` | [folders.MarkExtension] | asks `Mark extension: `, the one of the row under the cursor first, and marks every file that ends with it |
| `* s` | [folders.MarkAll] | marks every row |
| `* c` | [folders.ChangeMarks] | asks for a mark and the one that takes its place: `D` then `*` makes the rows flagged marked |
| `% m`, `* %` | [folders.MarkMatching] | asks `Mark (regexp): ` and marks every row whose name the pattern finds |
| `% d` | [folders.FlagMatching] | asks `Flag for deletion (regexp): ` and flags every row whose name the pattern finds |
| `% g` | [folders.MarkHolding] | asks `Mark files containing (regexp): ` and marks every file whose text the pattern finds |
| `~` | [folders.FlagBackups] | flags every backup, a name that ends with `~`, as Emacs makes them |
| `#` | [folders.FlagAutoSaves] | flags every auto-save file, a name between two `#`, as Emacs makes them |
| `M-}`, `M-{` | [folders.NextMarked], [folders.PreviousMarked] | the next row with a mark, or the one before, round the end of the list |

The marks stay through a sort, a filter and `g`, as long as their names are there; they go with the folder left. `*` and
`%` wait for a second key, as the prompt line says with `* -`; `C-g` takes them back, and a second key with no command says
so. A pattern is one of [std/regex](https://www-celestial.github.io/cesia-lang/texts.html#regular-expressions), which is linear in time
whatever the pattern: no pattern can hang the editor. A pattern that is wrong is said on the prompt line, as
`Bad pattern: a class isn't closed.`, and nothing is marked: [folders.PatternError] checks it first, since std/regex stops
the program that gives it a wrong one. `% g` reads the files of at most 1 MB, and leaves out those that hold a zero byte,
which are no text.

### Acting on files

| Keys | Command | What it does |
|---|---|---|
| `C` | [folders.Copy] | asks `Copy NAME to: ` and copies, a folder with all it holds |
| `R`, `C-c r` | [folders.Rename] | asks `Rename NAME to: ` and renames, or moves into a folder, across disks too |
| `S` | [folders.Symlink] | asks `Symlink NAME from: ` and makes a symbolic link to the file there, with its path from the root |
| `Y` | [folders.RelativeSymlink] | the same with a relative path, as `../lib/a.so` |
| `H` | [folders.HardLink] | asks `Hardlink NAME to: ` and makes another name of the file, on the same disk |
| `M` | [folders.ChangeMode] | asks `Change mode of NAME to: `, the mode of one file first, and gives the mode |
| `T` | [folders.Touch] | asks `Change time of NAME to (none for now): ` and gives the time of its last change, as `touch` does |
| `+` | [folders.MakeFolder] | asks `Create folder: `, this folder first, and makes it, with the folders above it |
| `C-c n` | | asks `New file, or folder/: `: a name that ends with `/` makes a folder, any other an empty file |
| `w` | [folders.CopyNames] | copies the names to the clipboard, a space between |
| `W` | [folders.CopyPaths] | copies the paths from the root to the clipboard, a space between |
| `y` | [folders.WhatIs] | says what the row is: its kind, its size, its mode in letters and in octal, the time of its last change, and for a link its target |

A command acts on the rows marked with `*` that the list shows, or, with none, on the row under the cursor; its prompt names
them, the name of one, or `* [3 files]` for more, as Dired does. The answer of `C`, `R`, `S`, `Y` and `H` is a path, from
the folder shown when it doesn't start with `/`, and Tab completes it as in `Find file`. It starts with the folder of the
other pane, when that pane shows the list of a folder, as Dired's `dired-dwim-target` does, or else with this folder, and,
for one file, its name after it: Enter alone copies or moves the file to the other pane under its own name. One file goes
into the answer when it is a folder or ends with `/`, else takes it as its new name; more files go into it, a folder. An
answer that ends with `/` and names no folder yet makes it. [folders.Destinations] tells where each one goes.

```cesia
use std/result
result.Unwrap(folders.Destinations([{Name: "a.ce", IsDir: false}], "/p", "/q/"))[1].To --> "/q/a.ce"
```

A file that is there already is replaced only after a yes: `b.ce exists. Replace it? (y or n)`, or, for more,
`3 exist (a.ce, b.ce, c.ce). Replace them? (y or n)`; n leaves those, and the others go on. A folder copied onto a folder
that is there gives it what it holds, the files of the same name replaced. A folder is never copied or moved into itself:
`Can't copy src into itself.`, and nothing is made. After each command, the folder is read again, and so is the list of the
other pane; the prompt line says what was done, as `Copied 3 files.`.

A copy, [folders.CopyTree], reads the whole tree first, then writes it, so that a copy into a link to itself can't feed
itself. Each file is copied as `cp -p` does, with its mode and its times; a folder gets its mode and its time once what it
holds is in, the deepest first; and a symbolic link is made again with the same target, never followed, a link to nothing
too. A file or a link is written at a name of its own beside its place, then renamed over what was there, as
[folders.Placed] does: what was there stays whole until the new one is, nothing is ever written through a link at the
target, and a file copied onto itself by another path stays as it was. Where the copy has a folder and the target a file or
a link, that entry fails and nothing goes under it; a special file, as a FIFO or a device, is named and left, since reading
one can wait for ever. A move, [folders.MoveTree], is a rename; across disks, where a rename can't go, it copies, then deletes what it copied,
only once the copy is whole. The buffers of the files moved, and of those inside the folders moved, take their new path, so
that a save goes where the file is now.

The mode of `M` is in octal, as `644` or `0755`, or as `chmod` writes it, [folders.ParseMode]: clauses apart by commas, each
who, of `u` the owner, `g` the group, `o` the others and `a` all of them, none for `a`, then `+` to add, `-` to take away or
`=` to set, then what, of `r`, `w`, `x`, `X`, which is `x` for a folder or for a file that someone may run already, `s` and
`t`. Each file gets the mode computed from its own:

```cesia
folders.ParseMode("u+x,go-w", 438, false) --> result.Ok(484)
folders.ParseMode("a+X", 420, true) --> result.Ok(493)
result.IsErr(folders.ParseMode("u+q", 420, false)) --> true
```

The answer of `T` is none, for now, a day, `2026-11-21`, at midnight, or a day and an hour, `2026-11-21 14:30`, or with
the seconds, on the clock of this machine, as [folders.TimeOf] reads it. `C-c n` is Cemacs's own; a name that exists already
is refused with `NAME already exists.`, and an empty one says `No name.`.

An error on one file names it, and the others go on: `Copied 2 of 3; b.ce: permission denied`, and how many more failed.

### Deleting

| Keys | Command | What it does |
|---|---|---|
| `D`, `C-c k` | [folders.Delete] | deletes the rows marked, or the row under the cursor, after a question |
| `x` | [folders.DeleteFlagged] | deletes the rows flagged with `D`, after a question |

Every deletion asks first. The setting [emacs.DeleteToTrash], true unless you change it, as Doom Emacs's
`delete-by-moving-to-trash`, says where the files go:

- True: to the trash, a folder whole, after `Move NAME to the trash? (y or n)`; the prompt line then says
  `Moved to the trash NAME.`. A file can come back from there, as [The trash](#the-trash) tells.
- False: for good, after `Delete NAME for good? (yes or no)`, which takes the word `yes`, typed, and Enter; each folder that
  holds something then asks once more, by its name: `Delete folder NAME and everything in it? (yes or no)`. A no leaves that
  folder, and the others go. The prompt line then says `Deleted NAME.`. A symbolic link is deleted, never what it points to,
  inside a folder too: [folders.RemoveTree] never follows one.

[Changing Cemacs](customising.md#settings) tells how to set it in your `Changed`: `c.DeleteToTrash = () -> false`. After a
deletion, the cursor goes to the row that took the place of the first one gone.

### The trash

Cemacs follows the Trash specification of freedesktop.org, version 1.0, for the trash in your home, the folder from which the
file manager of your desktop can restore a file:

- The trash is `$XDG_DATA_HOME/Trash`, or `~/.local/share/Trash` when `XDG_DATA_HOME` isn't set. Without `HOME` either, it
  says `There is no trash: HOME is not set.`
- The file or folder goes into `files/`, under its own name, or `NAME.2`, `NAME.3` and so on when that one is taken.
- Its info goes into `info/NAME.trashinfo` first, as the specification asks: its path from the root, each part
  percent-encoded, as URLs write a space `%20`, and the date it was trashed. If the move then fails, the info is removed.

```cesia
use std/date
folders.TrashInfo("/home/me/my notes.ce", date.FromUnix(0)) --> "[Trash Info]\nPath=/home/me/my%20notes.ce\nDeletionDate=1970-01-01T00:00:00\n"
```

The info is dated on the clock of this machine, in its time zone, as the specification asks: [folders.TrashInfo] writes the
date it is given as `YYYY-MM-DDThh:mm:ss`, and the trash gives it [date.Local] of the moment.

Cemacs differs from the specification in two points. It finds a free name by looking at the names taken, where the
specification asks for an exclusive creation, a create that fails when something is at the name, `O_EXCL` on Unix, so two
programs trashing the same name at the same instant could clash: Cesia has no such create yet. And for a file on another
disk than your home, where a rename can't reach the trash, it doesn't use the trash folder that the specification puts at the
top of that disk: the move fails, and the prompt line says `can't move NAME to the trash: REASON`, with the file left where
it was.

### Editing the names

| Keys | Command | What it does |
|---|---|---|
| `C-x C-q` | [folders.EditNames] | makes the names the list shows a text to edit, one a line, in place of the list |
| `C-c C-c`, `C-x C-s` | [folders.FinishNames] | renames each file whose line changed, and brings the list back |
| `C-c C-k`, `C-g` | [folders.AbortNames] | leaves the names as they are, and brings the list back |

This is Emacs's Wdired. Every key of the editor edits the text: `C-s` searches it, as [Search](search.md) tells, `C-k` cuts a
line and `C-/` undoes. The three keys above are the buffer's own, which come over the global ones while it is the current
buffer. Before anything is renamed, [folders.NamesPlan] checks the lines: as many as the names, none empty, none
with a `/`, since a name changes here and not its folder, none twice, and none a name that is there already, unless another
line renames that one away. Each name is written as its row writes it, by [folders.NameText]: a line left as it was keeps
its name byte for byte, the line of a name with a control character can't be edited, `R` renames it, and an edited line is
read by [folders.NameOf], `\\` standing for one backslash. One that fails says why on the prompt line, and the text stays to
be fixed:

```cesia
folders.NamesPlan(["a", "b"], ["b", "a"], n -> true) --> result.Ok([{From: "a", To: "b"}, {From: "b", To: "a"}])
result.IsErr(folders.NamesPlan(["a", "b"], ["c", "c"], n -> false)) --> true
```

Each file is renamed first to a name of its own, `.#wdired-` and a number, then to its new name, so that two names can swap,
as [folders.Renamed] does; a rename that fails at the first step puts back those done, and nothing is renamed. One that fails
at the second puts its file back under its old name, or, when another file took that name since, leaves it under the name
of its own, which the prompt line says: no file is ever replaced. The marks go with their files to the new names, and so do
the buffers of the files renamed.

### Running programs

| Keys | Command | What it does |
|---|---|---|
| `!` | [folders.ShellCommand] | asks `! on NAME: ` and runs a command of the shell on the files, in this folder, then shows what it wrote |
| `&` | [folders.AsyncShellCommand] | the same, without waiting: what it wrote comes in the buffer `*Async Shell Command*` when it ends |
| `Z` | [folders.Compress] | asks y or n, then compresses or uncompresses each file |
| `c` | [folders.CompressTo] | asks `Compress NAME to: ` and puts the files in an archive, by the end of its name |
| `=` | [folders.Diff] | asks `Diff NAME with: ` and lists how the file under the cursor differs from that one; Enter on a line opens it there |
| `A` | [folders.SearchMarked] | asks `Search marked files (regexp): ` and lists each line of the files, those inside the folders too, that the pattern finds; Enter goes there |
| `Q` | [folders.ReplaceMarked] | asks for a pattern and what replaces it, then replaces it in the buffers of the files, left changed and not saved |

The command of `!` and `&` follows Dired's rules, as [folders.Expanded] makes the line for the shell: a `*` alone, between
spaces, stands for all the files, and the command runs once; else a `?` alone stands for each file, and the command runs
once for each; else each file comes after the command, once for each. A `*` inside a word, as `*.ce`, is the shell's own.
Each name is quoted by [folders.Quoted], between single quotes, each quote inside it closed, escaped and opened again, so
that a name with a space, a quote, a `$` or a backquote stays one word and never runs; a name that starts with `-` comes
after `./`, so that no program takes it for an option.

```cesia
folders.Expanded("tar -cf x.tar *", ["a", "b c"]) --> "tar -cf x.tar 'a' 'b c'"
folders.Expanded("wc -l", ["a", "it's"]) --> "wc -l 'a'; wc -l 'it'\\''s'"
folders.Quoted("-rf") --> "'./-rf'"
```

`!` waits for its command at most 60 seconds, [folders.CommandLimit], and ends it after; `&` has no limit, and the editor
goes on meanwhile. What a command wrote shows on the prompt line when it is one line, or else in the buffer
`*Shell Command Output*`, in the other pane, the list staying where you are. The shell is the one of `$SHELL`, or `/bin/sh`.

`Z` does what Dired's table of suffixes says, [folders.CompressPlan]: a folder becomes a `.tar.gz`, by `tar`; a `.tar.gz`,
`.tgz`, `.tar.xz`, `.tar.bz2` or `.zip` opens in this folder, a `.zip` in a folder of its name; a file compressed by `gzip`,
`bzip2`, `xz` or `zstd` is uncompressed; any other file is compressed by `gzip`. None replaces a file: `tar` keeps those
there, `-k`, so does `unzip`, `-n`, the others refuse, and a folder whose `.tar.gz` is there says `NAME.tar.gz exists
already`. `c` makes a `.tar.gz` or `.tgz`, a
`.tar.xz`, a `.tar.bz2` or a `.tar` by `tar`, or a `.zip` by `zip`, as [folders.ArchivePlan] says; an archive that is there
goes first, after a yes. Each waits at most 600 seconds, [folders.ArchiveLimit]. `=` runs
`git --git-dir=/dev/null diff --no-index --no-ext-diff --no-textconv --no-color -- A B`, the names after `--`, so that none
becomes an option, out of any repository, so that no `.git/` of the folder or above gives git a program to run (see
[Git](git.md#security)), and shows its lines as
[Git](git.md) shows a diff, the new lines in the colour of texts, the old ones in that of keywords; its answer starts with
the other file marked, or else the backup `NAME~`, or else the folder of the other pane.

`A` lists its places as [the search of a project](search.md#searching-a-project) does, `PATH:LINE:COLUMN` then the line,
the path from the folder shown, at most 10,000 places in 20,000 files, each of at most 1 MB and with no zero byte. `Q`
replaces in the text of the buffer of a file, when one is open, else in that of the file, through std/regex: `$1` in the
text that replaces stands for the first group of the pattern. Each file changed opens in a buffer, changed in one step of
undo and not saved, and the prompt line says how many places in how many files: `C-x C-s` saves each one, and `C-/` undoes
it. Neither follows a symbolic link.

Cemacs never holds the permission to run these programs. Each runs through `tools/folders.ce`, which Cemacs starts as
`cesia run --allow exec=PROGRAM tools/folders.ce`, with that one program alone: `gzip`, `tar`, `zip`, `unzip`, `bzip2`,
`xz`, `zstd`, `git`, or the shell of `!` and `&`. It runs the program with its arguments, each one word, never through a
shell but for `!` and `&`, in the folder shown, and gives back what it wrote, in JSON. A program missing from the `PATH`
says `PROGRAM can't run`, and the rest works.

### Views and help

| Keys | Command | What it does |
|---|---|---|
| `s` | [folders.NextSort] | sorts by date, then by size, then by name again |
| `(` | [folders.ToggleDetails] | hides the mode, the size and the age of each row, or shows them again |
| `.`, `C-c .` | [folders.ToggleHidden] | shows the names that start with a dot, or hides them again |
| `?` | [folders.KeysSummary] | says the main keys on the prompt line |

[folders.Letters] is the table of the letters and their commands, and [folders.StarLetters] and [folders.PercentLetters]
those of the second key after `*` and `%`. In a list, waiting after a prefix key shows the band of hints, as everywhere.

### What differs from Dired

Cemacs takes Dired's keys, and leaves out some of its commands:

- No subfolder shown inside the list, Dired's `i`: `o` or `C-o` shows a folder beside it.
- No change of owner or group, `O` and `G`, which most often need the rights of root, and no printing, `P`.
- No numeric argument before a command, as `3 m` or `C-u`: marks and filters do that work.
- `Q` replaces every place at once, where Dired's asks at each one: the buffers stay not saved, and `C-/` undoes a file.
- `/`, the filter, `C-c n`, `W` and `.` for the hidden names are Cemacs's own; Dired's `.`, which flags numbered backups,
  is not here.
- Folders come first in every sort, and a row shows the age of its file, where `ls -l` shows a date.

### Speed

The folder is read once each time it is shown, one listing and one look at each entry, two for a symbolic link; the filter
only filters the rows read then. A mark changes only its rows, and a sort or `(` makes the rows again from the entries read,
without reading the folder. [Speed](performance.md) has the times.

## The files of a project

| Keys | Command | What it does |
|---|---|---|
| `C-x p f`, `C-c f p` | [project.Files] | lists the files of the project of the current file, ranked as you type; Enter opens one |

A project, here, is a Git repository: the folder that holds a `.git`, and all that is below it. `C-x p f`, the key of Emacs's
`project-find-file`, opens a list of every file of the project of the current file, or of the folder Cemacs started in, by
its path from the root of the project. The files are those that Git lists, as Emacs's `project.el` reads them: the ones Git
tracks and the new ones it doesn't ignore, by the `.gitignore` files, with `git ls-files -z -c -o --exclude-standard
--deduplicate`. So `_build/` and the other ignored folders stay out. [project.Listed] does it: from any folder of the
project, it asks Git for the root, `git rev-parse --show-toplevel`, then for the files, and gives `{Root, Paths}` in an Ok,
or in an Err the words that the prompt line shows.

The prompt line shows `Find file in NAME: `, the name of the project's folder, then what you type. Typing filters the list
as in [every list](search.md#lists), and ranks it: the file that best matches comes first, by the score that Vim and Neovim
use, and words apart, `ml lib`, match in any order. Enter opens the file under the cursor and closes the list.
[A case: finding a file from a few letters](finding.md) tells why it ranks this way, and measures it on Cesia's 1,933 files.

The list is read once, when it opens: a file made after it is not in it until `C-x p f` again. Outside any Git repository,
the prompt line says `FOLDER/ is in no Git repository.`, and nothing opens. Cemacs runs Git with the permission `exec=git`:
see [Install](install.md#starting-it).
