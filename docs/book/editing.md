# Editing

This chapter tells how the cursor moves, how text is typed and deleted, how a selection is made, cut, copied and pasted, how
undo works, and what the mouse does. Every key here is in the table of `src/emacs/emacs.ce`, and runs a command of
[core/commands]: a public function from the state of the editor to a new state.

## The examples of this chapter

The examples below drive the real editor, with no window: [press.Press] plays keys and texts through [commands.Update], as
the window would send them, and the result is the state after them. This is how the tests of Cemacs drive it too.

```cesia
use core/press
use core/text
use core/view
use src/emacs
use src/rope
use src/ui
use std/value

defn editor(words)
  (** The editor with one buffer holding words, the Emacs keys and no window: 800 by 600 pixels, characters 8 by 19. *)
  s = view.Start([text.Of(words, missing)], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, 800, 600)
  s.Config = () -> emacs.Config(emacs.Keys)
  s
end

textOf(state) = rope.Text(state.Buffers[state.Current].Rope)   (** The text of the current buffer. *)
cursorOf(state) = state.Buffers[state.Current].Cursor   (** Its cursor. *)

textOf(press.Press(["Hello", "C-a", "Oh, "], editor(""))) --> "Oh, Hello"
```

A text such as `"Hello"` is typed one character at a time; a name such as `"C-a"` is a key.

## The cursor

The cursor is the place where typing inserts text: always between two characters, or before the first or after the last. It
is drawn as a thin bar that doesn't blink, since a blinking cursor would draw frames forever, and a still editor draws
nothing. Emacs calls this place the point; Cemacs calls it the cursor.

The cursor is a line and a column, `{Line, Column}`. Lines count from 1. Columns count characters from 0, so the column
is how many characters of the line come before the cursor. The mode line shows them as `line:column`:

```cesia
cursorOf(press.Press(["ab", "enter", "cd"], editor(""))) --> {Line: 2, Column: 2}
```

A character here is what Cesia counts as one: `é` is one character, though UTF-8 writes it in two bytes. Each character
takes one column on the screen, a wide one such as `中` too, which can then overlap the next.

## Moving

| Keys | Command | Moves the cursor |
|---|---|---|
| `C-f`, `right` | [commands.ForwardChar] | one character on; at the end of a line, to the start of the next |
| `C-b`, `left` | [commands.BackwardChar] | one character back; at the start of a line, to the end of the one above |
| `C-n`, `down` | [commands.NextLine] | one line down |
| `C-p`, `up` | [commands.PreviousLine] | one line up |
| `M-f` | [commands.ForwardWord] | to the end of the word, or of the next one |
| `M-b` | [commands.BackwardWord] | to the start of the word, or of the one before |
| `C-a`, `home` | [commands.LineStart] | to the start of the line |
| `C-e`, `end` | [commands.LineEnd] | to the end of the line |
| `C-v`, `pagedown` | [commands.PageDown] | one page down: as many lines as the pane shows |
| `M-v`, `pageup` | [commands.PageUp] | one page up |
| `M-<` | [commands.FileStart] | to the start of the file |
| `M->` | [commands.FileEnd] | to the end of the file |

`M-<` and `M->` need Shift on most keyboards, and either way works: Alt, Shift and `,` gives `M-S-,`, which is bound to the
same command, and so is `M-S-.`. A move stops at the ends of the file: `C-p` on the first line does nothing.

A word is a run of letters, digits and underscores, `_`. A character that isn't ASCII, the 128 characters of plain English
text, counts as a letter, so `été` is one word: Cesia knows the case of ASCII letters only, and treating the others as
letters keeps every alphabet in words. `M-f` first skips what is not a word, then the word:

```cesia
cursorOf(press.Press(["one two", "C-a", "M-f"], editor(""))) --> {Line: 1, Column: 3}
cursorOf(press.Press(["one two", "C-a", "M-f", "M-f", "M-b"], editor(""))) --> {Line: 1, Column: 4}
```

Moving by lines keeps the column you wanted, the goal column, through shorter lines: from column 3, a line of one character
puts the cursor at its end, and the next long line puts it back at column 3. Any other move, and any edit, forgets it.

