# Windows and panes

Cemacs has one window, the one your system shows. This chapter tells its parts: the panes, which show buffers side by side
or one above the other, the mode line of each pane, the output, the prompt line and the band of hints. Emacs uses other
words for two of them: it calls the window of the system a frame, and each pane a window. Cemacs keeps the words of the rest
of the desktop, window and pane.

```cesia fold=code
use core/panes
use core/press
use core/text
use core/view
use src/emacs
use src/ui
use std/value

defn editor(width, height)
  (** The editor with one empty buffer and the Emacs keys, in a window of this size, with characters 8 by 19 pixels. *)
  s = view.Start([text.Of("", missing)], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, width, height)
  s.Config = () -> emacs.Config(emacs.Keys)
  s
end
```

## The window

The window opens at 1280 by 720 pixels, or at the size of the `Window` of your config, and you can change its size after.
Its title is the name of the current buffer. It is cut, from the bottom up, into:

| Part | Height | What it shows |
|---|---|---|
| the prompt line | 22 pixels | the last message, a question being asked, the filter of a list, or the error under the cursor |
| the output | once a program has run: a third of the height above the prompt line, after 24 pixels are taken off it | what the program printed, or its variables at a stop |
| the panes | the rest | the buffers, each pane with its mode line at its bottom |

[view.Layout] computes these rectangles, each `{X, Y, Width, Height}` from the top left of the window, from its size and the
size of one character of the code font:

```cesia
lay = view.Layout(800, 600, {Width: 8, Height: 19}, true)
[lay.Area.Height, lay.Output.Height, lay.Prompt.Height] --> [394, 184, 22]
```

