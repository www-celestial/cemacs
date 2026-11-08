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
at the end of the answer. It has no completion, the help that finishes a name from the files that exist.

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
| larger than 16 MiB, 16,777,216 bytes | `PATH is too large to open: SIZE bytes, and the limit is 16777216.` |
| not valid UTF-8, or holding a zero byte | `PATH is not valid UTF-8 text, or holds a zero byte.` |
| unreadable, such as without the permission of the system | the reason that Cesia gives |

A device or a FIFO says it has the size 0, and reading one may never end or fill the memory, so Cemacs asks the system what
a file is before it reads it. The limit of size keeps a file too large for memory from stopping the editor, with every
buffer's unsaved text: [Speed](performance.md#opening-a-file) has what a large file costs.

### Encodings

An encoding is the way the characters of a text become bytes in a file. Cemacs reads and writes UTF-8 only, the encoding of
Cesia's code and of most text today, where a character takes one to four bytes. A file is valid UTF-8 when each of its byte
sequences is one that RFC 3629 allows: [files.IsText] refuses an overlong form, a character written in more bytes than it
needs; a surrogate, a code from U+D800 to U+DFFF that UTF-16 uses in pairs and that is no character; and a code above
U+10FFFF, the last one of Unicode. A file in Latin-1 breaks these rules as soon as it holds a character outside ASCII, and a
file in UTF-16 holds zero bytes, so such a file stays closed instead of showing wrong characters and being saved broken.

```cesia
use std/text
files.IsText("café") --> true
files.IsText(text.FromBytes([0x63, 0x61, 0x66, 0xE9])) --> false
files.IsText(text.FromBytes([0x61, 0, 0x62])) --> false
```

The second text is `café` in Latin-1, where `é` is the one byte `E9`. A file that starts with the byte order mark of UTF-8,
the bytes `EF BB BF` that some programs write first, is valid UTF-8: it opens, the mark stays the first character of the
buffer, and a save writes it back.

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
   The new file is the only one Cemacs ever removes.
2. Once it is written in full, a rename puts it in place of the old file. On Linux, a rename within one file system, as
   here, is atomic: at every instant the name leads to the whole old file or to the whole new one, never to a part of
   either.
3. If writing or renaming fails, the new file is removed, the old one stays whole, the buffer keeps its text and its star,
   and the prompt line tells the reason, naming your file, not the new one.

This protects the file from a failure of Cemacs, of the disk being full, or of a permission. It doesn't flush the system's
caches to the disk, as `fsync` would, so a loss of power right after a save may still lose that save on some file systems.

Since the saved file is a new one, it doesn't keep what belonged to the old one: its permissions are those of a new file,
`rw-r--r--` with the usual `umask`, so a script loses its right to run and a read-only file becomes writable; a symbolic link
is replaced by a plain file, its target left as it was; and a hard link no longer shares the text. The folder must let you
write in it, for the new file.

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

The folder manager is a list of the files and folders of a folder, as Emacs's Dired is. The list is named by the folder's
absolute path, and the prompt line shows that path, ending with `/`, followed by what you type. Here are the rows of a
folder, as [folders.Rows] makes them from its entries, two hours after the last change of each:

```cesia
use src/folders
use std/io
entries = [{Name: "cesia.toml", IsDir: false, Size: 262, Modified: 0}, {Name: "src", IsDir: true, Size: 0, Modified: 0},
  {Name: ".git", IsDir: true, Size: 0, Modified: 0}, {Name: "LICENSE", IsDir: false, Size: 1069, Modified: 0}]
for row in folders.Rows(entries, false, 7200)
  io.Print(row.Words)
end
```

Folders come first, each with a `/` after its name, then files, each in the order of their names. A file shows its size,
counted by 1000: `B` for bytes up to 999, then `kB`, `MB`, `GB` and `TB`, with one decimal below 10, as
[folders.SizeText] does. Its age says when it last changed: `now` under a minute, then minutes, hours, and days up to 30,
then the date, as [folders.AgeText] does.

