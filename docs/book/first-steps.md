# First steps

In this chapter you open a file, learn the few keys that get you going, and write Cesia: the errors show in the lines, a key
runs the file with the permissions of its project, and another runs it under the debugger. Last, you change Cemacs itself.
Each part leads to the chapter that tells all of it.

You need Cemacs installed, as [Install](install.md) says: Cesia, SDL3 and SDL3_ttf, and the code.

## Opening a file

```bash
bin/cemacs notes.ce
```

The window opens on `notes.ce`. A file that doesn't exist yet opens empty, and is made at the first save. With no file,
Cemacs opens one empty buffer.

A buffer is a text that Cemacs holds in memory, most often the text of a file: you edit the buffer, and saving writes it to
the file. Until then the file on disk doesn't change. Several buffers can be open at once, one for each file.

The window has four parts, from the top:

```text
+--------------------------------------------------------------+
|  1  use std/io                                               |
|  2  io.Print("Hello")                       the code         |
|                                                              |
| notes.ce *                           2:17   Cesia            |  the mode line
+--------------------------------------------------------------+
| Output   ended, code 0                                       |  the output, after a run
| Hello                                                        |
+--------------------------------------------------------------+
| Saved notes.ce                                               |  the prompt line
+--------------------------------------------------------------+
```

- The code, with the number of each line on its left, and the cursor, a thin bar: typing inserts text there.
- The mode line, under the code: the name of the buffer, a star `*` when its text isn't saved, the line and the column of
  the cursor, and the count of errors when there are some.
- The output of the last program you ran, once you run one.
- The prompt line, at the bottom: it tells what the last key did, and it is where a question is asked, such as the name of a
  file to open. Emacs calls this line the echo area when it shows a message, and the minibuffer when it reads an answer.

The [Windows and panes](windows.md) chapter tells each part in full.

## The keys

The keys are those of Emacs. `C-` means the Control key and `M-` the Alt key: `C-x C-s` is Control and `x`, then Control and
`s`. Such a key of two or more keys is a key sequence, and its first key, `C-x` here, is a prefix key: it does nothing alone,
and waits for the key after it.

A few keys to start with:

| Keys | What they do |
|---|---|
| `C-f`, `C-b`, `C-n`, `C-p`, or the arrows | a character forward or back, a line down or up |
| `M-f`, `M-b` | a word forward or back |
| `C-a`, `C-e`, or Home and End | the start and the end of the line |
| `C-v`, `M-v`, or Page Down and Page Up | a screen down or up |
| `M-<`, `M->` | the start and the end of the file |
| `C-space`, then a move, or Shift and a move | select from there |
| `C-w`, `M-w`, `C-y` | cut, copy, paste |
| `C-k` | cut the rest of the line |
| `C-/`, `C-?` | undo, redo |
| `C-g` | stop what the keys started: a selection, a question, a prefix key |
| `C-x C-f`, `C-x C-s` | open a file, save |
| `C-x C-c` | quit |

The cut text goes to the clipboard of your system, so you can paste it in another program, and paste theirs here.
[Editing](editing.md) tells every key that moves and edits.

## The groups under C-c

You don't need to learn the keys above. Under `C-c`, every key is in a group, as in Doom Emacs. Press `C-c` and wait half
a second: a band above the prompt line shows each group. Press a group's letter and wait again: the band shows its keys.

| Group | Its keys |
|---|---|
| `C-c f`, files | `f` open, `s` save, `d` the folder, `c` the code of Cemacs |
| `C-c b`, buffers | `b` the list, `n` the next one, `k` close |
| `C-c w`, windows | `s` split below, `v` split to the right, `o` the next pane, `d` close it, `m` keep only this one |
| `C-c s`, search | `s` search forward as you type, `r` backward: see [Search](search.md) |
| `C-c c`, code | `r` run the file, `k` stop it, `o` its output, `h` hide or show the output, `n` and `p` the next and the previous error |
| `C-c d`, debug | `r` run under the debugger, `b` a breakpoint, `e` evaluate, `c` continue, `n` next, `s` step, `u` out |
| `C-c q`, quit | `q` quit |

So `C-c f f` opens a file, as `C-x C-f` does. `?` after a prefix key lists everything that can follow it, each with the name
of its command and what it does: `C-x ?`, `C-c ?` or `C-c d ?`. Typing filters that list, and Enter runs the key under the
cursor. You can always find a key from its group, without knowing it: `C-c`, then look. [Keys](keys.md) lists every key.

## Files, buffers and panes

| Keys | What they do |
|---|---|
| `C-x b`, `C-x C-b` | the next buffer, the list of buffers |
| `C-x k` | close the buffer |
| `C-x d` | the folder of the current file, as a file manager |
| `C-x 2`, `C-x 3` | split the pane below, or to the right |
| `C-x o`, `C-x 0`, `C-x 1` | the next pane, close this one, keep only this one |

A pane is a part of the window that shows a buffer, with its own mode line; Emacs calls it a window, and the whole window a
frame. Two panes can show the same buffer at two places.

The list of buffers and the folder are lists: buffers of rows. Typing filters a list, and Enter opens the row under the
cursor. In the folder, type part of a folder's name and then `/` to go into it, and Backspace goes up; `C-c n` makes a file
or a folder, `C-c r` renames, and `C-c k` moves to the trash. [Files and buffers](files.md) tells all of it.

## Writing Cesia

Cemacs colours Cesia's code as you type: keywords, names that are called, texts, numbers and comments each have their
colour.

### Errors in the lines

