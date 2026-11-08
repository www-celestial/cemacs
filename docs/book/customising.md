# Changing Cemacs

Cemacs is changed in Cesia, as Emacs is changed in Emacs Lisp: its settings, its keys and its commands are functions of its
own code, and a change can load into the window that runs. This chapter tells where things are, how to change a setting or
a key, how to write a command, a list and an app of your own, and the rules a change must follow to reload safely.

## Where things are

| Folder | What it holds |
|---|---|
| `core/` | the core: the buffer, the keys, the frame, the files, the commands, the run of a program. It binds no key and knows no app. |
| `src/emacs/` | the keys of Emacs and the settings |
| `src/buffers/`, `src/folders/`, `src/check/`, `src/output/`, `src/help/` | the apps: the list of buffers, the folder manager, the check, the output as a list, the `?` lists |
| `src/rope/`, `src/history/`, `src/sdl/`, `src/ui/` | the rope, the undo history, the window through SDL3, the theme and the rectangles |
| `src/cemacs.ce` | the program: it merges the keys of every app, makes the config, and opens the window |

`C-c f c` opens `src/cemacs.ce`, the place to start. Here it is, its comments left out:

```cesia norun
use src/buffers
use src/check
use src/emacs
use core/editor
use src/folders
use src/help
use src/output
use std/dict
use std/io

Keys() = help.WithHelp(dict.Merge(dict.Merge(dict.Merge(dict.Merge(emacs.Keys(), buffers.Keys()), folders.Keys()), check.Keys()), output.Keys()))

Config() = check.Hooked(emacs.Config(Keys))

io.Print(editor.Start(Config))
```

[dict.Merge] gives the keys of its second argument the last word, so for a key in two apps, the later one wins.

## Settings

The settings are functions of `src/emacs/emacs.ce`, each with no parameter. Their values today, read from the code as this
page was built:

```cesia
use src/emacs
[emacs.TabText(), emacs.WheelLines(), emacs.DragZone(), emacs.FontSize(), emacs.HintDelay(), emacs.CheckDelay()] --> ["  ", 3.0, 4, 15, 0.5, 0.5]
```

| Setting | Unit | What it says | Read |
|---|---|---|---|
| [emacs.TabText] | a text | what Tab types | at each Tab |
| [emacs.WheelLines] | lines, a float | the lines that one notch of the wheel moves the screen; a touchpad sends parts of a notch | at each turn of the wheel |
| [emacs.DragZone] | pixels | how far the mouse may go from a press, on either axis, for it to stay a click | at each move of the mouse |
| [emacs.FontSize] | points | the size of the three fonts | once, when the window opens |
| [emacs.HintDelay] | seconds | the wait after a prefix key before the band of hints shows | at each tick |
| [emacs.CheckDelay] | seconds | the time with no key after which a Cesia buffer that changed is checked | at each tick |

To change one, change its function and save:

```cesia norun
(* in src/emacs/emacs.ce *)
TabText() = "    "
HintDelay() = 0.3
```

With `cesia do dev`, the new value works at once, since each is read at its next use; `FontSize` waits for the next start,
since the window reads it once. With `bin/cemacs`, every change waits for the next start.

Some values are not settings but parts of the code, and changing one means changing that code:

| Value | Where |
|---|---|
| the theme, dark | `ui.Dark` in `core/editor/editor.ce`; `src/ui` also has `ui.Light` |
| the fonts | `fonts/`, opened in `core/editor/editor.ce` |
| the size of the window at the start, 1280 by 720 | `core/editor/editor.ce` |
| the 1,000 states of the undo history | `src/history/history.ce`, the `limit` of `history.Of` |
| the 1,000 lines kept of the output | `kept` in `core/run/run.ce` |
| the largest file opened, 16 MiB | `largest` in `core/files/files.ce` |
| the colours of the errors and the breakpoints | `core/view/view.ce` |

## The config

The editor runs on a config, a record of functions that `emacs.Config` makes and `src/cemacs.ce` hands to the window:

| Field | What it gives |
|---|---|
| `Keys` | the global keymap |
| `PromptKeys`, `PromptMouseKeys` | the keys and the mouse while a question is open |
| `MouseKeys` | the mouse, by the action of its event |
| `ListKeys` | the keys of every list, over the global ones |
| `TabText`, `WheelLines`, `DragZone`, `FontSize`, `HintDelay`, `CheckDelay` | the settings |
| `Idle`, `Saved`, `Moving` | the hooks, which [check.Hooked] adds: see below |

Each field is a function, and so is the config itself: the state of the editor holds the function `Config`, and calls it each
time it needs a key or a setting. That is what makes a change apply at the next key under `--watch`: a reload gives the
function new code, and the next call runs it.

## Keys of your own

A key binding is an entry of a keymap: the key sequence as a text, and the function it runs. Any function from a state to a
state will do: a command of [core/commands], one of your own, or one written in place.

