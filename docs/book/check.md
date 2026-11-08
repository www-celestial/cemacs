# Errors in the lines

Cemacs checks each Cesia file while you write it, without running it, and shows the errors in the lines: what Emacs's
Flymake does, the checking of code on the fly. This chapter tells what it shows, when it runs, and how it follows your edits.
The check is an app of Cemacs, [src/check]: the core knows nothing of it.

## What it shows

Each error or warning is a mark on a span of a line, the characters it is about:

- a line of two pixels under the span, red for an error, amber for a warning; a span takes at least one character;
- the number of the line in the same colour;
- the words of the first mark of the line, errors first, two characters after the end of the line, in a quieter tone of the
  same colour, with `(+2)` when the line has two more; they are cut at the edge of the pane, and left out when fewer than
  four columns are free;
- the count of the buffer's marks in its mode line, as `2 errors, 1 warning`, red when there is an error;
- on the prompt line, when nothing else is said there: the mark under the cursor, from the start of its span to just after
  it, or else the first mark of the cursor's line, with its hint, the words that say how to fix it.

The words at the end of the line are drawn, not typed: they are not in the text, and the cursor never goes into them.

## What runs

The check is `cesia check`, the command of Cesia that reads code and says what is wrong without running any of it: syntax,
names that don't exist, the arguments of a known function, values that surely don't fit a type, and results whose `Err` would
go unseen. Cesia's book tells each kind. Cemacs runs it as:

```bash
cesia check --json --stdin PATH
```

`--stdin` gives it the text of the buffer on its input, so it checks the text as you see it, saved or not, with the other
files of its package as they are on disk; `--json` makes it write one JSON object per line, which [check.Marks] reads. Cesia
counts columns from 1, Cemacs from 0, and Cemacs keeps the marks of the buffer's own file only:

```cesia
use src/check
check.Marks("{\"file\": \"a.ce\", \"line\": 2, \"column\": 3, \"end\": 7, \"severity\": \"error\", \"message\": \"m\", \"hint\": null}", "a.ce") --> [{Line: 2, Column: 2, End: 6, Severity: "error", Message: "m", Hint: missing}]
```

`cesia check` is the same check that `cesia lsp`, Cesia's language server, gives other editors. Cemacs runs the command, not
the server: one process for each check, which reads the files it needs and ends.

## When it runs

A buffer is due for a check when its file's name ends with `.ce` and its text has changed since it was last checked:

```cesia
use core/text
check.IsDue(text.Of("", "a.ce")) --> true
check.IsDue(text.Of("", "notes.md")) --> false
```

Once no key, text or click has come for [emacs.CheckDelay] seconds, half a second, Cemacs checks the current buffer if it is
due, or else the first buffer that is. So typing never starts a check: a pause does.

- One check runs at a time, in a process started from a fiber, a task of Cesia that waits beside the editor without
  holding it, so that the editor never waits for it: you go on typing while it runs, and its result comes at a later pass
  of the loop.
- A result for a text that changed while it ran is dropped, and the next pause asks again.
- After a save, every Cesia buffer is due again, since another file may use the one just saved.
- A check that can't run, because `cesia` isn't on the `PATH` for instance, says `cesia check can't run: REASON` once, and the
  buffer counts as checked, so it isn't asked again until it changes.
- A buffer of more than [check.CheckLimit] bytes, 1,000,000, is not checked: it counts as checked, with no mark, and its mode
  line says `not checked: over 1 MB` where the count of marks would be. `cesia check` of a file of 15.9 MB grew to 320 MB
  and kept a core busy for more than 12 s, for marks nobody reads in a file that size, often a generated one; the editor
  stays as light at rest with such a file as the other editors, which check nothing unless asked. The words come with the
  marks, [text.WithMarks] with a `note`, and an edit that brings the buffer under the limit checks it again at the next
  pause.

While a check runs or a buffer is due, Cemacs counts the time with ticks, events it makes itself at each pass of its loop,
and draws a frame at each one; a still editor with nothing due draws nothing. See [Inside Cemacs](internals.md#the-loop-of-events).

## How the marks follow your edits

A check takes a moment, and the text changes meanwhile. An edit takes away the marks of the lines it changes, so that a fix
you are typing loses its mark at once, and moves the marks below it with their lines; undo and redo do the same. The marks
of the other lines stay until the next check gives the new ones.

```cesia
use core/press
use core/view
use src/emacs
use src/ui
use std/value
mark = {Line: 3, Column: 0, End: 1, Severity: "error", Message: "m", Hint: missing}
b = text.WithMarks([mark], text.Of("a\nb\nc", "a.ce"))
s = view.Start([b], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, 800, 600)
s.Config = () -> emacs.Config(emacs.Keys)
[m.Line for m in text.MarksOf(press.Press(["enter"], s).Buffers[1])] --> [4]
[m.Line for m in text.MarksOf(press.Press(["C-n", "C-n", "x"], s).Buffers[1])] --> []
```

Enter on line 1 moves the mark of line 3 to line 4; typing on line 3 takes it away.

## Going from one error to the next

| Keys | Command | What it does |
|---|---|---|
| `M-g n`, `C-c c n` | [check.NextError] | the cursor at the start of the next mark after it, and its words on the prompt line |
| `M-g p`, `C-c c p` | [check.PreviousError] | the cursor at the start of the mark before it |

Both go round the ends of the buffer, and a buffer with no mark says `No error here.` `M-g n` and `M-g p` are the keys of
Emacs's `next-error` and `previous-error`; `M-g` alone is a group, `errors`, so the band of hints shows them.

## The hooks of the check

The check needs to hear of time passing and of saves, which only the core sees. It asks for them through three hooks, which
[check.Hooked] adds to the config of the editor: `Idle(state)` at each tick, `Saved(state)` after each save, and
`Moving(state)`, which says whether it needs ticks. [Changing Cemacs](customising.md#hooks) tells how an app of your own can
use them.