Cemacs checks a Cesia file while you write it, as `cesia check` does, without running it. Half a second after your last key
it reads the buffer, even before it is saved. An error is underlined in red, a warning in amber, the number of its line
takes the same colour, and the words of its message show at the end of the line. The prompt line tells the error under the
cursor, with its hint, the words that say how to fix it. The mode line counts them.

| Keys | What they do |
|---|---|
| `M-g n`, or `C-c c n` | the next error, from the cursor; after the last one, the first |
| `M-g p`, or `C-c c p` | the previous error |

A warning is about a result whose `Err` would go unseen, such as a `sys.Read` used as a plain value: Cesia's book explains
each kind, in its chapter on errors. [Errors in the lines](check.md) tells when the check runs and what it shows.

### Names, the project and Git

| Keys | What they do |
|---|---|
| `M-.`, then `M-,` | goes to the definition of the name at the cursor, then back |
| `M-?` | lists every place of the project that reads the name |
| `C-c c m` | renames it in all of them |
| `C-x p g` | lists every line of the project that holds some words |
| `C-c t t` | runs the test the cursor is in, or the tests of the file's folder; failures are marked in their lines |
| `C-x g` | the state of Git, where `s` stages a file and `c` commits |

The prompt line shows the signature of the call you type, `Total(prices): The total of prices, with the tax.`
[Names](names.md), [Search](search.md#searching-a-project), [Running and debugging](running.md#tests) and [Git](git.md) tell
them in full.

### Running a file

`C-c c r` runs the file of the current buffer, as saved, as `cesia run` would, and as fast. What it prints shows in the
output below the panes, as it comes, its errors too; its first line is the command that runs it. `C-c c k` stops a program
that keeps running, such as a server, and `C-c c r` again stops it and runs the file anew. `C-c c h` hides or shows the
output.

`C-c c o` opens the whole output as a list, on its last error. Typing filters it, and Enter on a line that names a place
goes there: an error of Cesia starts with its file, line and column, as `src/main.ce:4:11:`, and each call under it ends
with its file and line.

### Permissions

A program runs with no permission, as `cesia run file.ce` does: it computes and prints. A program that reads a file stops,
and the output says which permission it lacks. Permissions are written once, in a task of `cesia.toml`, as Cesia's book
shows in its chapter on permissions:

```toml
[tasks.serve]
file = "src/server.ce"
allow = ["read=data", "net=:8080"]
```

When the `cesia.toml` of the folder where you started Cemacs has a task whose `file` is the current file, `C-c c r` runs
that task, as `cesia do serve` does: with its permissions, and the tasks it `needs` first. The first line of the output shows
the command, with its `--allow`. Add `watch = true` to the task, and `C-c c r` runs it under `--watch`: each save loads your
changes into the program that runs, without stopping it.

### Debugging

`C-c d r` runs the file under the debugger, a program that runs yours and can stop it, to show its variables. It runs nearly
as fast as without it until it reaches a breakpoint, a line where you ask it to stop. It runs with no permission, even when
a task runs the file.

- `C-c d b` puts a breakpoint on the line of the cursor, a dot in the margin, or takes it away.
- When the program stops, at a breakpoint or on an error, its line takes a band of colour, and the output shows the variables
  of the function where it stopped, with their values.
- `C-c d e` evaluates the line of the cursor, or the selection, in the program, and shows its value at the end of the line,
  in grey: it is not part of the file.
- `C-c d c` continues to the next stop. `C-c d n` runs one line, a call as a whole; `C-c d s` runs one line and goes into a
  call; `C-c d u` runs on to the end of the function.

While the program is stopped, you can change its code and save it: when it goes on, the code that changed is loaded.
[Running and debugging](running.md) tells all of it.

## Changing Cemacs

Cemacs is a Cesia project, and its settings are Cesia code. Your changes go in a folder of your own, `user/`, which Cemacs
made at its first start and which `git pull` never touches. `C-c f c` opens `user/config/config.ce`, whose function
`Changed` gets the config of Cemacs, the record of its keys and its settings, and gives it back changed. The keys of Emacs
and the settings of Cemacs are in `src/emacs/emacs.ce`, each a function. Here are two of them, as this page was built:

```cesia
use src/emacs
emacs.FontSize() -->
emacs.HintDelay() -->
```

To change them, set them in `Changed`, each as a function, and save:

```cesia
defn Changed(config)
  (** Cemacs with larger text and the band of hints sooner. *)
  c = config
  c.FontSize = () -> 17
  c.HintDelay = () -> 0.3
  c
end

Changed(emacs.Config(emacs.Keys)).HintDelay() --> 0.3
```

A key runs any function from the state of the editor to a new state. Here is a group `t` of your own, with one key in it,
in a new package `user/mine/`:

```cesia
(* user/mine/mine.ce *)
use core/commands
Keys() = {"C-c t": "tools", "C-c t s": commands.Save}
```

In `user/config/config.ce`, add `use user/mine` at the top, and in `Changed`,
`c.Keys = () -> dict.Merge(config.Keys(), mine.Keys())` before its last line, with `use std/dict`. Start Cemacs with
`cesia do dev` from its folder: each save of one of its files, or of yours, then reloads it in the window, without closing
it, so a changed key or setting works at the next key; the size of the text waits for the next start, since the window
reads it once. A new package, as `user/mine/` here, needs one restart first, since a program that runs can't load a new
package. [Changing Cemacs](customising.md) tells all of it, with an app of your own, and [Recipes](recipes.md) has small
tasks done this way.

`cesia do test` runs the suite of Cemacs, and `SDL_VIDEODRIVER=dummy cesia do test` runs it without showing a window.