```cesia
cursorOf(press.Press(["C-e", "C-b", "C-n"], editor("abcd\nx\nabcd"))) --> {Line: 2, Column: 1}
cursorOf(press.Press(["C-e", "C-b", "C-n", "C-n"], editor("abcd\nx\nabcd"))) --> {Line: 3, Column: 3}
```

A page is as many lines as the pane shows, with no line kept from the screen before: in a pane of 28 lines, `C-v` on line 1
goes to line 29. The screen follows the cursor, so that it stays in sight.

## Typing

A key that types, a letter or a digit with or without Shift, inserts its character at the cursor; so does a key of the
numeric keypad, and the text of an input method. A key with Control or Alt types nothing, and runs its command.

| Keys | Command | Inserts |
|---|---|---|
| `enter`, `S-enter` | [commands.NewLine] | a line end, then the spaces and tabs that start the current line, up to the cursor |
| `tab`, `S-tab` | [commands.Tab] | the text of [emacs.TabText]: two spaces |

So Enter keeps the indent, the spaces at the start of a line that show the code inside a block:

```cesia
textOf(press.Press(["  if x", "enter", "y"], editor(""))) --> "  if x\n  y"
```

Tab inserts spaces and never a tab character, since Cesia's code is indented with spaces: change [emacs.TabText] to have
another width. Typing over a selection replaces it, as in most editors; in Emacs, `delete-selection-mode` does that.

## Deleting

| Keys | Command | Deletes |
|---|---|---|
| `backspace`, `S-backspace` | [commands.DeleteBefore] | the character before the cursor; at the start of a line, the line end before it, which joins the two lines |
| `C-d`, `delete`, `S-delete` | [commands.DeleteAfter] | the character after the cursor; at the end of a line, the line end, which joins the next line to it |

With a selection, both delete the selection instead. At the start of the file `backspace` does nothing, and so does
`delete` at its end.

## The mark and the selection

The mark is a second place in the buffer, which you set; the text between the mark and the cursor, in whichever order, is
the selection. Emacs calls it the region. It is drawn with a background of colour, and a line end that it holds shows as one
more character of colour past the end of the line.

| Keys | Command | What it does |
|---|---|---|
| `C-space` | [commands.SetMark] | puts the mark at the cursor: the moves after it select |
| `S-right`, `S-left`, `S-down`, `S-up` | [commands.SelectForwardChar], [commands.SelectBackwardChar], [commands.SelectNextLine], [commands.SelectPreviousLine] | select one character, or one line, from the cursor |
| `S-home`, `S-end` | [commands.SelectLineStart], [commands.SelectLineEnd] | select to the start or to the end of the line |
| `S-pageup`, `S-pagedown` | [commands.SelectPageUp], [commands.SelectPageDown] | select one page up or down |
| `C-g` | [commands.Cancel] | takes the mark away, and says `Quit` |

There are three ways to start a selection, and each ends its own way:

- `C-space`: the mark stays through every move, until `C-g`, an edit, a cut or a copy. Emacs works so with
  `transient-mark-mode`, its default.
- Shift with a move: the mark is put where the cursor was, and the next move without Shift takes it away, as in most
  editors; Emacs calls it shift selection. A Shift move with a mark already set keeps that mark and grows the selection.
- The mouse: press the first button and drag.

```cesia
s = press.Press(["abc", "S-left", "S-left"], editor(""))
text.Region(s.Buffers[1]) --> "bc"
textOf(press.Press(["abc", "S-left", "S-left", "X"], editor(""))) --> "aX"
```

## Cutting, copying and pasting

| Keys | Command | What it does |
|---|---|---|
| `C-w` | [commands.Cut] | the selection removed, and put in the clipboard |
| `M-w` | [commands.Copy] | the selection put in the clipboard; the mark goes away, and the text stays |
| `C-y` | [commands.Paste] | the clipboard inserted at the cursor, in place of the selection |
| `C-k` | [commands.CutLine] | the rest of the line cut, or the line end itself when the cursor is already at the end |