```cesia
folders.SizeText(142) --> "142 B"
folders.SizeText(3250) --> "3.3 kB"
folders.AgeText(7200, 0) --> "2 h"
```

The date is in UTC, the time of Greenwich, and a row shows no hour of the day. Names take the colours of the code by what
they are: a folder as a name, a hidden one faint as a comment, code as a text (`.ce`, `.ml`, `.c`, `.py`, `.sh`, `.el` and
other languages), settings and data as a keyword (`.toml`, `.json`, `.yaml`, `.csv`, `.lock` and others), pictures, fonts and
archives as a field (`.png`, `.svg`, `.ttf`, `.pdf`, `.zip`, `.tar` and others), anything else plain.

A name that starts with a dot is hidden, as most file managers do on Linux: `C-c .` shows the hidden names or hides them
again.

### Moving through folders

What you type goes on the path of the prompt line:

| You type | What it does |
|---|---|
| letters | filter the names, as in any list |
| part of a folder's name, then `/` | goes into the folder under the cursor if it is one, else into the first folder shown, or says `No folder matches.` |
| `/` with nothing typed | goes to the root, `/` |
| `~`, then `/` | goes to your home folder, from `HOME`, or says `HOME is not set.` |
| `backspace` | takes back the last letter, or with none goes to the folder above, the cursor on the one just left |
| `C-y` | goes to the path in the clipboard: a folder opens, a file shows its folder with the cursor on it |
| `enter` | a folder opens in the list; a file opens in a buffer, and the list closes |

`backspace` at the root says `This is the root.` A pasted path may start with `/`, with `~`, or be relative to the folder
shown; one that leads nowhere says `No file or folder at PATH.`

### Making, renaming and trashing

| Keys | What it does |
|---|---|
| `C-c n` | asks `New file, or folder/: `: a name that ends with `/` makes a folder, with the folders above it; any other an empty file |
| `C-c r` | asks `Rename NAME to: `, with the name to change; a path in the answer moves the file or folder there |
| `C-c k` | asks `Move NAME to the trash? (y or n) `, then moves the row under the cursor to the trash |

These keys work only in the folder manager. A name that exists already is refused with `NAME already exists.`, and an empty
one says `No name.` After each, the folder is read again, and the cursor goes to the name.

Nothing is ever deleted for good: `C-c k` moves to the trash, the folder from which the file manager of your desktop can
restore a file. Cemacs follows the Trash specification of freedesktop.org, version 1.0, for the trash in your home:

- The trash is `$XDG_DATA_HOME/Trash`, or `~/.local/share/Trash` when `XDG_DATA_HOME` isn't set. Without `HOME` either, it
  says `There is no trash: HOME is not set.`
- The file or folder goes into `files/`, under its own name, or `NAME.2`, `NAME.3` and so on when that one is taken.
- Its info goes into `info/NAME.trashinfo` first, as the specification asks: its path from the root, each part
  percent-encoded, as URLs write a space `%20`, and the date it was trashed. If the move then fails, the info is removed.

```cesia
folders.TrashInfo("/home/me/my notes.ce", 0) --> "[Trash Info]\nPath=/home/me/my%20notes.ce\nDeletionDate=1970-01-01T00:00:00\n"
```

Cemacs differs from the specification in three points. It writes the date in UTC, where the specification asks for local
time. It finds a free name by looking at the names taken, where the specification asks for an exclusive creation, one that
fails when the name exists, so two programs trashing the same name at the same instant could clash. And for a file on another disk than your home, where a rename can't reach the trash, it doesn't use the trash folder
that the specification puts at the top of that disk: the move fails, and the prompt line says
`Can't move NAME to the trash: REASON`, with the file left where it was.

The folder is read once each time it is shown, one listing and one look at each entry; typing only filters the rows read
then. [Speed](performance.md) has the times.