```cesia norun
(* in src/emacs/emacs.ce: three lines added at the top of Keys(), the others left as they are *)
Keys() = {
  "C-c t": "tools",
  "C-c t s": commands.Save,
  "C-c t h": s -> commands.Say("Hello", s)
}
```

- A key sequence is its chords with a space between them, as many as you like: `"C-c t s"`.
- A text in place of a function names a group: `"C-c t": "tools"` makes `C-c t` a prefix key, shown as `+tools` in the band
  of hints. Without it, the band shows `+more`.
- `?` after the new prefix, `C-c t ?`, lists its keys by itself, since `help.WithHelp` adds `?` after every prefix key.
- A function written in place has no name, so the band and the `?` lists show it as `a function`: give it a name, with a
  `(** *)` comment, to have it shown.
- To take a key away, take its line away.

Bindings to the mouse take the event as well as the state: `"wheel": (event, s) -> ...`, as in `MouseKeys`.

## A command of your own

A command takes the state and gives the next one. Nothing in it is special: the state is a value, a map of fields, so a
command reads the fields it needs and gives a state with some of them changed. The current buffer is
`state.Buffers[state.Current]`, and [core/text] has the functions that move in a buffer and edit it, each from a buffer to a
buffer.

Here is a command that writes the line of the cursor again below it, as one step of undo, tried on the real editor with
[press.Press], as the tests of Cemacs try theirs:

```cesia
use core/commands
use core/press
use core/text
use core/view
use src/rope
use src/ui
use std/dict
use std/value

defn DuplicateLine(state)
  (** The line of the cursor written again below it, the cursor on the copy. *)
  b = state.Buffers[state.Current]
  words = rope.Line(b.Cursor.Line, b.Rope)
  s = state
  s.Buffers[state.Current] = text.InsertWords("\n$words", text.ToLineEnd(b))
  s
end

(** The keys of Emacs, with a group of our own. *)
mine() = dict.Merge(emacs.Keys(), {"C-c t": "tools", "C-c t d": DuplicateLine})

defn tried(words)
  (** The editor on these keys, with one buffer holding words and no window. *)
  s = view.Start([text.Of(words, missing)], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, 800, 600)
  s.Config = () -> emacs.Config(mine)
  s
end

textOf(state) = rope.Text(state.Buffers[state.Current].Rope)   (** The text of the current buffer. *)

textOf(press.Press(["C-c", "t", "d"], tried("hello"))) --> "hello\nhello"
textOf(press.Press(["C-c", "t", "d", "C-/"], tried("hello"))) --> "hello"
```

[commands.Say] puts a message on the prompt line, and [commands.Ask] asks a question there: its third argument gets the
answer and the state, with the question closed. A command that goes to a line:

```cesia
use std/text as str

GoToLine(state) = commands.Ask("Go to line: ", "", wentTo, state)   (** Asks for a line, and puts the cursor at its start. *)

defn wentTo(answer, state)
  (** The cursor at the start of the line answered, or a message if the answer is no number. *)
  n = str.Number(answer)
  if not value.IsInt(n)
    return commands.Say("$answer is no line number.", state)
  end
  s = state
  s.Buffers[s.Current] = text.Place(n, 0, s.Buffers[s.Current])
  s
end

asked = dict.Put("C-c t g", GoToLine, mine())
s = view.Start([text.Of("a\nb\nc", missing)], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, 800, 600)
s.Config = () -> emacs.Config(() -> asked)
press.Press(["C-c", "t", "g", "3", "enter"], s).Buffers[1].Cursor --> {Line: 3, Column: 0}
press.Press(["C-c", "t", "g", "x", "enter"], s).Message --> "x is no line number."
```

[text.Place] brings a line past the end back inside the text, so `99` goes to the last line. [commands.Confirm] asks a
question of `y` or `n` the same way.

The building blocks of [core/commands] for an app are: [commands.Say], [commands.Ask], [commands.Confirm],
[commands.OpenFile], [commands.ShowList], [commands.ToBuffer], [commands.AddToFilter], [commands.Clipboard],
[commands.Bindings], [commands.Chords], [commands.Home] and [commands.Still]; every command of the tables of [Keys](keys.md)
can be called too.

## A list of your own

A list shows rows, and runs keys on the row under the cursor. [commands.ShowList] opens one: a name, the rows, each
`{Words, Item}` where `Item` is what the row stands for, and a function that gives the keys of the list, whose commands take
the item and the state. Here is an outline of a file, the lines that start a function, where Enter goes to one; Emacs has
`imenu` for this:

