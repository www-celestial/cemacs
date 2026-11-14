# Names: definitions, references and renames

A name of Cesia code, as `shop.Total`, `Rate` or `list.Map`, leads somewhere: to its *definition*, the line that gives it
its value, and from there to its *references*, every place that reads it. Cemacs goes to both, shows the documentation of a
name, tells the *signature* of the call you are typing, its name and its parameters, and renames a name in every file that
reads it. These keys are those of [src/ide], which asks `cesia lsp` where a name is defined and what its documentation
says, and asks [src/lookup], through `tools/lookup.ce`, the places that read it: [How the IDE asks](#how-the-ide-asks) tells how.

```cesia norun
(** A shop. *)
use std/list

Rate = 20   (** The tax, in percent. *)

defn Total(prices)
  (** The total of prices, with the tax. *)
  sum = list.Reduce((a, b) -> a + b, 0, prices)
  sum + sum * Rate / 100
end
```

With the cursor on `shop.Total` in another file that uses this package, `M-.` opens the file above on `defn Total`, and
`M-,` comes back. `M-?` lists the three places that read `Total`, and `C-c c m` renames it in all of them.

## Keys

`M-.`, `M-,` and `M-?` are the keys of Emacs for the same work, which it calls *cross references*, xref; the group of the
code of `C-c` has them too, with the documentation and the rename:

| Keys | Command | What it does |
|---|---|---|
| `M-.`, `C-c c d` | [ide.Definition] | goes to the definition of the name at the cursor; a name of Cesia's own `std/` shows its documentation |
| `M-,`, `C-c c b` | [ide.Back] | goes back to the place the last `M-.`, or a place opened from a list of places, left |
| `M-?`, `C-c c f` | [ide.References] | lists every place of the project that reads the name at the cursor |
| `C-c c i` | [ide.Documentation] | shows the signature, the text and the examples of the name at the cursor |
| `C-c c m` | [ide.Rename] | renames the name at the cursor everywhere the project reads it (m as in move, the word of `cesia pkg move`) |

On a keyboard where `?` is Shift and `/`, `M-?` arrives as `M-S-/`, which is bound to the same command. The places to go
back to are kept as a stack, the last 100 of them: `M-,` again goes further back.

## Which definition

Where a name is defined is told by Cesia's own language server, `cesia lsp`, the one every editor that speaks the Language
Server Protocol asks, so that Cemacs and the others find the same place, by the same rules. At the first `M-.`, `M-?`,
`C-c c i`, `C-c c m` or signature of the session, Cemacs starts `tools/names.ce`, which starts `cesia lsp` and speaks its
protocol, so that none of that code loads with the editor; both stay until Cemacs ends, and a question is then a message to
processes that run already, about a millisecond. The name under the cursor is read with its dots: on `Map` of `list.Map(f)`,
the name is `list.Map`; on `list`, it is the package. Then:

- a name of the file's own package, as `Rate` or `extra`, is looked for in the files of its folder, the file itself first;
  a file that is in no source folder of its project is a program, and only its own names count;
- a name after the name of a package that the file uses, as `shop.Total` with `use src/shop`, is looked for in that
  package;
- a name of `std/`, as `list.Map`, has no file in a project, unless the project holds a copy of that package in `std/`: its
  documentation shows, as `cesia doc list.Map` gives it;
- a name after the dot of a value, as `Area` in `r.Area()`, is a method: the one of that name in the file's package, or in
  the packages of the project that it uses.

With a question, Cemacs gives the text of the current buffer and of each Cesia buffer not saved, when it changed since the
last question, so that a definition you just typed is found. The first time it gives a buffer, it gives the text on the disk first, so that a text
that doesn't read yet, as a call half typed, stands for its file with the definitions the server read in the saved one.
Two things are the server's today: a name through the name of a package, as `shop.Total`, is found where the package's
file on the disk has it, not in a buffer of that file not saved, and its documentation is its signature without its text.

## The documentation and the signature

`C-c c i` opens a list with the signature of the name, its text and its examples; Enter on it goes to its definition, and
`C-g` closes it. The signature alone shows on the prompt line once the cursor stays still in a call, half a second after
the last key, as Emacs's *eldoc* does: after `shop.Total(` the line says `Total(prices): The total of prices, with the
tax.`, the signature and the first sentence of its text. Nothing shows when a mark of the check is on the line, or a message
or a question is on the prompt line: they come first. It is asked once for a place of the cursor, when the time of the check
comes, so that it costs nothing while the editor is still.

## The references

`M-?` lists each place as `path:line:column` and the words of its line, the definition first, the paths from the root of the
project, the folder that holds its `cesia.toml`. Typing filters the list, Enter goes to the place and keeps the place left,
for `M-,`. The places are those that read the name, as the compiler of Cesia reads it, through `cesia.Reads`, its resolver
of names:

- a parameter or a local of the same name is no reference, nor is a word in a comment or a text; a name read inside a text,
  as `"$(Total(xs))"`, is one;
- a name of a package is found in the files of the package and their tests, written alone, and, for a public one, in every
  file of the project that uses the package, after the name the file gives it: `shop.Total`, or `s.Total` after
  `use src/shop as s`;
- a name of `std/`, as `list.Map`, is found in every file of the project that uses its package;
- a method or a field is read after the dot of any value, which no reading of the code can tie to one struct: it is found by
  name, every `.Area` of the project, and the prompt line says so.

`cesia.Reads` gives the first place where a source reads each name it doesn't define. Cemacs asks it of each top-level
definition that holds the name, one at a time; when the name is read there, that place is a reference, the name there is
replaced by a placeholder of the same length, a name the source holds nowhere, and the definition is read again, until no
read of the name is left. So each place found is one the compiler resolves to the definition, and the columns of the
others don't move. A file that doesn't read is left out, and the prompt line counts the files left out.

## A rename

`C-c c m` asks `Rename Total to: `; after the new name and Enter, it finds the references as `M-?` does, and asks
`Rename Total to Sum in 3 places of 3 files? (y or n)`. After `y`, each file is opened if it isn't, gets its edits as one
step of undo, and is saved again if it was saved before, so that the disk holds the project as it now reads and the check
reads it; a buffer with changes of its own gets the edits and stays unsaved. The prompt line tells how many files were saved.

A rename is refused, with the reason on the prompt line, when the new name:

- isn't a name: a letter, then letters and digits; or is a word of Cesia, as `end`;
- would make a public name private, or the other way: in Cesia, a capital first letter says that a name is public, and
  a rename keeps what the name is;
- is defined already in the package;
- would be read as something else in one of the places, as a local of that name around a call: each top-level definition
  that an edit touches is read again with the new name, and every edit there must be read as the renamed name.

A method or a field can't be renamed, since its calls can't be told from those of the other methods of the name; nor can a
name of `std/`, nor one in a file that doesn't read, which would leave its places as they were. A file whose text changed
between the question and the yes, where an edit no longer finds the old name, is left as it is, and the prompt line says so.

## How the IDE asks

The keys of this chapter, those of [the search of a project](search.md#searching-a-project), of [Git](git.md) and of
[the tests](running.md#tests) are all those of one app, [src/ide], which does none of their work itself: each key asks a
program of Cemacs, run by `cesia run` at that moment, and does what its answer says. The question goes in JSON on the
program's input: what to do, the file of the current buffer, its text and the place of the cursor, the folder Cemacs started
in, and the texts of the Cesia buffers not saved. The answer comes back as one line of JSON on its output, in a few words
that src/ide knows:

| Word | What src/ide does |
|---|---|
| `Say` | says the words on the prompt line |
| `Open` | goes to a place, `{Path, Line, Column}`, keeping the place left for `M-,` |
| `List` | opens a list of rows, each with its words, its colours and the item it stands for; a key of the list, as Enter, goes to the place of the item or asks the program again with it; in the state of Git, a letter asks it |
| `Ask` | asks a question on the prompt line, then asks the program again with the answer |
| `Confirm` | asks for a yes, then makes the edits that come with it in buffers, as a rename does: no answer edits a buffer without that yes |
| `Run` | runs `cesia test`, and sends its output to the program once it ends |
| `Marks` | puts the marks of failures in the lines of their files |
| `Insert` | writes a form of Cesia under the cursor, from the program of the forms only: [Editing](editing.md#forms-of-cesia) |

| Program | Its work | Its permissions |
|---|---|---|
| `tools/names.ce` | [src/names]: for the session, it asks `cesia lsp` where a name is defined and what its documentation says | `read`, `exec=cesia`, to start `cesia lsp` |
| `tools/lookup.ce` | [src/lookup]: the places that read a name, and the edits of a rename, from where `cesia lsp` says it is defined | `read` |
| `tools/grep.ce` | [src/grep]: the search of a project | `read`, `exec=git` |
| `tools/git.ce` | [src/git]: Git | `read`, `exec=git` |
| `tools/testing.ce` | [src/testing]: what a key tests, the failures | `read` |
| `tools/snippets.ce` | [src/snippets]: the forms of `C-c i` | none |
| `tools/shell.ce` | [the shell](shell.md): it starts your shell and passes it the commands of its buffer, for as long as the buffer is open | `exec=` your shell, alone |

The question waits in a fiber, as the check does, and each tick of the editor takes the answer once it has come, so that
typing never waits; a new question takes the place of one not answered yet. `tools/names.ce` and `tools/shell.ce` run for
the session instead: a question to the names goes as its length on a line and its JSON, their answers come as lines of JSON,
in order, read from a fiber. `tools/names.ce` speaks to `cesia lsp` as the protocol says: JSON after a `Content-Length`
header, columns in UTF-16 code units.
So none of this work loads when Cemacs starts:
every line of Cesia that loads at the start costs about 5 µs, more as the code grows, and the four programs and their
packages hold about 2,000 lines, which would add over 8 ms to each start. A question costs a process instead, about 15 ms to
start and load, then its work.

## Security

- The lookup runs no code: it reads files, and asks `cesia.Definitions` and `cesia.Reads`, which parse and resolve without
  running anything. Its only permission is `read`: it can't write, connect, or start a program. `tools/names.ce` has `read`
  and `exec=cesia`, the one program it starts being `cesia lsp`, which reads files and never writes one, as Cesia's book tells.
- Each program runs with the permissions of the table above, which src/ide gives it; an answer can't ask for others, nor
  name a program that isn't in the table: a request of an answer that does is refused.
- An answer is read as input from another program: every place is checked, a path from the root, a line from 1, a column
  from 0 and an end after it, every list, row and edit is checked for its shape, 20,000 at most, before a file is opened or a
  buffer changed; a wrong answer is a message. Only the program of the tests may ask for a run, and only of `cesia test`.
- A rename edits buffers, never files behind them: each edit is checked against the text of its buffer, a buffer with
  changes of its own is never saved by it, and a file that changed on disk asks before it is written, as `C-x C-s` does.
- The lookup reads no file over 1 MB, at most 20,000 files of a project, and the files of the folders that a project keeps
  for other things: those whose name starts with a dot, `std/`, `deps/`, `site/` and `_build/`. A file that is in no project
  is looked at alone, with the other files of its folder, never the folders above it.
- A question that takes over 10 seconds is ended.

## Speed

A definition, a documentation or a signature is a message to `cesia lsp`, under a millisecond once it runs, about 20 ms for
its start at the first question; the references and a rename add a process, which Cesia starts, loads src/lookup into
and runs, more for a name read in many files, all of it in the background; [Speed](performance.md#the-questions-of-srcide) gives the measures.
Typing costs nothing more: no key that types asks anything, and the signature is asked at most once for a place of the
cursor, half a second after the last key.
