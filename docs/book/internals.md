# Inside Cemacs

This chapter tells how Cemacs is built: the state and its update, the rope that holds a buffer's text, the undo history, the
colours, the indent, the frame, the loop of events, and the start. It is for a reader who wants to change the core, or to know
what each operation costs. The code is 7,183 lines of Cesia in `core/` and `src/`, without their tests, and each file can be read
alone.

## The state, the update and the view

Cemacs is one value and two functions:

- the state, a map that holds everything: the buffers, which one is current, the panes, the question being asked, the
  message, the program that runs, the size of the window, the config;
- [commands.Update], which takes an event and the state and gives the next state, or `missing` when the editor ends;
- [view.View], which takes the state and gives the frame: an array of drawing commands, each a map such as
  `{Kind: "text", X, Y, Text, Color, Font}`.

The window's loop, [sdl.Run], reads the events, calls the update on each, and draws the view. Nothing else holds the editor's
state: no global variable, no object that changes. This is the shape that the Elm language made known as the Elm
architecture: a model, an update and a view.

The core in `core/` is pure where it can be: [core/text], [core/color], [core/keys], [core/view], [core/lists] and
[core/panes] take values and give values, and touch no file and no window. A pure function is one whose result depends only
on its arguments, and that changes nothing outside: it can be tested with plain values, as the examples of this book do.
[core/files], [core/run] and the clipboard touch the outside, in as few places as they can.

Every value of Cesia is immutable, it never changes once made: `s.Buffers[k] = b` gives the name `s` a new state, which
shares with the old one every part it didn't change. Sharing parts this way is called structural sharing, and a structure
that keeps its old versions whole is a persistent data structure. It is what makes the next sections cheap: a copy of a
state, or of a buffer's text, costs nothing, so the undo history keeps whole texts, and two panes keep two places of one
buffer.

### The fields