```cesia
use core/lists

defn Outline(state)
  (** Lists the lines that start a function, and Enter goes to the one under the cursor. *)
  b = state.Buffers[state.Current]
  rows = [{Words: "$n  $(rope.Line(n, b.Rope))", Item: n} for n in 1..rope.LineCount(b.Rope) if str.StartsWith("defn ", rope.Line(n, b.Rope))]
  commands.ShowList("Outline", rows, () -> {"enter": jumped}, state)
end

defn jumped(n, state)
  (** Back to the buffer the list was opened from, the cursor on line n. *)
  s = commands.ToBuffer(lists.Of(state.Buffers[state.Current]).Back, state)
  s.Buffers[s.Current] = text.Place(n, 0, s.Buffers[s.Current])
  s
end

listed = dict.Put("C-c t o", Outline, mine())
code = view.Start([text.Of("defn a()\n  1\nend\ndefn b()\n  2\nend", "f.ce")], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, 800, 600)
code.Config = () -> emacs.Config(() -> listed)
textOf(press.Press(["C-c", "t", "o"], code)) --> "1  defn a()\n4  defn b()"
press.Press(["C-c", "t", "o", "b", "enter"], code).Buffers[1].Cursor --> {Line: 4, Column: 0}
```

Typing `b` filtered the list to the second row, and Enter went there, closing the list. The rows can also be a function of
the state, which the list calls at each event, for rows that change, as the list of buffers does; `ShowList` takes three
more arguments by name: `free`, keys that need no row, `label`, the words before the filter, and `typed`, a function that
gets each typed text in place of the filter, as the folder manager uses them.

## An app of your own

An app is a folder of `src/` whose package gives a function `Keys()`, the keys that work everywhere:

```cesia norun
(* src/mine/mine.ce *)
(** My commands. *)
use core/commands

Keys() = {"C-c t": "tools", "C-c t d": DuplicateLine, "C-c t g": GoToLine, "C-c t o": Outline}   (** My keys. *)
```

In `src/cemacs.ce`, add `use src/mine`, and `mine.Keys()` to the keys that `Keys` merges. A new package needs a restart of
Cemacs: a program that runs can't load a package it didn't load at its start, and Cesia says so, `A running program can't load
a new module. Restart it to use this one.` After that, every change to the app reloads.

### Hooks

An app that needs to hear of time, or of saves, as the check does, goes through the hooks of the config, which the core calls:

| Hook | When the core calls it |
|---|---|
| `Idle(state)` | at each tick, the event that counts time, with [commands.Still] telling the seconds since the last key |
| `Saved(state)` | after each save |
| `Moving(state)` | at each pass of the loop: true asks for ticks, and for a frame at each one |

[check.Hooked] sets all three. A config without them has hooks that do nothing. To add your own beside those of the check,
wrap them, so that both run:

```cesia
use src/check

myIdle(s) = s   (** What my app does at each tick: here, nothing. *)

defn WithMine(config)
  (** The config with my Idle after the one already there. *)
  c = config
  before = config.Idle
  c.Idle = s -> myIdle(before(s))
  c
end

Keys() = mine()   (** In src/cemacs.ce, the keys it merges. *)
Config() = WithMine(check.Hooked(emacs.Config(Keys)))
value.IsFunction(Config().Idle) --> true
```

Ask for ticks only while there is something to wait for: an editor whose `Moving` is false draws nothing until the next
event, and only looks for one every 5 milliseconds.

## Reloading Cemacs while it runs

`cesia do dev`, from the folder of Cemacs, runs it under `--watch`: at each save of one of its files, Cesia loads the new
code into the program that runs, without closing the window or losing the buffers. This is a hot reload, as Cesia's book
calls it.

A reload changes the functions, and runs nothing at the file level again. So a change must follow three rules, which the code
of Cemacs keeps everywhere:

1. **Values are functions.** `Keys() = {...}` and `TabText() = "  "` give what the code says at each call. A variable at the
   file level, `Keys = {...}`, would keep its old value until a restart; and a new one, added by a reload, would be read
   before it has a value, which stops the program, with its unsaved text.
2. **A field added to the state is read through a `match` with a default.** The state lives through a reload, so it may
   come from code that didn't have the field yet, and reading a field a map doesn't have stops the program. The code of
   Cemacs reads each later field this way, as [commands.Still] does:

   ```cesia norun
   defn Still(state)
     match state
       {Still: seconds} -> seconds
       else -> 0.0
     end
   end
   ```

   Writing a field adds it, so only reading needs the care.
3. **A new package needs a restart**, as above.

A mistake that doesn't load, a name that doesn't exist or a syntax error, is shown in the terminal that runs `cesia do dev`,
and the old code stays. A mistake that loads but fails when it runs, such as a function bound to a key with the wrong number
of parameters, stops the program when the key is pressed, and the text not saved is lost: Cesia has no way to catch it. Save
your buffers before you try a change on the editor you write it in.

`tests/reload-check.sh` proves the rules in a window: it changes keys and settings of a running Cemacs, as a person would save
them, and checks each one at the next key.

## Testing a change

`cesia test` runs the tests of every package, the examples of its `(** *)` comments and its test functions, as Cesia's book
tells in its chapter on tests; `cesia test core/commands` runs those of one package. `cesia do test` runs the whole suite,
both paths of Cesia included: see [Install](install.md#checking-the-install). [press.Press] plays keys through the editor
with no window, as the examples above do.