The clipboard is the one of your system, shared with other programs: what Cemacs cuts, another program pastes, and the other
way. Emacs speaks of killing a text and yanking it back, and keeps every kill in a kill ring, a list of the last cuts that
`M-y` goes through. Cemacs has no kill ring: the clipboard holds one text, the last one cut or copied. A cut with nothing
selected says `Nothing is selected.`, a paste with an empty clipboard says `The clipboard is empty.`, and `C-k` at the end of
the file says `Nothing to cut.`.

`C-k` again and again adds each cut to the one before, so that `C-k C-k C-k` puts the line, its line end and the next line in
the clipboard together, and `C-y` puts them back at once. Emacs calls this appending kills. Any other command, a key that
types or a click, ends the chain: the next `C-k` starts a new text.

```cesia
s = press.Press(["C-k", "C-k", "C-k"], editor("one\ntwo\nthree"))
textOf(s) --> "\nthree"
s.Clip --> "one\ntwo"
```

The examples have no window, so they keep the clipboard in the state, as `Clip`; in the window it is the system's.

## Undo and redo

| Keys | Command | What it does |
|---|---|---|
| `C-/` | [commands.Undo] | the last step undone, the cursor where it was before that step |
| `C-?`, `C-S-/` | [commands.Redo] | the step undone last done again, the cursor where that step left it |

Each buffer keeps its undo history: the states of its text, one per step, so a step can be taken back and done again. A
step is one command that changes the text, with one exception: typing makes words. A character typed right after another
one joins its step, and a space typed ends the step, as its last character; Enter and Tab are steps of their own. So typing
`hello world` and undoing takes back `world`, then `hello `:

```cesia
textOf(press.Press(["hello world", "C-/"], editor(""))) --> "hello "
textOf(press.Press(["hello world", "C-/", "C-/"], editor(""))) --> ""
```

Any other command, a move too, ends a step of typing. A typed text that replaces a selection is one step, the removal and
the new text together.

The history is linear: after an undo, a new edit forgets the steps that could have been done again. It keeps up to 1,000
states before the present one, and the oldest go first. Emacs works another way: its undo is an edit of its own, which a later undo takes back, so it has
no separate redo. In Cemacs `C-?` is redo, as `Ctrl-Shift-Z` is in many editors.

```cesia
textOf(press.Press(["x", "C-/", "y", "C-?"], editor(""))) --> "y"
```

The undo history knows which state was saved: undoing back to the text on disk takes away the star of the mode line. Undo and
redo take away the mark too, since a mark left where it was would select a text you never chose.

## C-g

`C-g` stops what the keys started:

- after a prefix key, as `C-x C-g`, it forgets the prefix, keeps the selection, and says `Quit`;
- with a question open on the prompt line, it closes the question, with no answer, and says `Quit`;
- in a list, it takes back what you typed to filter it, and with nothing typed it closes the list;
- else, it takes the mark away, and says `Quit`.

A key bound to nothing says so on the prompt line, as `C-t is not bound.` or `C-x C-t is not bound.`, and changes nothing.

## The mouse

| Action | Command | What it does |
|---|---|---|
| press of the first button | [commands.Press] | the pane under the mouse becomes the one you edit; in its code, the cursor goes to the edge between two characters nearest to the mouse |
| move with the button held | [commands.Drag] | selects from the press to the mouse, once the mouse has left the zone around the press |
| release | [commands.Release] | ends the drag; a click that selected nothing leaves no mark |
| wheel | [commands.Wheel] | scrolls the pane under the mouse |

The zone around a press is [emacs.DragZone], 4 pixels on either axis: a hand that moves a pixel while it clicks makes no
selection. Once the mouse has left the zone, the cursor follows it, even back into it. A drag past the edge of the code
keeps selecting, and the screen follows. A press is a command, so it ends a prefix key, a chain of `C-k` and a step of
typing. The other buttons only do that.

One notch of the wheel moves the screen by [emacs.WheelLines] lines, 3, without moving the cursor, and without making the
pane under the mouse the one you edit. A touchpad sends parts of a notch: what is less than a line is kept for the next
event, so a slow stroke still scrolls. After the wheel the screen stays where it is, the cursor maybe out of sight, until a
key or a click brings it back.

While a question is open on the prompt line, only the wheel and the end of a drag work, so that the text can't change under
the question.