[view.Start] makes the first state; its fields are `Buffers`, `Current`, `Pending` (the prefix keys waiting), `Prompt` (the
question asked, or `missing`), `Message`, `Run` (the program, or `missing`), `Window`, `Width`, `Height`, `Cell` (the size of
a character of the code font), `Look` (the theme and the widths of the fonts), `Clip` (the clipboard when there is no window),
`Chorded`, `Chain` (true after `C-k`), `Dragging`, `Pressed`, `Wheel`, `Ending`, `Title`, `Config`, `Home` (the folder of
Cemacs), `Second`, `Panes`, `Pane`, `Waited`, `Hints` and `Chords`. Later code added `Still`, `Breaks` and `Checking`, read
through a `match` with a default, for the reason [Changing Cemacs](customising.md#reloading-cemacs-while-it-runs) tells.

A buffer, made by [text.Of], holds `Rope` (its text), `Cursor`, `Mark`, `Origin` (what set the mark: `"key"`, `"shift"`,
`"mouse"`, or `""`), `History`, `Version`, `Clock`, `Saved`, `Path`, `Disk` (the size and time of its file when read),
`Top` and `Left` (the first line and column on the screen), `Colors`, `Guess` (the states of the colours guessed for a screen
past those known, or `missing`), `Screen` (what the view keeps of the lines on the screen from one frame to the next),
`Wanted` (the goal column), `Typing`, `Free` (true after the wheel), `Marks` (the errors of the check) and `MarksNote` (words
for the mode line when there are none, such as why the text wasn't checked); a list has `List` too, and the check adds
`Checked`, the version it read.

A buffer is modified when its `Version` differs from `Saved`. Each edit takes a new number from `Clock`, which never goes back,
so two different texts never share a number, and undo brings back the number of the state it returns to: comparing two
numbers says whether the text is the one saved, where comparing two texts would cost a pass over both.

## The rope

A buffer's text is a rope, [src/rope]: a binary tree whose leaves hold pieces of the text and whose inner nodes join two
ropes, the text of the left one first. Each node keeps three numbers about the text under it: `Size`, its bytes; `Lines`, its
line ends; and `Height`, the longest path down to a leaf. Boehm, Atkinson and Plass described ropes in 1995, from their use in
the Cedar system at Xerox PARC, as an alternative to strings held in one block of memory, where joining two texts copies
both: see [References](references.md).

A leaf doesn't hold its bytes: it is a view of a text, `{Text, Start, Size, Lines}`, the `Size` bytes of `Text` from the
byte `Start`, and the line ends among them. The text is kept by reference: a file read from the disk is one text of Cesia,
and all the leaves made from it view parts of that one text, which is never copied nor changed; a text typed or pasted is a
text of its own. This is the idea of the piece table, which Crowley found the best of six structures for the text of an
editor in 1998: the file read is never copied, an edit only adds pieces; Visual Studio Code's piece tree, in 2018, put the
pieces in a balanced tree whose nodes count the bytes and the line ends under them, as Cemacs's rope does.

```cesia
use src/rope
r = rope.Of("one\ntwo\nthree")
[rope.Size(r), rope.LineCount(r), rope.LineStart(2, r), rope.Line(3, r)] --> [13, 3, 4, "three"]
```

Positions count bytes from 0, lines count from 1. Every operation goes down the tree by those numbers:

- [rope.SplitAt], the bytes before a position and the others, goes down by sizes, and joins what it passes on the way back;
  a leaf it cuts becomes two views of the same text, and only the line ends of the first are counted.
- [rope.JoinRopes] puts two ropes one after the other. Two views that touch in the same text, the second starting where the
  first ends, become one view if they hold at most 16 KiB together; two short leaves of other texts whose bytes fit in 1,024
  become one leaf, a copy of both.
- [rope.Insert] is a split, then two joins; [rope.Delete] two splits and a join.
- [rope.LineStart] finds the byte where line n starts by going down by counts of line ends, then in the view it reaches
  counts the line ends of its blocks of 2 KiB until the one that holds it, and searches that block alone.
- [rope.Slice], the text between two positions, and [rope.Text], the whole text, visit the leaves between them, in order,
  and join the parts they view: they make no node, so reading the lines on the screen only reads the tree. A slice inside
  one view, and the whole text of a rope whose views still cover one text from its first byte to its last, as after an open
  or after an undo back to it, are that text or a part of it, with no join: saving a file not changed, or checking it,
  copies nothing.

The tree is kept balanced as an AVL tree is, after Adelson-Velsky and Landis: at every node, the heights of the two sides
differ by at most one. A join of two ropes of very different heights goes down the side of the taller one, and puts each
node it rebuilds back in balance with one rotation or two, a rotation being the turn of three nodes that makes the taller
side shorter. A balanced tree of n leaves has a height of at most about 1.44 log₂ n, so a split, a join, an insert, a
delete and a search for a line visit O(log n) nodes: their cost grows with the logarithm of the size, and doubling the text
adds about one level. The paper on ropes names AVL trees as one way to make these operations logarithmic; its own ropes join
in constant time instead, and rebalance only when a tree grows deeper than a bound. Cemacs keeps the AVL balance at every
join, and, as the paper does, makes one leaf of two short leaves joined, and copies only the nodes along the path of an
edit. Inside a leaf the work is at most 16 KiB, in blocks of 2 KiB. The whole text of an edited buffer, `rope.Text`, costs
O(n), and the editor asks for it only to save or to check.

[rope.Of] makes a rope from a whole text, as a file just read: it cuts views of 16 KiB one after the other, the last one
shorter, without copying a byte, then puts them under nodes two by two, level by level, and joins an odd rope left over with
[rope.JoinRopes], which keeps the balance. Each view counts its line ends, its `Lines`, with Cesia's [text.Count], eight
bytes at a time, on slices of 2 KiB that are made and dropped young: OCaml's minor heap frees them at its next minor
collection, at no cost for each dead value. A file of
99.9 MB is 6,097 views and as many nodes. The size of a view weighs two costs: Cesia makes a record in a few hundred
nanoseconds, where C makes one in a few, so fewer records open a file faster, while a larger view makes finding a line inside
it longer. Measured on 99.9 MB, n = 7: [rope.Of] in 105 ms [104, 118] with views of
16 KiB, where leaves of 1,024 bytes, each a copy, took 258 ms [256, 352]; views of 4 and of 64 KiB, measured beside those of 16
KiB with an earlier Cesia, took 117 and 89 ms against 94; and finding a line in a view of 64 KiB counts up to 32 blocks of 2 KiB instead of 8. A random edit can leave a small leaf, down to a few bytes, which a later join may merge.

A rope is persistent: an edit makes new nodes along one path, O(log n) of them, and shares every other node with the rope
before it, which stays whole: this way of making a tree persistent is called path copying. A view keeps its whole text
alive, even when an edit deleted most of what it showed; the undo history keeps that text anyway, as it keeps the states
before the edit.

```cesia
before = rope.Of("abc")
after = rope.Insert(1, "X", before)
[rope.Text(before), rope.Text(after)] --> ["abc", "aXbc"]
```

### Why a rope

GNU Emacs keeps a buffer in a gap buffer: one block of memory with a hole at the place of the last edit, so that typing there
fills the hole and costs nothing, while an edit far away first moves the hole, and copies the bytes between. A rope costs a
few node visits for every edit wherever it is, and makes copies free. Cemacs needs copies: every state of the undo history is
a whole text, and every state of the editor holds every buffer, at each event. With a gap buffer each would copy the text;
with a rope each shares it.

The cursor is a line and a column, counted in characters; the rope counts bytes. [core/text] turns one into the other only
at an edit, inside one line: the start of the line from the rope, then the bytes of the characters before the column. A UTF-8
character takes one to four bytes, so this costs the length of the line, not of the text.

## The undo history

[src/history] keeps the past states, the present one and the future ones, those undone that redo can bring back:

```cesia
use src/history
h = history.Record(2, history.Record(1, history.Of(0)))
[history.Current(history.Undo(h)), history.Current(history.Redo(history.Undo(h)))] --> [1, 2]
```

Each state of a buffer's history holds the rope, the cursor, the version, the place of the cursor before the step, and the
first line that the step changed. Undo goes back one state, and puts back the text, the version and the cursor of before the
step; redo goes forward. Recording a new state forgets the future ones, so the history is a line, not a tree, and it keeps at
most 1,000 past states, forgetting the oldest. Since the ropes share their nodes, 1,000 states of a large file cost little more
than the text itself and the nodes the edits made.

A character typed after another one, in the same step of typing, replaces the last state instead of adding one: that is how
a word becomes one step of undo, as [Editing](editing.md#undo-and-redo) tells.

## The colours

[core/color] reads one line at a time, and gives its tokens, the pieces of the line each with its role: keyword, called name,
text, number, comment, field after a dot, or plain. Together the tokens hold every character of the line, in order: the frame
draws them one after the other. It is a lexer, the first step of reading code, which cuts it into words; it reads only
words, and knows no structure.

```cesia
use core/color
color.Tokens("defn f() (* a", color.FirstState).Tokens --> [[1, "defn"], [6, " "], [2, "f"], [6, "() "], [5, "(* a"]]
color.Tokens("defn f() (* a", color.FirstState).State --> {Comment: 1, Text: false}
```

A line doesn't stand alone: a comment `(* ... *)` can span lines and hold another one, and a text can run over several
lines. So the lexer takes the state at the start of a line, the depth of comments it is in and whether it is in a text, and
gives the state at its end. An editor has to colour code that is broken, since it is being written: this lexer never stops
on an error, and an unfinished text or comment only carries its state to the next line.

Each buffer keeps the state at the start of each line, known down to some line, [color.StartOf]. An edit at line n forgets
the states after n; drawing reads them again only down to the last line on the screen, and a line with no quote and no
comment mark is not even read, since it can't change the state. So typing at line 19,000 of a file reads only the lines on
the screen, and a jump to the end of a large file reads every line once, the first time.

The states are kept in chunks of 1,024 lines, a list of lists: forgetting the lines after an edit keeps the chunks before it
and cuts one, and reading more lines fills the last chunk and adds new ones. Each costs the number of chunks plus one chunk,
where one flat list of a state per line was cut and extended by copies of every state before the edit: at line 1,416,745 of a
file of 99.9 MB, 1,384 chunks instead of 1.4 million states, and a key there went from about 40 ms to about 1 ms. GNU Emacs
keeps the cache of its `syntax-ppss`, the state of its parser at places of the buffer, sparse for the same reason: its entries
at least `syntax-ppss-max-span`, 20,000 characters, apart.

That reading needs only the state, not the words, so it doesn't go through the lexer: [color.StateAfter] gives the state at
the end of a line by jumping from mark to mark, each found natively with [text.ByteFind]. In a comment it looks for the next
`(*` or `*)`, as comments nest; in a text, for the next quote, a doubled quote `""` and the character after a backslash
being part of the text; elsewhere, for the next quote or `(*`. The lines come 100,000 at a time, one slice of the rope cut at
its line ends. The state is the one the lexer gives, and a test checks it on 2,000 random lines from every kind of state:

```cesia
color.StateAfter("x = \"a (* b", color.FirstState) --> {Comment: 0, Text: true}
color.StateAfter("a *) \"b\"", {Comment: 1, Text: false}) --> {Comment: 0, Text: false}
```

### A far place first, its exact colours after

A jump far from the colours known, `M->` at the end of a file of 99.9 MB, or a search that finds its word there, would read
the states of millions of lines before it can draw: about 4 s. So [view.Follow] reads at most [view.ColorBatch] lines at
once, 25,000, about 35 ms here, well under the tenth of a second within which a person sees an answer as immediate. When the
screen is farther than that, it is drawn at once with its states guessed, `Guess`: from the last state known, as if no
comment or text opened in the lines between, then carried along the lines of the screen. While a pane shows guessed colours,
the editor asks for ticks, [view.Colouring], and each tick reads [view.ColorBatch] lines more, until the colours known reach
the screen, which is then drawn again with its exact colours. A comment that opens far above can make the screen's colours
wrong for those seconds; nothing else is guessed. This is what Emacs's jit-lock does by its own means: it colours on demand
the part of the buffer that the screen shows, and, with `jit-lock-contextually`, colours it again after a pause from the
true context of the lines above.

## The indent

[core/indent] gives the place of a line of Cesia code by the rule of `cesia fmt`, which [Editing](editing.md#indentation-in-a-file-of-cesia)
tells: its lexer is fmt's, the scan and the shapes of `src/tools/fmt.ce` of Cesia, read line by line. fmt reads a whole file
from its first line; an editor can't, at each key, in a file of a million lines. So a line is read from its anchor: the
nearest line above it at the left margin from which fmt's reading is sure to start out of any block and bracket. A line is an
anchor when:

- it is at the left margin, it starts in code, by the state of the colours at its start, and it starts with a name that
  doesn't close or go on with something, so not `end`, `else`, `then`, `and`, `or`, `not` or `in`, or with a comment;
- the lines at the margin right above it, up to the first of them, are such lines too, and each line above one of them ends its
  statement, opens no block and closes no bracket it didn't open: a line that leads on to the next;
- that run of lines starts after a blank line, at the start of the file, after an `end` at the margin, or after the end of a
  comment.

The test on the run is what makes the anchor sure: a line at the margin inside a block, as a text written there or a
statement left out of its place, is followed or preceded by a line that doesn't lead on. The anchor is looked for in the 64
lines above, then in 512, then in [indent.LookBack], 2,000; a file whose lines at the margin are farther apart than that is
read from the line 2,000 lines up, in as many blocks as its indent says. So a line costs the lines of the definition it is
in, never the whole file. The reading from the anchor gives the state at the start of the line, the blocks and brackets open
and the lines of the statement it may go on with, and from it [indent.Wanted] the place of a line being typed and
[indent.Plan] the changes of Tab.

Enter keeps its reading: [text.NewLine] stores, in the buffer's `Layout`, the state at the start of the new line, and the next
Enter, or the first word typed on that line, goes on from it when it is at most 256 lines above, instead of looking for the
anchor again. An edit forgets it from the line it changes, as it forgets the states of the colours after that line,
[indent.Forget]. The reading kept is the one from the anchor: on the 36,038 lines of the files of Cesia and Cemacs, Enter at the
end of each line, going on from the reading kept, gives the same state as a reading from the anchor. GNU Emacs keeps, the same
way, the states of its parser at places of the buffer in the cache of `syntax-ppss`, forgotten from the place of each edit,
so that the indent of a line doesn't read the buffer from its start.

A line costs, over every line of those files, measured once while other programs ran, a median of 0.2 ms, 4 ms at the 99th
percentile; the slowest are long
statements read line after line, as a list of long texts, about 15 ms, and one line of 220 KB, 78 ms.

## The frame

[view.View] makes the frame from the state: a clear of the window, then each pane, its code, its mode line and the line
between panes, then the output, the band of hints and the prompt line. It reads only the lines on the screen, cut to the
columns that fit, so a large file costs no more to draw than a small one. It only reads: [view.FollowState], which the update
calls last, is the one place that moves the screen of each pane to keep its cursor in sight, and that extends the known
colours down to the last line shown.

The frame is made again whole at each event, from the state: the program says what to draw, not what changed. This is the
way of an immediate-mode interface, as it is called, where no widget keeps a state of its own between frames. What costs to
make is kept below it, keyed by what it is made from, so that keeping it never changes what is drawn:

- [view.Follow] keeps, in the buffer's `Screen`, the tokens of each line on the screen under the text of the line, with the
  width it was cut to and the state of the colours at its start. The view reads the lines on the screen with one slice of the
  rope, and takes a line's tokens from `Screen` only if its text, its width and its state are the same; else it reads them
  itself. A typed key reads the tokens of one line again, a scrolled line those of the line that comes in. This is the idea of
  Elm's `Html.Lazy`, which skips making the view of a part whose arguments are the same as at the frame before; Elm compares
  them by reference, Cemacs by value, so that a state changed after the last follow is still drawn right. A test makes random
  edits at random places, follows after some of them only, and compares the frames drawn with and without the rows kept.
- [src/sdl] keeps the text objects of SDL3_ttf, each shaped once, by the font and the words it holds: shaping, the work of
  HarfBuzz, which SDL3_ttf calls, that turns the letters of a text into the glyphs of the font and their places, is done when a text first appears, and a line that moves on the
  screen is drawn from the object made before. Up to 8,192 objects are kept; past that, all are forgotten and made again as
  frames need them.

Frames wait for the screen's refresh, which SDL calls vsync, so Cemacs draws no frame that the screen can't show.

## The loop of events

[sdl.Run] is a loop of events, an event loop:

1. It takes every event waiting: a key, a text, the mouse, a change of size, the window closed. A TERM or INT signal asking
   the program to end comes as the window closed.
2. It calls the update on each, in order.
3. If the state asks for frames of its own, [commands.Moving], it gives the update a tick, an event `{Kind: "tick",
   Seconds}` with the time since the last pass, at most 0.05 seconds so that nothing jumps after a pause, then draws a
   frame, and lets the other fibers run.
4. Else, it draws a frame only if some event came, then sleeps in SDL until the next event comes, `SDL_WaitEventTimeout`,
   for at most 250 milliseconds, [sdl.RestMs]; then the other fibers run, and the loop starts again.

A still editor draws nothing, and wakes about four times a second. While it sleeps, the process is blocked in the system: it
waits on the connection to the display, a file descriptor, until the display server writes an event on it, as GNU Emacs,
Vim and Neovim wait in `select` or `poll` on their terminal. An event wakes it at once, so a key is read about 0.7 ms after
it was sent: see [Speed](performance.md#at-rest). The 250 ms bound is for the fibers of Cesia, which can't wake SDL: while
the editor sleeps in SDL, no fiber runs, and Cesia has no way to say when the next one is due. The fibers of Cemacs itself, a
check and the output of a program, run while the state asks for frames, so the bound only delays what nothing waits for:
a reload under `--watch` that nobody looks at yet, a fiber of an app that doesn't ask for frames. SDL's dummy driver, which
the tests use, can't wait for an event: there, SDL looks for one every millisecond itself. The state asks for frames while a prefix key waits for the band of hints to open, which needs
the time counted; while a check runs or a buffer is due for one; while a program runs, whose output comes at each pass; and
while a pane shows colours guessed, which each tick reads more of.

The check and the program's output wait in fibers. A fiber is a task of Cesia that runs beside the others in the same
program, and takes turns with them: a fiber waits for `cesia check` to end, another reads what the program writes, and each
sends what it got on a channel, a queue between fibers. At each tick, the editor takes what the channels hold without
waiting, so typing never waits for them. Cesia's book tells fibers and channels in its chapter on fibers.

### From a key to a command

A key goes through these steps, in [commands.Update]:

1. [keys.Chord] makes its chord, or nothing for a key that only types: its text event comes next and types it.
2. With a question open, the chord goes to [emacs.PromptKeys]; in a list, to its keys; else, to the global keymap.
3. [keys.Lookup] finds it, with the prefix keys waiting: a command, a prefix that waits for more, or nothing.
4. The command runs on the state. If it wasn't [commands.CutLine], the chain of cuts ends; in a list, a command that changed
   the text is taken back.
5. [commands.Settled] makes the list of the current buffer again from its rows, puts the pane you edit on the current buffer,
   moves the screens to their cursors, and sets the title of the window.

## Saving

[core/files] writes a new file beside the old one, then renames it over the old one. POSIX, the standard of system calls that
Linux and macOS follow, says of `rename` that when the new name exists already, it keeps leading to the old file or to the
new one at every instant of the operation, never to neither: so no reader ever sees a part of either file.
[Files and buffers](files.md#never-losing-the-text) tells what this guarantees and what it doesn't.

## The start

`src/cemacs.ce` calls [editor.Start] with the config. It:

1. takes the folder of Cemacs from its first argument, or `.` with none;
2. opens the window, 1280 by 720, with the font of the body at the size of [emacs.FontSize], then adds the other two fonts,
   `strong` and `code`;
3. measures the code font: a character is as wide as `M`, and a line as high as `Ag` plus [view.LineGap], one pixel;
4. makes the first state, with one empty buffer, then opens the files given after the folder, in order: an empty buffer that
   nothing touched gives its place to the first one;
5. runs the loop until the update gives `missing`, then closes the window and gives `Ok(missing)`, which `src/cemacs.ce`
   prints.

[Speed](performance.md) has the time all of this takes.
