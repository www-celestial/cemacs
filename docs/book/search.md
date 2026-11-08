# Search

Cemacs searches a buffer as Emacs does, incrementally: `C-s` opens the prompt line, and each letter you type moves the cursor
to the next place of the words typed so far, which shows selected. This chapter tells that search, then what else Cemacs
finds: rows in lists, keys, errors, and the places that the output of a program names. Search by regular expression, a
pattern such as `[0-9]+` that matches many texts, replace, Emacs's `M-%`, and a search through the files of a project are
not there yet.

## Searching a buffer

| Keys | Command | What it does |
|---|---|---|
| `C-s`, `C-c s s` | [commands.SearchForward] | searches forward from the cursor as you type; in a search, goes to the next place |
| `C-r`, `C-c s r` | [commands.SearchBackward] | the same, backward |

An incremental search is one that looks as you type, instead of waiting for the whole words: after `C-s` and `t`, the
cursor is after the first `t` past it; after `tw`, after the first `tw`, which may be the same place or a later one. The
place found shows selected, from its start to its end, and the screen follows it. Going forward, the cursor ends after the
place; going backward, at its start. While the search lasts, the prompt line says what it does:

| The prompt line | When |
|---|---|
| `I-search: WORDS` | a search forward, which found WORDS |
| `I-search backward: WORDS` | a search backward |
| `Failing I-search: WORDS` | no place of WORDS is left that way; the last place found stays selected |
| `Wrapped I-search: WORDS` | after the search went round the end of the file to its start, or round the start to the end backward |
| `Failing wrapped I-search: WORDS` | even round the end, nothing |

The keys while a search is open:

| Keys | What they do |
|---|---|
| a typed text, `C-y` | adds it to the words, and looks again from the start of the place found, so that the place stays while it still matches |
| `C-s` | the next place forward; once the search fails, the next `C-s` goes round to the start of the file |
| `C-r` | the next place backward, and round the end once it fails that way |
| `C-s` or `C-r` with no words yet | looks for the words of the last search again |
| `backspace` | takes back the last step, a letter or a `C-s`, with the place it had |
| `enter` | ends the search, the cursor at the place |
| `C-g` | when the search fails, takes back the letters that matched nothing; else ends the search where it started, and says `Quit` |
| any other key | ends the search at the place, then does what it does: `C-a` goes to the start of that line |

```cesia
use core/press
use core/view
use core/text
use src/emacs
use src/rope
use src/ui
start = view.Start([text.Of("one two\nthree two", missing)], ui.Look(ui.Dark, (w, f) -> 8, 19), {Width: 8, Height: 19}, 800, 600)
start.Config = () -> emacs.Config(emacs.Keys)
found = press.Press(["C-s", "two", "C-s"], start)
found.Prompt.Label --> "I-search: "
found.Buffers[1].Cursor --> {Line: 2, Column: 9}
press.Press(["C-s", "two", "C-s", "C-s"], start).Prompt.Label --> "Failing I-search: "
press.Press(["C-s", "two", "C-s", "C-s", "C-s"], start).Buffers[1].Cursor --> {Line: 1, Column: 7}
press.Press(["C-s", "three", "C-g"], start).Buffers[1].Cursor --> {Line: 1, Column: 0}
```

Case folding, the matching of a capital and a small letter as the same letter, follows Emacs: words with no capital match
either case, and words with one match exactly. `two` finds `Two` and `TWO`; `Two` finds only `Two`. Cesia knows the case of
the letters of ASCII only, so `é` never matches `É`. [commands.Folds] tells which:

```cesia
use core/commands
commands.Folds("two") --> true
commands.Folds("Two") --> false
```

The words are bytes to find, not a pattern: `a.b` finds the three characters `a.b`. A search lives in the prompt line, so
the buffer can't change while it is open; a key that would change it, as `C-k`, ends the search first.

### How it finds

Searching forward, [rope.Find] goes along the rope by runs of its leaves. A run is a sequence of leaves that view the same text,
each one starting where the one before ended: a file just opened is one run, the whole file; an edit splits it in two around
what was typed, a text of its own. A run that views its text to the last byte, as the whole file just opened, or the part
after the last edit, is searched in that text itself, with no copy, by one call of Cesia's [text.ByteFind]. Any other part
of the rope is read a window at a time: 64 KiB first, then twice as much at each window, up to 1 MiB, each window one slice of
the rope; each overlaps the one before it by the length of the words less one byte, so that a place across two windows is
found, and the places across the end of a run are looked for on their own, in a slice of twice the words. Searching backward,
[rope.FindBefore] reads windows going back from the cursor, as Cesia has no search that goes backward.

[text.ByteFind] finds the words eight bytes at a time: it looks for the rarest byte of the words with the test of SWAR, SIMD
within a register, that tells in a few instructions whether any byte of a 64-bit word is the one looked for, then compares the
words at each place it gives. With folding, `fold = true`, the letters of ASCII match in either case in the same pass, with
no copy of the text in lower case.

```cesia
r = rope.Of("ab ab ab")
[rope.Find("ab", 1, r), rope.FindBefore("ab", 6, r)] --> [3, 3]
rope.Find("AB", 1, r, fold = true) --> 3
```

Showing a place far away costs more than finding it: the colours of the lines on the screen depend on every line before
them, as a comment or a text opened on one line goes on over the next ones. The place is shown at once, with its colours
guessed, and they become exact over the next instants: see [Inside Cemacs](internals.md#a-far-place-first-its-exact-colours-after)
and [Speed](performance.md#search).

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
file from a few of its letters; Emacs's completion calls it the `flex` style. A space splits the filter into words, and each
word must match, in any order, as in Vim and Neovim: `ce cmd` matches `commands.ce` too. [lists.Matches] tells whether a
filter matches:

```cesia
use core/lists
lists.Matches("cmd", "commands.ce") --> true
lists.Matches("CMD", "commands.ce") --> true
lists.Matches("dmc", "commands.ce") --> false
lists.Matches("ce cmd", "commands.ce") --> true
```

The filter reads the words of a row, or its key when it has one: a row of the folder manager has the file's name as its key,
so a filter never matches a size or a date. Each character is found natively, with [text.ByteFind], after the one before
it, as [lists.Filtered] does. In a list whose rows are made once, as the files of a folder and the keys, a letter added filters only
the rows shown before it; the buffers and the output are made again at each event, since they change. [Speed](performance.md)
has the times of a folder of 10,000 files.

```cesia
rows = [{Words: "editor.ce", Item: 1}, {Words: "commands.ce", Item: 2}, {Words: "commands.test.ce", Item: 3}]
[r.Item for r in lists.Filtered("cmt", rows)] --> [3]
```

When a filter changes the rows, the cursor stays on the row it was on if that row is still shown, else on the same line.

Most lists keep their rows in their order. The list of [the files of a project](files.md#the-files-of-a-project), `C-x p f`,
ranks them instead: the rows the filter keeps come the best first, by [lists.Score], the score of fzy that Vim and Neovim
use, which rewards the letters found at the start of a word or side by side, and of two paths alike, the shorter.
[lists.Ranked] gives that order; [A case: finding a file from a few letters](finding.md) tells why, and measures it.

```cesia
[r.Item for r in lists.Ranked("cmt", rows)] --> [3]
[r.Item for r in lists.Ranked("cmd", rows)] --> [2, 3]
```

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
