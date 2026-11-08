# Inside Cemacs

This chapter tells how Cemacs is built: the state and its update, the rope that holds a buffer's text, the undo history, the
colours, the frame, the loop of events, and the start. It is for a reader who wants to change the core, or to know what each
operation costs. The code is 5,582 lines of Cesia in `core/` and `src/`, without their tests, and each file can be read
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
`Top` and `Left` (the first line and column on the screen), `Colors`, `Wanted` (the goal column), `Typing`, `Free` (true after
the wheel) and `Marks` (the errors of the check); a list has `List` too, and the check adds `Checked`, the version it read.

A buffer is modified when its `Version` differs from `Saved`. Each edit takes a new number from `Clock`, which never goes back,
so two different texts never share a number, and undo brings back the number of the state it returns to: comparing two
numbers says whether the text is the one saved, where comparing two texts would cost a pass over both.

## The rope

A buffer's text is a rope, [src/rope]: a binary tree whose leaves hold pieces of the text, at most 1,024 bytes each, and whose
inner nodes join two ropes, the text of the left one first. Each node keeps three numbers about the text under it: `Size`, its
bytes; `Lines`, its line ends; and `Height`, the longest path down to a leaf. Boehm, Atkinson and Plass described ropes in
1995, from their use in the Cedar system at Xerox PARC, as an alternative to strings held in one block of memory, where
joining two texts copies both: see [References](references.md).

```cesia
use src/rope
r = rope.Of("one\ntwo\nthree")
[rope.Size(r), rope.LineCount(r), rope.LineStart(2, r), rope.Line(3, r)] --> [13, 3, 4, "three"]
```

Positions count bytes from 0, lines count from 1. Every operation goes down the tree by those numbers:

- [rope.SplitAt], the bytes before a position and the others, goes down by sizes, and joins what it passes on the way back.
- [rope.JoinRopes] puts two ropes one after the other. Two small leaves whose bytes fit in 1,024 become one leaf.
- [rope.Insert] is a split, then two joins; [rope.Delete] two splits and a join.
- [rope.LineStart] finds the byte where line n starts by going down by counts of line ends, then searching one leaf.
- [rope.Text] makes the whole text, by visiting every leaf.

The tree is kept balanced as an AVL tree is, after Adelson-Velsky and Landis: at every node, the heights of the two sides
differ by at most one. A join of two ropes of very different heights goes down the side of the taller one, and puts each
node it rebuilds back in balance with one rotation or two, a rotation being the turn of three nodes that makes the taller
side shorter. A balanced tree of n leaves has a height of at most about 1.44 log₂ n, so a split, a join, an insert, a
delete and a search for a line visit O(log n) nodes: their cost grows with the logarithm of the size, and doubling the text
adds about one level. The paper on ropes names AVL trees as one way to make these operations logarithmic; its own ropes join
in constant time instead, and rebalance only when a tree grows deeper than a bound. Cemacs keeps the AVL balance at every
join, and, as the paper does, makes one leaf of two short leaves joined, and copies only the nodes along the path of an
edit. Inside a leaf the work is at most 1,024 bytes. The whole text, `rope.Text`, costs O(n), and the editor never asks for
it but to save or to check.

Measured on a text of 20,000 lines, 707,583 bytes of Cesia's code: [rope.Of] makes 1,024 leaves of at most 691 bytes in a
tree of height 10; after 3,000 random inserts and deletes, the tree had 1,095 leaves and a height of 12, and the two sides of
every node still differed by at most one, checked every 100 edits. A random edit can leave a small leaf, down to a few bytes,
which a later join may merge.

A rope is persistent: an edit makes new nodes along one path, O(log n) of them, and shares every other node with the rope
before it, which stays whole.

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

Each buffer keeps the state at the start of each line, known down to some line. An edit at line n forgets the states after
n; drawing reads them again only down to the last line on the screen, and a line with no quote and no comment mark is not
even read, since it can't change the state. So typing at line 19,000 of a file reads only the lines on the screen, and a jump
to the end of a large file reads every line once, the first time.

## The frame

[view.View] makes the frame from the state: a clear of the window, then each pane, its code, its mode line and the line
between panes, then the output, the band of hints and the prompt line. It reads only the lines on the screen, cut to the
columns that fit, so a large file costs no more to draw than a small one. It only reads: [view.FollowState], which the update
calls last, is the one place that moves the screen of each pane to keep its cursor in sight, and that extends the known
colours down to the last line shown.

The frame is made again whole at each event, from the state: the program says what to draw, not what changed. This is the
way of an immediate-mode interface, as it is called, where no widget keeps a state of its own between frames. Under it,
[src/sdl] keeps what costs to make: a text object of SDL3_ttf for each place in the frame, up to 8,192, whose text and font
are set again only when they differ from the last frame. Frames wait for the screen's refresh, which SDL calls vsync, so
Cemacs draws no frame that the screen can't show.

## The loop of events

[sdl.Run] is a loop that never blocks on the window:

1. It takes every event waiting, without waiting for one: a key, a text, the mouse, a change of size, the window closed. A
   TERM or INT signal asking the program to end comes as the window closed.
2. It calls the update on each, in order.
3. If the state asks for frames of its own, [commands.Moving], it gives the update a tick, an event `{Kind: "tick",
   Seconds}` with the time since the last pass, at most 0.05 seconds so that nothing jumps after a pause, then draws a
   frame, and lets the other fibers run.
4. Else, it draws a frame only if some event came, and sleeps 5 milliseconds.

A still editor draws nothing. The state asks for frames while a prefix key waits for the band of hints to open, which needs
the time counted; while a check runs or a buffer is due for one; and while a program runs, whose output comes at each pass.

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
