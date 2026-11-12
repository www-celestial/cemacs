# Changing Cemacs

Cemacs is changed in Cesia, as Emacs is changed in Emacs Lisp: its settings, its keys and its commands are functions of its
own code, and a change can load into the window that runs. Your changes go in a folder of your own, `user/`, which `git pull`
never touches. This chapter tells where that folder is and what it holds, how to change a setting or a key, how to write a
command, a list and an app of your own, and the rules a change must follow to reload safely. [Recipes](recipes.md) has small
tasks done that way, each with its code.

## Your folder, user/

`user/` is in the folder of Cemacs, beside `core/` and `src/`, and it is yours: Cemacs makes it once and never writes to it
again. The first time `bin/cemacs` or `cesia do dev` starts and finds no `user/`, it copies the template of Cemacs,
`tools/user-template/`, there, through `tools/user.sh`; when `user/` is there, even as a symbolic link, nothing is copied.
`.gitignore`, the list of names that git leaves out, holds `/user/`: git doesn't see the folder, `git status` doesn't show
it, and `git pull` brings the new code of Cemacs without touching it, where a change of yours to `src/emacs/emacs.ce` would
have to be merged with those of Cemacs at each `git pull`. To keep the history of your changes, make `user/` a git repository of its own: see
[Install](install.md#your-folder-user).

```text
cemacs/
  user/              yours: git ignores it
    config/
      config.ce      your settings, your keys and your start
    notes/
      notes.ce       an app of your own, as Recipes makes one
```

`user/config/config.ce` is your init file, the file of code that an editor runs at its start to apply your changes, as
`~/.emacs.d/init.el` is for Emacs and `~/.config/nvim/init.lua` for Neovim. `C-c f c` opens it. As the template makes it,
it changes nothing:

```cesia
(** Your changes to Cemacs: its settings, its keys and what it does at the start. Cemacs made this folder, user/, from tools/user-template the first time it
    started, and never writes to it again; git ignores it, so git pull leaves it as it is. C-c f c opens this file.
    src/cemacs.ce gives Changed the config that Cemacs makes, and runs on what it gives. Under cesia do dev, a change here works at the next key, but FontSize,
    Theme and Window, which the window reads when it opens, wait for the next start. An app of your own is a folder beside this one, as user/notes/ for
    use user/notes: use it here and merge its keys; a new package needs a restart. cesia test user runs the tests of this folder. *)
use core/commands
use src/ui
use std/dict

defn Changed(config)
  (** Cemacs with your changes. Each field of config is a function: set only those you change, so that a field Cemacs adds later still comes through. To try
      an example, take away the (* and *) around it, and save. *)
  c = config
  (* c.FontSize = () -> 17 *)
  (* c.TabText = () -> "    " *)
  (* c.Theme = () -> ui.Light *)
  (* c.Window = () -> {Width: 1600, Height: 900} *)
  (* c.Keys = () -> dict.Merge(config.Keys(), {"C-c t": "tools", "C-c t s": commands.Save}) *)
  (* c.Start = s -> commands.SplitRight(s) *)
  c
end
```

```cesia
use src/emacs
use std/value
value.Equal(Changed(emacs.Config(emacs.Keys)), emacs.Config(emacs.Keys)) --> true
```

`Changed` gets the config, the record of functions that the editor runs on, and gives it back changed: [The config](#the-config)
lists its fields. `c = config` and then `c.FontSize = ...` make a new record, the one given left as it was; each `(* *)` is
a comment, which Cesia skips. A field `Changed` doesn't set keeps the value of Cemacs, so a setting that a later version of
Cemacs adds comes through. `src/cemacs.ce` calls `Changed` each time the editor reads its config, at each key, so under
`cesia do dev` a change you save works at the next key, but for `FontSize`, `Theme`, `Window` and `Start`, read only at the
start: see [Reloading Cemacs while it runs](#reloading-cemacs-while-it-runs).

A mistake in `config.ce` that keeps it from loading, such as a name that doesn't exist, stops Cemacs at its start, with the
place of the mistake in the terminal: fix it with another editor, or move `user/` away, and Cemacs makes a new one from the
template at its next start. [Troubleshooting](troubleshooting.md#at-start) lists what the terminal shows.

## Where things are

| Folder | What it holds |
|---|---|
| `core/` | the core: the buffer, the keys, the frame, the files, the commands, the run of a program. It binds no key and knows no app. |
| `src/emacs/` | the keys of Emacs and the settings |
| `src/buffers/`, `src/folders/`, `src/project/`, `src/check/`, `src/output/`, `src/help/` | the apps: the list of buffers, the folder manager, the files of a project, the check, the output as a list, the `?` lists |
| `src/rope/`, `src/history/`, `src/sdl/`, `src/ui/` | the rope, the undo history, the window through SDL3, the theme and the rectangles |
| `src/cemacs.ce` | the program: it merges the keys of every app, makes the config, gives it to your `Changed`, and opens the window |
| `tools/user-template/` | the template that `user/` is made from |
| `user/` | yours: your config, `user/config/config.ce`, and your apps |

Here is `src/cemacs.ce`, its comments left out:

```cesia norun
use src/buffers
use src/check
use src/emacs
use core/editor
use src/folders
use src/help
use src/output
use src/project
use user/config as user
use std/dict
use std/io

Keys() = dict.Merge(dict.Merge(dict.Merge(dict.Merge(dict.Merge(emacs.Keys(), buffers.Keys()), folders.Keys()), project.Keys()), check.Keys()), output.Keys())

defn Config()
  c = user.Changed(check.Hooked(emacs.Config(Keys)))
  keys = c.Keys
  c.Keys = () -> help.WithHelp(keys())
  c
end

io.Print(editor.Start(Config))
```

[dict.Merge] gives the keys of its second argument the last word, so for a key in two apps, the later one wins.
`use user/config as user` loads your config, as the package named `user` here, and `Config` gives its `Changed` the config
of Cemacs: the keys of the apps, the settings and keys of [src/emacs] and the hooks of [check.Hooked]. After your `Changed`,
[help.WithHelp] adds `?` after every prefix key of the keys it gave, yours too, which lists the keys that follow it.

Cesia stops when a folder that `cesia.toml` names among those of the code is missing, and `cesia.toml` names `user`. So in a
clone where Cemacs never started, `cesia test`, `cesia check` and `cesia doc` say
`cesia.toml:4:1: The source folder "user" doesn't exist.` until one start, or `tools/user.sh`, makes it. `cesia do test`
makes it first.

## Settings

The settings of Cemacs are functions of `src/emacs/emacs.ce`, each with no parameter, but `Start`, which takes a state. Their
values today, read from the code as this page was built:

```cesia
use src/emacs
use src/ui
use std/value
[emacs.TabText(), emacs.WheelLines(), emacs.DragZone(), emacs.FontSize(), emacs.HintDelay(), emacs.CheckDelay()] --> ["  ", 3.0, 4, 15, 0.5, 0.5]
[value.Equal(emacs.Theme(), ui.Dark), emacs.Window()] --> [true, {Width: 1280, Height: 720}]
```

| Setting | Unit | What it says | Read |
|---|---|---|---|
| [emacs.TabText] | a text | what Tab types | at each Tab |
| [emacs.WheelLines] | lines, a float | the lines that one notch of the wheel moves the screen; a touchpad sends parts of a notch | at each turn of the wheel |
| [emacs.DragZone] | pixels | how far the mouse may go from a press, on either axis, for it to stay a click | at each move of the mouse |
| [emacs.FontSize] | points | the size of the three fonts | once, when the window opens |
| [emacs.HintDelay] | seconds | the wait after a prefix key before the band of hints shows | at each tick |
| [emacs.CheckDelay] | seconds | the time with no key after which a Cesia buffer that changed is checked | at each tick |
| [emacs.Theme] | a record of colours | the theme: [ui.Dark], or [ui.Light], or one of your own with the same fields | once, when the window opens |
| [emacs.Window] | pixels, `{Width, Height}` | the size of the window when it opens, which you can change after | once, when the window opens |
| [emacs.Start] | a function from a state to a state | what the editor does at its start, after it opened the files it was given: nothing | once, after the files opened |

To change one, set its field in your `Changed`, as a function: the template has an example of each, and a function from a
config to a config can gather yours, as each recipe of [Recipes](recipes.md) does:

```cesia
use src/check

defn MySettings(config)
  (** A tab of four spaces, and the band of hints sooner. *)
  c = config
  c.TabText = () -> "    "
  c.HintDelay = () -> 0.3
  c
end

[MySettings(check.Hooked(emacs.Config(emacs.Keys))).TabText(), MySettings(check.Hooked(emacs.Config(emacs.Keys))).HintDelay()] --> ["    ", 0.3]
```

`Changed` then gives `MySettings(config)`. With `cesia do dev`, the new value works at its next use; `FontSize`, `Theme` and
`Window` wait for the next start, since the window reads them once, and `Start` runs at the start only. With `bin/cemacs`,
every change waits for the next start. A config made without `Theme`, `Window` or `Start`, as a program that calls
[editor.Start] itself may make, gets the dark theme, 1280 by 720 and nothing.

Changing a function of `src/emacs/emacs.ce` itself works too, as before `user/` existed, but `git pull` then has to merge
your change with those of Cemacs.

Some values are not settings but parts of the code, and changing one means changing that code:

| Value | Where |
|---|---|
| the fonts | `fonts/`, opened in `core/editor/editor.ce` |
| the 1,000 states of the undo history | `src/history/history.ce`, the `limit` of `history.Of` |
| the 1,000 lines kept of the output | `kept` in `core/run/run.ce` |
| the largest file opened, 1 GiB | `largest` in `core/files/files.ce` |
| the colours of the errors and the breakpoints | `core/view/view.ce` |

## The config

The editor runs on a config, a record of functions that [emacs.Config] makes, [check.Hooked] adds the hooks to, your
`Changed` changes, and `src/cemacs.ce` hands to the window:

| Field | What it gives |
|---|---|
| `Keys` | the global keymap |
| `PromptKeys`, `PromptMouseKeys` | the keys and the mouse while a question is open |
| `MouseKeys` | the mouse, by the action of its event |
| `ListKeys` | the keys of every list, over the global ones |
| `CompleteKeys` | the keys of the list of completions, over the global ones |
| `TabText`, `WheelLines`, `DragZone`, `FontSize`, `HintDelay`, `CheckDelay`, `Theme`, `Window` | the settings |
| `Start` | what the editor does once at its start |
| `Idle`, `Saved`, `Moving` | the hooks, which [check.Hooked] adds: see below |

Each field is a function, and so is the config itself: the state of the editor holds the function `Config`, and calls it each
time it needs a key or a setting, two or three times for a key. That is what makes a change apply at the next key under
`--watch`: a reload gives the function new code, and the next call runs it. Your `Changed` runs at each of these calls, so
keep it to setting fields: the template's costs less than a microsecond, and [Speed](performance.md#start-up) has the
numbers.

## Keys of your own

A key binding is an entry of a keymap: the key sequence as a text, and the function it runs. Any function from a state to a
state will do: a command of [core/commands], one of your own, or one written in place. In your `Changed`, the new keys are
the keys of the config with yours merged over them:

```cesia
use core/commands
use std/dict

defn MyKeys(config)
  (** A group of my own, tools, under C-c t. *)
  c = config
  c.Keys = () -> dict.Merge(config.Keys(), {"C-c t": "tools", "C-c t s": commands.Save, "C-c t h": s -> commands.Say("Hello", s)})
  c
end

value.Len(dict.Keys(MyKeys(emacs.Config(emacs.Keys)).Keys())) - value.Len(dict.Keys(emacs.Keys())) --> 3
```

- A key sequence is its chords with a space between them, as many as you like: `"C-c t s"`.
- A text in place of a function names a group: `"C-c t": "tools"` makes `C-c t` a prefix key, shown as `+tools` in the band
  of hints. Without it, the band shows `+more`.
- `?` after the new prefix, `C-c t ?`, lists its keys by itself, since `src/cemacs.ce` runs [help.WithHelp] on the keys your
  `Changed` gives, which adds `?` after every prefix key.
- A function written in place has no name, so the band shows it as `a function`, and the `?` lists as `(a function)`: give
  it a name, with a `(** *)` comment, to have it shown.
- To take a key of Cemacs away, take it out of the keys: `c.Keys = () -> dict.Drop("C-x C-c", config.Keys())`.

Bindings to the mouse take the event as well as the state: `"wheel": (event, s) -> ...`, as in `MouseKeys`.

## A command of your own

A command takes the state and gives the next one. Nothing in it is special: the state is a value, a map of fields, so a
command reads the fields it needs and gives a state with some of them changed. The current buffer is
`state.Buffers[state.Current]`, and [core/text] has the functions that move in a buffer and edit it, each from a buffer to a
buffer.

A command of yours goes in `user/config/config.ce`, or in an app of yours, and a key of your `Changed` binds it. Here is
one that writes the line of the cursor again below it, as one step of undo, tried on the real editor with [press.Press], as
the tests of Cemacs try theirs:

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

An app is a package, a folder of Cesia files, that gives a function `Keys()`, the keys that work everywhere. Yours is a
folder of `user/`, as `user/mine/`:

```cesia norun
(* user/mine/mine.ce *)
(** My commands. *)
use core/commands

Keys() = {"C-c t": "tools", "C-c t d": DuplicateLine, "C-c t g": GoToLine, "C-c t o": Outline}   (** My keys. *)
```

In `user/config/config.ce`, `use user/mine` at the top loads it, as the package `mine`, and `Changed` merges its keys:

```text
use user/mine

defn Changed(config)
  c = config
  c.Keys = () -> dict.Merge(config.Keys(), mine.Keys())
  c
end
```

These lines can't run on this page, which has no package `user/mine`: [Recipes](recipes.md#your-first-app-in-usernotes)
runs a whole app, with a stand-in for its package. A new package needs a restart of Cemacs: a program that runs can't load
a package it didn't load at its start, and Cesia says so, `A running program can't load a new module. Restart it to use this
one.` After that, every change to the app reloads. The apps of Cemacs itself are folders of `src/`, which `src/cemacs.ce`
merges in `Keys`, in the same way.

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

value.IsFunction(WithMine(check.Hooked(emacs.Config(mine))).Idle) --> true
```

`Changed` then gives `WithMine(config)`: the config it gets has the hooks of the check already, which `before` keeps.
[Recipes](recipes.md#something-after-each-save) wraps `Saved` the same way.

Ask for ticks only while there is something to wait for: an editor whose `Moving` is false draws nothing until the next
event, and sleeps until it comes. A fiber of your own runs then only every 250 milliseconds, the longest the editor sleeps:
ask for ticks while it has work.

## Reloading Cemacs while it runs

`cesia do dev`, from the folder of Cemacs, runs it under `--watch`: at each save of one of its files, those of `user/` too,
Cesia loads the new code into the program that runs, without closing the window or losing the buffers. This is a hot
reload, as Cesia's book calls it. It runs `tools/dev.sh`, which makes `user/` first if it is missing, as `bin/cemacs` does.

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
3. **A new package needs a restart**, as above, one of `user/` too.

What the window reads once waits for the next start whatever the reload: `FontSize`, `Theme` and `Window`; and `Start` runs
at the start only.

A mistake that doesn't load, a name that doesn't exist or a syntax error, is shown in the terminal that runs `cesia do dev`,
and the old code stays. A mistake that loads but fails when it runs, such as a function bound to a key with the wrong number
of parameters, stops the program when the key is pressed, and the text not saved is lost: Cesia has no way to catch it. Save
your buffers before you try a change on the editor you write it in.

`tests/reload-check.sh` proves the rules in a window: it changes keys and settings of a running Cemacs, in
`src/emacs/emacs.ce` then in `user/config/config.ce`, as a person would save them, and checks each one at the next key.

## Testing a change

`cesia test` runs the tests of a folder, the examples of the `(** *)` comments of its packages and their test functions, as
Cesia's book tells in its chapter on tests: `cesia test core/commands` runs those of one package, and `cesia test user` those
of your folder, the test files of your apps, `user/mine/mine.test.ce` beside `user/mine/mine.ce`. `cesia do test` runs the
whole suite of Cemacs, both paths of Cesia included, on `core/` and `src/` only, so that an app of yours being written never
makes it fail: see [Install](install.md#checking-the-install). [press.Press] plays keys through the editor with no window,
as the examples above do.
