# Keys

This chapter lists every key of Cemacs, and tells how a key you press becomes a command. The tables below are not written by
hand: the page reads the keymaps from the code of Cemacs each time the site is built, so they can't be out of date.

## Words

- A key binding links a key to what it runs. In Cemacs, it is an entry of a dictionary whose key is a text, such as
  `"C-x C-s"`, and whose value is the function itself, such as [commands.Save].
- A keymap is a set of key bindings. Cemacs has a few, listed below: the global one, those of a question, of a list, and of
  the mouse.
- A command is what a key runs: any function from the state of the editor to a new state. Emacs asks a command to be marked
  as interactive; Cemacs asks nothing, so any function of that shape can be bound, even one written in place.
- A chord is one key with the modifiers held with it, written as `C-x`, `M-<` or `S-right`. A key sequence is one or more
  chords, written with a space between them: `C-x C-s`, `C-c f f`.
- A prefix key is a key sequence that some longer binding starts with, such as `C-x` or `C-c f`: it runs nothing alone, and
  waits for the next key. A group is a prefix key whose binding is a text, its name: `"C-c f": "files"`.

## The global keymap

These keys work in every buffer of text. They come from `src/emacs/emacs.ce` and from the apps that `src/cemacs.ce` merges
with them, with `?` after every prefix key: the code below makes the same merge, and the table from it. Your own keys, which
the `Changed` of `user/config/config.ce` merges over these, are not in it: the table comes from the code of Cemacs, and
`user/` is yours.

```cesia output=md fold=code
use src/buffers
use src/check
use src/emacs
use src/folders
use src/help
use src/ide
use src/notebook
use src/output
use src/project
use std/cesia
use std/dict
use std/io
use std/list
use std/text as str
use std/value

(* The keys as src/cemacs.ce merges them: that file opens the window when it loads, so the page makes the same merge. *)
all = help.WithHelp(dict.Merge(dict.Merge(dict.Merge(dict.Merge(dict.Merge(dict.Merge(dict.Merge(emacs.Keys(), buffers.Keys()), folders.Keys()),
  project.Keys()), check.Keys()), output.Keys()), notebook.Keys()), ide.Keys()))

defn about(f)
  (** The name of a command as the reference writes it, as a link, and the first sentence of its text. *)
  doc = cesia.Doc(f)
  name = str.Split("(", str.Split("\n", doc)[1])[1]
  body = str.Replace("\n", " ", str.Split("\n\n", doc)[2])
  first = str.Split(". ", body)[1]
  "[$name] | $(if str.EndsWith(".", first) first else "$first." end)"
end

defn row(k, bindings)
  (** The row of the table for the key k. *)
  v = bindings[k]
  if value.IsText(v) "| `$k` | the group $v | waits for one of the keys below it |" else "| `$k` | $(about(v)) |" end
end

(* The rows in order: the keys of one chord first, then each prefix key with what follows it. *)
chords(k) = value.Len(str.Split(" ", k))
first(k) = str.Split(" ", k)[1]
defn table(bindings)
  sorted = list.Sort(dict.Keys(bindings))
  ones = [k for k in sorted if chords(k) == 1 and not value.IsText(bindings[k])]
  more = [k for k in sorted if chords(k) > 1 or value.IsText(bindings[k])]
  io.Print("| Key | Command | What it does |")
  io.Print("|---|---|---|")
  for k in list.Concat(ones, more)
    io.Print(row(k, bindings))
  end
end

table(all)
```

That is this many keys, the groups included:

```cesia
value.Len(dict.Keys(all)) -->
```

