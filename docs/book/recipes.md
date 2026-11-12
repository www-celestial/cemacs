# Recipes

Each recipe here is one small task, done in your own folder, `user/`: what it does, the code to put there, how to bind or
call it, and what you see. The code of every recipe ran when this page was built, on the editor itself with no window, and
the lines with `-->` checked what it does; the links under each recipe lead to the reference of every package and function
it uses. [Changing Cemacs](customising.md) tells the rules behind them.

## How a recipe plugs in

Your changes live in `user/config/config.ce`, which `C-c f c` opens. Cemacs calls its function `Changed` with the config it
made: the record of functions that the editor runs on, its keymaps, its settings and its hooks. What `Changed` gives back is
what the editor runs on. So each recipe below is a function from a config to a config, which changes a few fields of the
config and gives it back, and your `Changed` calls the recipes you want, one inside the other:

```text
defn Changed(config)
  (** Cemacs with my changes. *)
  Tools(MySettings(config))
end
```

Copy a recipe into `user/config/config.ce`, its `use` lines at the top of the file, and call it in `Changed`. The last
section, [All of them together](#all-of-them-together), runs a `Changed` that calls every recipe of this page.

The code below tries each recipe as `src/cemacs.ce` runs it. `cemacs` makes the config of Cemacs, its keys, the settings of
`src/emacs` and the hooks of the check, as your `Changed` gets it, and gives it to a recipe; `tried` makes the editor on that
config with one empty buffer, then opens the files given and runs the `Start` of the config, as the window does at its
start. [press.Press] then plays keys through the editor, as the tests of Cemacs do.

```cesia fold=code
use src/buffers
use src/check
use src/emacs
use src/folders
use src/help
use src/output
use src/project
use src/rope
use src/ui
use core/commands
use core/panes
use core/press
use core/text
use core/view
use std/dict
use std/value

(* The keys of Cemacs as src/cemacs.ce merges them: that file opens the window when it loads, so the page makes the same merge. *)
appKeys() = dict.Merge(dict.Merge(dict.Merge(dict.Merge(dict.Merge(emacs.Keys(), buffers.Keys()), folders.Keys()), project.Keys()), check.Keys()),
  output.Keys())

defn cemacs(changed)
  (** The config as src/cemacs.ce makes it, with changed in place of the Changed of user/config. *)
  c = changed(check.Hooked(emacs.Config(appKeys)))
  keys = c.Keys
  c.Keys = () -> help.WithHelp(keys())
  c
end

defn tried(changed, files)
  (** The editor on the config of changed, with no window: one empty buffer, then the files opened and the Start of the config run, as at the start. *)
  s = view.Start([text.Of("", missing)], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, 800, 600)
  s.Config = () -> cemacs(changed)
  commands.Settled(cemacs(changed).Start(commands.OpenAll(files, s)))
end

here(state) = state.Buffers[state.Current]   (** The buffer being edited. *)
textOf(state) = rope.Text(here(state).Rope)   (** Its text. *)
```

This page runs in a folder that holds the files its recipes open: `notes.md`, `todo.md`, `shop.ce`, `shop.test.ce` and
`user/notes/notes.md`.

## Your font, tab, theme and window

**What it does.** The text at 17 points instead of 15, Tab typing four spaces instead of two, the light theme instead of the
dark one, and a window of 1600 by 900 pixels at the start instead of 1280 by 720.

```cesia
use src/ui

defn MySettings(config)
  (** My settings: larger text, a tab of four spaces, the light theme and a larger window. *)
  c = config
  c.FontSize = () -> 17
  c.TabText = () -> "    "
  c.Theme = () -> ui.Light
  c.Window = () -> {Width: 1600, Height: 900}
  c
end
```

Each field of the config is a function, here written in place: `() -> 17` is a function with no parameter that gives 17.
`c = config` then `c.FontSize = ...` makes a new record, `config` left as it was. A field you don't set keeps the value of
Cemacs, so a setting that Cemacs adds later still comes through.

**How to use it.** Call it in `Changed`, `MySettings(config)`, and start Cemacs again: the window reads the size of the text,
the theme and its own size once, when it opens. Under `cesia do dev`, the tab works at the next Tab, without a restart.

**What you see.** The window opens at 1600 by 900, in the light theme, and Tab types four spaces:

```cesia
mine = cemacs(MySettings)
[mine.FontSize(), mine.Window()] --> [17, {Width: 1600, Height: 900}]
value.Equal(mine.Theme(), ui.Light) --> true
textOf(press.Press(["tab"], tried(MySettings, []))) --> "    "
```

A theme is a record of colours, each a number such as `0x0E1013`: red, green and blue in two hexadecimal digits each. A
theme of your own can start from one of the two of [src/ui] and change some of its colours, here a black ground around the
panes:

```cesia
defn Black()
  (** The dark theme on a black ground. *)
  t = ui.Dark
  t.Ground = 0x000000
  t
end

Black().Ground --> 0
```

`c.Theme = Black` then uses it: `Black` is a function with no parameter, so it is the field as it is.

More: [ui.Dark], [ui.Light], [emacs.FontSize], [emacs.TabText], [emacs.Theme], [emacs.Window], and every setting in
[Changing Cemacs](customising.md#settings).

## Two files side by side at the start

**What it does.** Each start opens two files of yours, one in a pane on the left and one on the right, and leaves you in the
right one. A pane is a part of the window that shows one buffer: [Windows and panes](windows.md#the-panes) tells them.

```cesia allow=read
use core/commands

(** The two files that I start with. *)
startFiles() = ["notes.md", "todo.md"]

defn SideBySide(state)
  (** The first file on the left, the second on the right, the right one being edited. *)
  files = startFiles()
  left = commands.OpenAll([files[1]], state)
  commands.OpenFile(files[2], commands.NextPane(commands.SplitRight(left)))
end

defn TwoFiles(config)
  (** Cemacs that starts on my two files, side by side. *)
  c = config
  c.Start = SideBySide
  c
end
```

`Start` is the field of the config that runs once, after the files given to `bin/cemacs` opened: a function from a state of
the editor to a new state, as a command is. [commands.OpenAll] opens the first file in the place of the empty buffer that
Cemacs starts with, where [commands.OpenFile] would keep that buffer beside it; [commands.SplitRight] splits the pane in two,
side by side, both on the first file; [commands.NextPane] goes to the right one; and the second file opens there.

Write the full paths of your files, as `/home/me/notes.md`: a relative path, as the two here, is read from the folder where
Cemacs started.

**How to use it.** Call it in `Changed`, `TwoFiles(config)`, and start Cemacs again: `Start` runs at the start only.

**What you see.** Two panes, `notes.md` on the left and `todo.md` on the right, the one you edit, and no other buffer:

```cesia
s = tried(TwoFiles, [])
[view.BufferName(s.Buffers[leaf.Buffer]) for leaf in panes.Leaves(panes.Tree(s))] --> ["notes.md", "todo.md"]
[panes.Active(s), value.Len(s.Buffers)] --> [2, 2]
```

More: [commands.OpenAll], [commands.OpenFile], [commands.SplitRight], [commands.NextPane], [panes.Leaves],
[panes.Active], [emacs.Start].

## A new empty buffer on a key

**What it does.** `C-c b e` makes a new buffer, with no text and no file, and shows it in the pane you edit: a place to
write what belongs to no file yet, as Emacs's `*scratch*` buffer is. A buffer is a text being edited and what Cemacs knows
of it, its cursor, its file and its undo: [Files and buffers](files.md#buffers) tells them. Cemacs has no such command, so
here it is:

```cesia
use core/text
use std/dict
use std/list
use std/value

defn NewBuffer(state)
  (** A new empty buffer with no file, in the pane being edited. *)
  s = state
  s.Buffers = list.Append(text.Of("", missing), state.Buffers)
  s.Current = value.Len(s.Buffers)
  s
end

defn NewBufferKey(config)
  (** Cemacs with C-c b e for a new empty buffer, in the group of the buffers. *)
  c = config
  c.Keys = () -> dict.Put("C-c b e", NewBuffer, config.Keys())
  c
end
```

The state of the editor holds its buffers, `state.Buffers`, and the number of the one being edited, `state.Current`; the
pane you edit always shows the current buffer, so making the new one current is all it takes. [text.Of] makes a buffer
from a text and a path, `missing` for none. The new keys are the keys of the config, `config.Keys()`, with one more put in
by [dict.Put].

**How to use it.** Call it in `Changed`, `NewBufferKey(config)`, and save: under `cesia do dev`, the key works at the next
key. `C-c b` is the group of the buffers, so the band of hints after `C-c b` lists `e` with the others.

**What you see.** A buffer named `untitled` in the mode line. Type in it; `C-x C-s` asks for a name, `Save as: `, and saves
it there.

```cesia
s = press.Press(["C-c", "b", "e", "hello"], tried(NewBufferKey, []))
[value.Len(s.Buffers), view.BufferName(here(s)), textOf(s)] --> [2, "untitled", "hello"]
press.Press(["C-x", "C-s"], s).Prompt.Label --> "Save as: "
```

More: [text.Of], [dict.Put], [list.Append], [commands.Save], [view.BufferName].

## Duplicate a line

**What it does.** The line of the cursor written again below it, the cursor on the copy, as one step of undo: `C-/` takes it
back at once.

```cesia
use core/text
use src/rope

defn DuplicateLine(state)
  (** The line of the cursor written again below it, the cursor on the copy. *)
  b = state.Buffers[state.Current]
  words = rope.Line(b.Cursor.Line, b.Rope)
  s = state
  s.Buffers[state.Current] = text.InsertWords("\n$words", text.ToLineEnd(b))
  s
end
```

The text of a buffer is a rope, `b.Rope`, a tree of pieces of text that [src/rope] reads: [rope.Line] gives the text of one
line. [text.ToLineEnd] moves the cursor to the end of its line, and [text.InsertWords] types a text there, as one step of
undo. Every function of [core/text] takes a buffer and gives a new one, which the command puts back in the state.

**How to use it.** It is a command: [A key group of your own](#a-key-group-of-your-own) binds it to `C-c t d`.

**What you see.** On a buffer that holds `hello`:

```cesia
one = press.Press(["hello"], tried(c -> c, []))
textOf(DuplicateLine(one)) --> "hello\nhello"
here(DuplicateLine(one)).Cursor --> {Line: 2, Column: 5}
textOf(press.Press(["C-/"], DuplicateLine(one))) --> "hello"
```

More: [rope.Line], [text.ToLineEnd], [text.InsertWords], [core/text].

## The test beside the code

**What it does.** In a file of Cesia, `shop.ce`, opens its tests, `shop.test.ce`, in a pane on the right; in the tests, opens
the code. Cesia keeps the tests of a package in files beside its code whose names end with `.test.ce`.

```cesia allow=read
use core/commands
use std/text as str
use std/value

defn otherOf(path)
  (** The test file of a file of Cesia, or the code of a test file. *)
  if str.EndsWith(".test.ce", path)
    "$(str.Slice(1, value.Len(path) - 8, path)).ce"
  else
    "$(str.Slice(1, value.Len(path) - 3, path)).test.ce"
  end
end

defn TestBeside(state)
  (** The tests of the file being edited in a pane on its right, or its code beside its tests. *)
  path = state.Buffers[state.Current].Path
  if value.IsMissing(path) or not str.EndsWith(".ce", path)
    return commands.Say("This buffer is no file of Cesia.", state)
  end
  commands.OpenFile(otherOf(path), commands.NextPane(commands.SplitRight(state)))
end
```

[commands.Say] puts a message on the prompt line, the line at the bottom of the window. A test file that doesn't exist yet
opens as an empty buffer for that path, which `C-x C-s` writes.

**How to use it.** A command: [A key group of your own](#a-key-group-of-your-own) binds it to `C-c t t`.

**What you see.** `shop.ce` on the left, `shop.test.ce` on the right, the one you edit; in a buffer of no file of Cesia, a
message:

```cesia
[otherOf("src/shop/shop.ce"), otherOf("src/shop/shop.test.ce")] --> ["src/shop/shop.test.ce", "src/shop/shop.ce"]
s = commands.Settled(TestBeside(tried(c -> c, ["shop.ce"])))
[view.BufferName(s.Buffers[leaf.Buffer]) for leaf in panes.Leaves(panes.Tree(s))] --> ["shop.ce", "shop.test.ce"]
TestBeside(tried(c -> c, ["notes.md"])).Message --> "This buffer is no file of Cesia."
```

More: [commands.OpenFile], [commands.SplitRight], [commands.NextPane], [commands.Say], [text.EndsWith], [text.Slice].

## Ask, then confirm: replace a word

**What it does.** Asks for a word and for what replaces it, then asks `y` or `n` with the count found, and replaces every one
in the buffer, as one step of undo. Cemacs has no replace of its own: this recipe makes a plain one, of a text as it is
written, with no pattern.

```cesia
use core/commands
use core/text
use src/rope
use std/text as str

defn Replace(state)
  (** Asks for a word and what replaces it, then, after y, replaces it everywhere in the buffer. *)
  commands.Ask("Replace: ", "", (old, s) -> if old == "" commands.Say("Nothing to replace.", s) else askedBy(old, s) end, state)
end

askedBy(old, state) = commands.Ask("Replace $old with: ", "", (by, s) -> confirmed(old, by, s), state)   (** Asks for what replaces old. *)

defn confirmed(old, by, state)
  (** Counts old in the buffer, and asks before it replaces them. *)
  n = str.Count(old, rope.Text(state.Buffers[state.Current].Rope))
  if n == 0
    return commands.Say("$old isn't in this buffer.", state)
  end
  commands.Confirm("Replace $n of $old? (y or n)", (yes, s) -> if yes == "y" replaced(old, by, n, s) else commands.Say("Nothing replaced.", s) end, state)
end

defn replaced(old, by, n, state)
  (** Every old of the buffer replaced by by, as one step of undo, the cursor back on its line, and the count said. *)
  b = state.Buffers[state.Current]
  words = str.Replace(old, by, rope.Text(b.Rope))
  all = text.ToFileEnd(text.SetMark(text.ToFileStart(b)))
  done = text.ClearMark(text.ReplaceRegion(e -> text.InsertWords(words, e), all))
  s = state
  s.Buffers[state.Current] = text.Place(b.Cursor.Line, b.Cursor.Column, done)
  commands.Say("Replaced $n.", s)
end
```

[commands.Ask] opens a question on the prompt line: a label, the answer it starts with, and a function that gets the answer
and the state once Enter closes the question. [commands.Confirm] asks the same way for `y` or `n`. The whole text is
selected, from the mark that [text.SetMark] puts at its start to the cursor at its end, and [text.ReplaceRegion] gives what
its function makes of the buffer without the selection, as one step of undo. [text.Count] and [text.Replace] count and
replace in a text; [text.Place] puts the cursor back on its line, or on the last line if the text got shorter.

**How to use it.** A command: [A key group of your own](#a-key-group-of-your-own) binds it to `C-c t r`.

**What you see.** `Replace: `, then `Replace TODO with: `, then `Replace 2 of TODO? (y or n)` on the prompt line; after `y`,
the text replaced and `Replaced 2.`; `C-/` takes it all back.

```cesia allow=read
todo = tried(c -> c, ["todo.md"])
asked = press.Press(["TODO", "enter", "DONE", "enter"], Replace(todo))
asked.Prompt.Label --> "Replace 2 of TODO? (y or n)"
done = press.Press(["y"], asked)
[done.Message, str.Count("DONE", textOf(done))] --> ["Replaced 2.", 2]
textOf(press.Press(["C-/"], done)) == textOf(todo) --> true
press.Press(["n"], asked).Message --> "Nothing replaced."
```

More: [commands.Ask], [commands.Confirm], [text.SetMark], [text.ReplaceRegion], [text.Place], [text.Count], [text.Replace].

## A list of your own: the lines to do

**What it does.** Lists the lines of the buffer that hold `TODO`, each with its number; typing filters them, and Enter goes
to the one under the cursor. A list is a buffer of rows, read only, which an app opens and whose keys work on the row under
the cursor: the list of buffers and the folder manager are lists.

```cesia
use core/commands
use core/lists
use core/text
use src/rope
use std/text as str

defn ToDo(state)
  (** Lists the lines of the buffer that hold TODO, and Enter goes to the one under the cursor. *)
  b = state.Buffers[state.Current]
  rows = [{Words: "$n  $(str.Trim(rope.Line(n, b.Rope)))", Item: n} for n in 1..rope.LineCount(b.Rope) if str.Contains("TODO", rope.Line(n, b.Rope))]
  commands.ShowList("To do", rows, () -> {"enter": wentTo}, state)
end

defn wentTo(n, state)
  (** Back to the buffer the list was opened from, the cursor at the start of line n. *)
  s = commands.ToBuffer(lists.Of(state.Buffers[state.Current]).Back, state)
  s.Buffers[s.Current] = text.Place(n, 0, s.Buffers[s.Current])
  s
end
```

[commands.ShowList] opens a list: its name, its rows, each `{Words, Item}` where `Item` is what the row stands for, here a
line number, and a function that gives the keys of the list, whose commands get the item of the row and the state.
[lists.Of] reads what a list knows, `Back` the buffer it was opened from, and [commands.ToBuffer] goes back there, closing
the list. Emacs's `occur` does this for any pattern.

**How to use it.** A command: [A key group of your own](#a-key-group-of-your-own) binds it to `C-c t l`.

**What you see.** The list `To do` with two rows; `pap` then Enter, which keeps the row of `paper`, goes to line 5:

```cesia allow=read
todo = tried(c -> c, ["todo.md"])
textOf(ToDo(todo)) --> "3  - TODO write the tests of the shop\n5  - TODO read the paper on ropes"
here(press.Press(["pap", "enter"], ToDo(todo))).Cursor --> {Line: 5, Column: 0}
```

More: [commands.ShowList], [commands.ToBuffer], [lists.Of], [rope.Line], [rope.LineCount], [text.Place],
[Search](search.md#lists) for how a filter matches.

## A key group of your own

**What it does.** `C-c t` becomes a group of your own, `tools`, with the four commands above: `C-c t d` duplicates the line,
`C-c t t` opens the test beside the code, `C-c t r` replaces a word, `C-c t l` lists the lines to do. A group is a prefix
key, a key that waits for the next one, whose binding is a name: the band of hints, which shows above the prompt line half
a second after a prefix key, shows it as `+tools`, then the keys under it.

```cesia
use std/dict

defn Tools(config)
  (** Cemacs with my group of tools under C-c t. *)
  c = config
  c.Keys = () -> dict.Merge(config.Keys(), {"C-c t": "tools", "C-c t d": DuplicateLine, "C-c t t": TestBeside, "C-c t r": Replace, "C-c t l": ToDo})
  c
end
```

A keymap is a dictionary from key sequences, texts such as `"C-c t d"`, to what they run. [dict.Merge] gives the keys of its
second argument the last word, so a key of yours wins over one of Cemacs; `C-c t` is free in Cemacs, in every buffer and
every list, as [Keys](keys.md) shows.

**How to use it.** Call it in `Changed`, `Tools(config)`, and save: under `cesia do dev`, the keys work at the next key.

**What you see.** Wait after `C-c`: the band shows `+tools` among the groups. Wait after `C-c t`: it shows `?`, `d`, `l`, `r`
and `t`, each with the name of its command. `C-c t ?` lists them in a list, with the first sentence of their comment:

```cesia
waited(keys) = commands.Update({Kind: "tick", Seconds: 1.0}, press.Press(keys, tried(Tools, [])))   (** The editor a second after keys. *)
[h.Name for h in waited(["C-c"]).Hints if h.Key == "t"] --> ["+tools"]
[h.Name for h in waited(["C-c", "t"]).Hints] --> ["ShowKeys", "DuplicateLine", "ToDo", "Replace", "TestBeside"]
textOf(press.Press(["C-c", "t", "?"], tried(Tools, []))) -->
```

The `?` after every prefix key, your own too, comes from [help.WithHelp], which `src/cemacs.ce` runs on the keys your
`Changed` gives. A command written in place, as `s -> commands.Say("hi", s)`, has no name: the band shows it as
`a function`, and the `?` list as `(a function)`. Give it a name and a `(** *)` comment to have it shown.

More: [dict.Merge], [help.WithHelp], [keys.Hints], [Keys](keys.md), [the band of hints](windows.md#the-band-of-hints).

## Something after each save

**What it does.** After each save, the prompt line tells the lines of the file too: `Saved notes.md, 5 lines`. A hook is a
function that the core calls at a moment, here `Saved`, after each save; the check of Cesia code has its own there already,
which marks the Cesia buffers to check again. This recipe wraps it, so that both run.

```cesia allow=read,write
use core/commands
use src/rope

defn counted(state)
  (** The message of the save, with the number of lines of the file. *)
  commands.Say("$(state.Message), $(rope.LineCount(state.Buffers[state.Current].Rope)) lines", state)
end

defn AfterSave(config)
  (** Cemacs that tells the lines of a file after each save, after the hook of the check. *)
  c = config
  c.Saved = s -> counted(config.Saved(s))
  c
end
```

`config.Saved` is the hook that the config had, the check's, which [check.Hooked] gave it before `Changed`: the new one
calls it first, then adds its words. A hook set without the one before would leave the Cesia buffers unchecked after a save.
[rope.LineCount] counts the lines, one more than the line ends.

**How to use it.** Call it in `Changed`, `AfterSave(config)`, and save: under `cesia do dev`, the next save tells it.

**What you see.**

```cesia
saved = press.Press(["- buy bread", "enter", "C-x", "C-s"], tried(AfterSave, ["notes.md"]))
saved.Message --> "Saved notes.md, 5 lines"
```

More: [check.Hooked], [commands.Say], [rope.LineCount], [Changing Cemacs](customising.md#hooks), which tells the three hooks.

## Your first app, in user/notes/

**What it does.** An app of notes: `C-c n n` opens your file of notes at its end, and `C-c n a` asks for a note, writes it at
the end of the file and saves it, without leaving the buffer you were in. The notes live beside the app, in
`user/notes/notes.md`, so `git pull` never touches them either. An app is a package, a folder of Cesia files: here
`user/notes/`, with this file in it, `user/notes/notes.ce`:

```cesia allow=read,write
use core/commands
use core/text

(** The file of my notes, beside this app in user/notes/. *)
notesPath(state) = "$(commands.Home(state))/user/notes/notes.md"

defn Open(state)
  (** Opens my notes, the cursor at their end, ready for the next one. *)
  s = commands.OpenFile(notesPath(state), state)
  s.Buffers[s.Current] = text.ToFileEnd(s.Buffers[s.Current])
  s
end

Add(state) = commands.Ask("Note: ", "", added, state)   (** Asks for a note, and writes it at the end of my notes. *)

defn added(note, state)
  (** The note written at the end of my notes, saved, and the buffer that was being edited being edited again. *)
  s = Open(state)
  s.Buffers[s.Current] = text.InsertWords("- $note\n", s.Buffers[s.Current])
  s = commands.Save(s)
  s.Current = state.Current
  commands.Say("Noted.", s)
end

(** The keys of my notes. *)
Keys() = {"C-c n": "notes", "C-c n n": Open, "C-c n a": Add}
```

[commands.Home] is the folder of Cemacs, where `user/` is. `C-c n`, n for notes, is free but in the folder manager, where it
keeps its own meaning, a new file: the keys of a list come over the global ones. The app's keys come in through `Changed`,
in `user/config/config.ce`, which gets the package with `use user/notes` at its top, and names it `notes`:

```cesia
use std/dict

defn WithNotes(config)
  (** Cemacs with the keys of my notes. *)
  c = config
  c.Keys = () -> dict.Merge(config.Keys(), notes.Keys())
  c
end
```

This page holds no package `user/notes`, so here a record with its function stands in for it, `notes = {Keys: Keys}`: in
your `config.ce`, `use user/notes` gives the real one.

```cesia
notes = {Keys: Keys}
```

**How to use it.** Make the folder `user/notes/` and the file `notes.ce`, add `use user/notes` and `WithNotes` to
`config.ce`, and start Cemacs again: a program that runs can't load a package it didn't load at its start, and under
`cesia do dev` Cesia says so, `A running program can't load a new module. Restart it to use this one.` After that, every
change to the app reloads at the next key. `cesia test user` runs the tests of your folder: a file `notes.test.ce` beside
`notes.ce`, with functions whose names start with `is`, as Cesia's book tells.

**What you see.** `C-c n n` opens `notes.md` with the cursor at its end; `C-c n a`, a note and Enter write it and save the
file, and you stay where you were:

```cesia
opened = press.Press(["C-c", "n", "n"], tried(WithNotes, ["todo.md"]))
[view.BufferName(here(opened)), here(opened).Cursor] --> ["notes.md", {Line: 4, Column: 0}]
noted = press.Press(["C-c", "n", "a", "call the bank", "enter"], tried(WithNotes, ["todo.md"]))
[noted.Message, view.BufferName(here(noted))] --> ["Noted.", "todo.md"]
rope.Text(noted.Buffers[2].Rope) --> "# My notes\n\n- Cemacs keeps user/ out of git\n- call the bank\n"
```

More: [commands.Home], [commands.OpenFile], [commands.Ask], [commands.Save], [text.ToFileEnd], [text.InsertWords],
[Changing Cemacs](customising.md#an-app-of-your-own).

## All of them together

Here is a `Changed` that calls every recipe of this page, as `user/config/config.ce` holds it once the recipes are copied in:

```cesia
defn Changed(config)
  (** Cemacs with every recipe of this page. *)
  WithNotes(AfterSave(Tools(NewBufferKey(TwoFiles(MySettings(config))))))
end
```

Each recipe changes its own fields, so their order counts only where two change the same one: here `NewBufferKey`, `Tools`
and `WithNotes` each add keys to those of the recipe before, and the last word goes to the outermost. The editor it gives:

```cesia
all = tried(Changed, [])
[cemacs(Changed).FontSize(), panes.Count(panes.Tree(all)), view.BufferName(here(all))] --> [17, 2, "todo.md"]
textOf(press.Press(["C-c", "t", "d"], all)) == "$(rope.Line(1, here(all).Rope))\n$(textOf(all))" --> true
```

`Changed` runs at each key, so a change of it applies at the next one under `cesia do dev`; `FontSize`, `Theme` and `Window`
wait for the next start, as `Start` does, and a new package of `user/` needs a restart.
