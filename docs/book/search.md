# Search

Cemacs has no search inside a buffer yet. Emacs's incremental search, which finds the next match as each letter is typed
(`C-s` and `C-r`), its search by regular expression, its replace (`M-%`), and a search through the files of a project are not
there: `C-s` says `C-s is not bound.` This chapter tells what Cemacs does find today: rows in lists, keys, errors, and the
places that the output of a program names.

## Lists

A list is a buffer of rows that Cemacs makes for you: the buffers (`C-x C-b`), the files of a folder (`C-x d`), the keys after
a prefix (`C-x ?`), the output of a program (`C-c c o`). Each row stands for something, a buffer, a file, a key or a line of
output, and Enter acts on the row under the cursor. A list is read only: a command that would change its text, as `C-w` or
undo, is taken back, and the prompt line says `This list is read only.` Moves, the selection and `M-w` work in it as in any
buffer, so a row can be copied.

Typing in a list filters it: only the rows that match what you typed stay, in their order. The prompt line shows the filter
after `Filter: `, or after the path in the folder manager. Backspace takes back the last character; `C-g` clears the filter,
and with no filter closes the list and goes back to the buffer it was opened from.

| Keys in a list | Command | What it does |
|---|---|---|
| a typed text | [commands.AddToFilter] | adds it to the filter |
| `backspace`, `S-backspace` | [commands.ListBack] | takes back the last character of the filter |
| `C-g` | [commands.ListCancel] | clears the filter, or closes the list |

### How a filter matches

A row matches when the characters of the filter come in its words in the same order, side by side or not, whatever their
case: `cmd` matches `commands.ce`. This is subsequence matching, the kind of fuzzy matching that many editors use to find a
file from a few of its letters; Emacs's completion calls it the `flex` style. [lists.Matches] tells whether a filter
matches:

```cesia
use core/lists
lists.Matches("cmd", "commands.ce") --> true
lists.Matches("CMD", "commands.ce") --> true
lists.Matches("dmc", "commands.ce") --> false
```

The filter reads the words of a row, or its key when it has one: a row of the folder manager has the file's name as its key,
so a filter never matches a size or a date. One letter alone is a plain search for that letter, run natively, as
[lists.Filtered] does. In a list whose rows are made once, as the files of a folder and the keys, a letter added filters only
the rows shown before it; the buffers and the output are made again at each event, since they change. [Speed](performance.md)
has the times of a folder of 10,000 files.

```cesia
rows = [{Words: "editor.ce", Item: 1}, {Words: "commands.ce", Item: 2}, {Words: "commands.test.ce", Item: 3}]
[r.Item for r in lists.Filtered("cmt", rows)] --> [3]
```

When a filter changes the rows, the cursor stays on the row it was on if that row is still shown, else on the same line.

## Keys

To find a key without knowing it:

- Press a prefix key and wait half a second: the band of hints lists what can follow. Under `C-c`, the keys are in groups,
  `C-c f` for the files and so on: see [Windows and panes](windows.md#the-band-of-hints).
- Press `?` after a prefix key, as `C-x ?`, `C-c ?` or `C-c f ?`: a list of every key that starts with that prefix, at any
  depth, with the name of its command and the first line of its documentation. Typing filters it, and Enter closes the list and
  runs the key under the cursor, as if you had pressed it.

The keys that only a list has, such as `C-c n` in the folder manager, are not in these lists. [Keys](keys.md) has the full
table.

## Errors

| Keys | Command | What it does |
|---|---|---|
| `M-g n`, `C-c c n` | [check.NextError] | the cursor on the next error or warning after it, and its words on the prompt line |
| `M-g p`, `C-c c p` | [check.PreviousError] | the cursor on the one before it |

Both go round the ends: after the last one comes the first. A buffer with none says `No error here.`
[Errors in the lines](check.md) tells where the errors come from.

## Places in the output

`C-c c o`, or `C-c C-o`, opens the output of the last run as a list, with the cursor on its last error. Enter on a line that
names a place of a file opens that file, or goes to its buffer, with the cursor there. Two forms name a place, as Cesia writes
its errors: `PATH:LINE:COLUMN: ` at the start of the line, the place of an error, and `(PATH:LINE)` at its end, the place of
a call under it. [output.PlaceIn] reads them, with columns from 1:

```cesia
use src/output
output.PlaceIn("src/a.ce:4:11: Index 5 is outside this array of 2 elements.") --> {Path: "src/a.ce", Line: 4, Column: 11}
output.PlaceIn("  called from f (a.ce:3)") --> {Path: "a.ce", Line: 3, Column: 1}
output.PlaceIn("> cesia run a.ce") --> missing
```

A line that names no place says `This line names no place of a file.`, and a file that isn't there says `PATH isn't there.`
A path is read from the folder where Cemacs started, as Cesia wrote it.