A command bound to two keys, as `C-x C-f` and `C-c f f`, is the same function: the second key is no copy of the first.
Under `C-c`, the letter of each group is the first letter of its name, as in Doom Emacs: `f` files, `b` buffers, `w`
windows, `c` code, `d` debug, `e` execute, the [cells](cells.md), `t` test, the [tests](running.md#tests), `g` [git](git.md), `q` quit.

## A question on the prompt line

While a question is open, as `Find file: `, these keys work, letters go into the answer, and every other key does nothing.
A question has no key sequences.

```cesia output=md fold=code
table(emacs.PromptKeys())
```

## A list

In a list, these keys come over the global ones, and the list's own keys come over them: Enter in every list, and the keys of
the folder manager, `C-c n`, `C-c r`, `C-c k`, `C-c .`, `C-y` and Backspace, which [Files and buffers](files.md#the-folder-manager)
tells.

```cesia output=md fold=code
table(emacs.ListKeys())
```

When two keymaps bind one key, the one that comes first here wins: in a list, the keys of the list, then those that need no
row, then [emacs.ListKeys], then the global keys. In a list, the band of hints shows the keys of the list too, those of the
folder manager as `a function`, since they are written in place in its code; the `?` lists show the global keys only.

## The list of completions

While the list of completions that Tab opens in a file of Cesia is under the cursor, these keys come over the global ones;
a letter typed makes the list again for the longer word, and any other key closes the list and does what it does.
[Editing](editing.md#completion) tells how.

```cesia output=md fold=code
table(emacs.CompleteKeys())
```

## The mouse

The mouse has its keymaps too, by the action of its event: `down`, `move`, `up` and `wheel`. Their commands take the event
as well as the state. While a question is open, only `up` and `wheel` work.

```cesia output=md fold=code
table(emacs.MouseKeys())
```

## How a key becomes a chord

The window gives Cemacs two kinds of events for the keyboard: a key event for each key pressed, with the name of the key and
the modifiers held, and a text event for the text that a key types. [keys.Chord] turns a key event into a chord, or into
nothing when the key only types:

- The modifiers come first, always in the order `C-` (Control), `M-` (Alt), `S-` (Shift): `C-M-S-x`.
- A key with a name is written by that name: `enter`, `tab`, `backspace`, `delete`, `escape`, `space`, `home`, `end`,
  `pageup`, `pagedown`, `left`, `right`, `up`, `down`, and `f1` to `f12`. Any other key is its character, in lower case.
- A key that types, a character or the space bar with no Control and no Alt, with Shift or not, is no chord: its text event
  types it, so that `A`, `é` and the characters of an input method arrive as they should.
- Shift isn't written for `<`, `>`, `?` and `_`, which already hold it: a key that reports `<` with Alt is `M-<`. A keyboard
  where the key reports `,` and Shift instead gives `M-S-,`, and Cemacs binds both to the same command.
- A key with Super, the key with the logo of the system, is left to the system: no chord.

```cesia
use core/keys
keys.Chord({Key: "s", Ctrl: true, Alt: false, Shift: false, Super: false}) --> "C-s"
keys.Chord({Key: "right", Ctrl: false, Alt: false, Shift: true, Super: false}) --> "S-right"
keys.Chord({Key: "a", Ctrl: false, Alt: false, Shift: true, Super: false}) --> missing
```

Some systems also send a text event after a chord with Control or Alt, the same letter again; Cemacs ignores that text, so
`C-a` never types an `a`.

`escape` is a key with a name, and nothing is bound to it. In Emacs, Escape followed by a key is the same as Meta with it;
in Cemacs it is not: use Alt.

## How a key sequence is read

[keys.Lookup] reads each chord after the prefix keys waiting before it, and gives one of three answers:

```cesia
use std/text as str
keys.Lookup("C-x", "C-s", {"C-x C-s": str.Lower}) --> {Command: str.Lower}
keys.Lookup("C-c", "f", {"C-c f": "files", "C-c f f": str.Lower}) --> {Pending: "C-c f"}
keys.Lookup("", "C-t", {"C-x C-s": str.Lower}) --> {Unknown: "C-t"}
```

- `Command`: the keys typed so far are bound to a function, which runs.
- `Pending`: some binding goes on after them, so they wait for the next key. The prompt line shows them with a dash, as
  `C-c f -`, and the band of hints opens after [emacs.HintDelay] seconds.
- `Unknown`: nothing is bound to them, and nothing starts with them. The prompt line says `C-x C-t is not bound.`, and
  nothing changes.

A key sequence bound to a command runs as soon as it is typed, so a longer one that starts with it can't be reached: bind
`C-c t` to a command and `C-c t s` is lost.

`C-g` after a prefix key forgets it, keeps the selection, and says `Quit`, whether or not a binding takes it, as `C-x C-g`
and `C-c C-g` do: [commands.CancelPair].

### The keys after a prefix

After a prefix key, a key that types, with no Control, Alt or Super, isn't read from its key event: Cemacs waits for the text
it types, and takes that text, in lower case, as the chord; the space bar is `space`. So on a US keyboard, Shift and `/`
after `C-x` is `C-x ?`, which the key event alone would call `C-x /`. The lower case means that Shift and `b` after `C-x` is
`C-x b`, as `b` alone is.

## Changing a key

The bindings are code, so changing a key is a line of your `Changed`, in `user/config/config.ce`, which `C-c f c` opens, and
any function from a state to a state can be bound. [Changing Cemacs](customising.md#keys-of-your-own) shows how, with your
own keys and groups, and [Recipes](recipes.md#a-key-group-of-your-own) makes a group of four commands.