The theme is dark, [ui.Dark] of `src/ui`, unless the `Theme` of your config gives another, as [ui.Light]; the window reads
it once, when it opens, as it reads its size: [Changing Cemacs](customising.md#settings) tells both. The text is drawn with
three fonts at the size of [emacs.FontSize]: Adwaita Sans for the mode line, the prompt line and the names in
the band of hints, Noto Sans Medium for the title of the output, and JetBrains Mono for the code, the numbers of the lines,
the keys in the band and the output itself.

## The panes

A pane shows one buffer, with a column of line numbers on its left and its mode line at its bottom. At the start there is
one pane, which fills the place of the panes.

| Keys | Command | What it does |
|---|---|---|
| `C-x 2`, `C-c w s` | [commands.SplitBelow] | splits the pane you edit in two, one above the other |
| `C-x 3`, `C-c w v` | [commands.SplitRight] | splits it in two, side by side |
| `C-x o`, `C-c w o` | [commands.NextPane] | goes to the next pane, from the last one to the first |
| `C-x 0`, `C-c w d` | [commands.ClosePane] | closes the pane you edit |
| `C-x 1`, `C-c w m` | [commands.OnlyPane] | keeps only the pane you edit |

A split gives each half its half of the pane, and the second one the odd pixel. Both halves show the same buffer at the same
place, and you stay in the first one. Each half must have room for 2 lines of 8 characters: else nothing is split, and the
prompt line says `This pane is too small to split.` A line of colour parts two panes side by side.

The panes are a tree, a structure where each split has two branches, and each branch is a split again or one pane, a leaf of
the tree. A split is `{Along, First, Second}`, where `Along` is `"rows"` for one above the other and `"columns"` for side by
side; a leaf is `{Buffer, View}`, the number of its buffer and the place it shows. Panes count from 1, in the order of the
leaves from the top left, and `C-x o` follows that order. Splitting below, then splitting the top half to the right, gives
three panes:

```cesia
s = press.Press(["C-x", "2", "C-x", "3"], editor(800, 600))
panes.Count(panes.Tree(s)) --> 3
[r.Width for r in panes.Rects(view.Layout(800, 600, {Width: 8, Height: 19}, false).Area, panes.Tree(s))] --> [400, 400, 800]
```

Closing a pane gives its place to the other branch of its split, and you edit the pane that is then at its number, or the
last one. The last pane can't be closed: `This is the only pane.`

### Two panes on one buffer

The text belongs to the buffer, so an edit shows in every pane that shows it. The place belongs to the pane: each pane has
its own cursor, mark and screen, so two panes on one file show two places of it. The pane you edit holds its place in the
buffer itself, and every command works there; each other pane keeps its place in its leaf, and going to it swaps them.

The place another pane keeps is a line and a column: it doesn't move with the lines added or removed above it, as Emacs moves
the point of each window. When the text has changed under it, it is brought back inside the text when it is drawn. A buffer
that no pane shows keeps the place it was left at.

### Which pane you edit

The pane you edit has a band of colour on the line of its cursor, a bright cursor, and a lighter mode line; another pane shows
its cursor in a faint colour, and no band. A click in a pane, in its code or its mode line, makes it the one you edit. The
wheel scrolls the pane under the mouse without making it the one you edit.

## The screen of a pane

A pane shows the lines from its top line down, as many as fit. It never wraps a line: a line longer than the pane is cut at
its edge, as Emacs does with `truncate-lines`. The screen follows the cursor, and moves as little as it can: when the cursor
goes below the last line shown, that line becomes the last one; above the first, the first. The same holds sideways, where a
cursor past the right edge moves the screen to the right.

After the wheel, the screen stays where it was put, even with the cursor out of sight, until a key, a typed text or a click
brings the screen back to the cursor.

The column on the left holds the number of each line, 62 pixels wide with its margins. A line with an error or a warning
has its number in red or in amber, and a breakpoint is a dot of colour before the number: see
[Errors in the lines](check.md) and [Running and debugging](running.md).

## The mode line

Each pane has a mode line at its bottom, a line that tells the state of its buffer. Emacs has the same, under the same
name, where it also names the modes of the buffer. From the left:

- the name of the buffer, with ` *` after it when its text isn't saved;

and from the right:

- the language: `Cesia` for a buffer of text, `List` for a list. Every buffer of text is coloured as Cesia, whatever the
  end of its file's name; only the check of errors looks at the end `.ce`;
- the place of the cursor, `line:column`, the column counted from 0;
- the count of the errors and warnings that the check found, as `2 errors, 1 warning`, in red when there is an error, in
  amber when there are only warnings. [view.MarkCount] makes the words.

```cesia
view.MarkCount(text.WithMarks([{Line: 1, Column: 0, End: 1, Severity: "error", Message: "m", Hint: missing}], text.Of("a", "a.ce"))) --> "1 error"
```

## The prompt line

The line at the bottom of the window, under every pane, is where Cemacs speaks to you and asks you things. Emacs splits this
in two words: the echo area, where messages show, and the minibuffer, where you type an answer. Cemacs's prompt line is both,
but it is no buffer: an answer is typed and deleted at its end only, and none of the moves of a buffer work in it.

It shows, the first one that applies:

1. a question and the answer being typed, with a bar after it: `Find file: src/`;
2. else the last message, such as `Saved notes.ce` or `C-t is not bound.`;
3. else, in a list, the words before its filter, `Filter: ` or the path of a folder, and what you typed;
4. else the error or the warning under the cursor, or else the first one of the cursor's line, with its hint, in its
   colour.

A message lasts until the next key or click. While a prefix key waits for the key after it, the prompt line shows it with a dash, as
`C-x -`, the way Emacs echoes a key sequence.

A question that takes `y` or `n`, such as `Text not saved. Quit anyway? (y or n)`, waits for one of the two letters, in either
case, and ignores the others; `C-g` closes it with no answer. Any other question ends with Enter.

Each answer given with Enter is kept, the last 100 for each question, as Emacs's minibuffer keeps its *history*: in a
question, `M-p` brings back the answer given before to the same question, the one before it at the next `M-p`, and `M-n`
goes the other way, back to what you had typed; at an end, the prompt line says `No answer before this one.` or `No
answer after this one.` A question is known by its words, so `Find file: ` has its own answers, and `Search project: `
its own. In `Find file: ` and `Save as: `, Tab completes the name of a file: see
[Files and buffers](files.md#opening-a-file). The history lasts until Cemacs ends.

## The band of hints

When a prefix key waits for [emacs.HintDelay] seconds, half a second, a band opens above the prompt line. It lists each key
that can follow, with the command it runs or, for a group, its name after a `+`: `C-c` shows `f +files`, `b +buffers` and the
other groups, and `C-c f` shows `f FindFile`, `s Save`, and so on. The keys are in the colour of keywords and the groups in the
accent colour of the theme, a blue, in columns read from the top down. The next key closes it. [keys.Hints] gives its rows:

```cesia
use core/keys
use std/text as str
keys.Hints("C-c", {"C-c f": "files", "C-c f f": str.Lower, "C-c q": str.Upper}) --> [{Key: "f", Name: "+files", Group: true}, {Key: "q", Name: "Upper", Group: false}]
```

The name of a command is its name in the code, without its package: `FindFile` for [commands.FindFile]. A function with no
name, written in place as `s -> ...`, shows as `a function`. Emacs shows such a band with `which-key-mode`, part of Emacs since
its version 30, and Doom Emacs turns it on.

## The output

Once a program has run, the output takes the bottom third of the window, above the prompt line. Its title is `Output`, or
`Variables` while the program is stopped, followed by the state of the program, such as `running` or `ended, code 0`. It shows
the last lines that fit, each cut at the edge. `C-c c h` hides it, or shows it again. [Running and debugging](running.md)
tells what it holds.
