# Glossary

The words of editors that this book uses, in alphabetical order. Each says what the word means in general, then how Cemacs
does it, and leads to the chapter that tells it. Where Emacs has another word for the same thing, both are given.

## Atomic rename

A rename that the system makes in one step: at every instant the name leads to the old file or to the new one, never to a
part of either. POSIX asks it of `rename`. Cemacs saves by writing a new file and renaming it over the old one: see
[Files and buffers](files.md#never-losing-the-text).

## AVL tree

A binary tree kept balanced: at every node, the heights of the two sides differ by at most one, so that the tree stays about
1.44 log₂ n deep for n leaves. Named after Adelson-Velsky and Landis, who described it in 1962. Cemacs's rope is balanced so:
see [Inside Cemacs](internals.md#the-rope).

## Band of hints

The band that opens above the prompt line when a prefix key waits for half a second, listing the keys that can follow. Emacs
has it with `which-key-mode`. See [Windows and panes](windows.md#the-band-of-hints).

## Breakpoint

A line where a debugger stops the program each time it reaches it, to show its variables. `C-c d b` in Cemacs: see
[Running and debugging](running.md#breakpoints).

## Buffer

A text that the editor holds in memory, most often the text of a file: you edit the buffer, and saving writes it to the
file. Each buffer of Cemacs has its own cursor, mark, undo history and errors. See [Files and buffers](files.md).

## Chord

One key pressed with the modifiers held with it, written as `C-x`, `M-<` or `S-right`. See [Keys](keys.md#how-a-key-becomes-a-chord).

## Clipboard

The place where a cut or copied text waits to be pasted, shared by the programs of the desktop. Cemacs uses the system's,
and keeps one text in it: it has no kill ring. See [Editing](editing.md#cutting-copying-and-pasting).

## Command

What a key runs. In Cemacs, any function from the state of the editor to a new state; Emacs asks a command to be marked as
interactive. See [Keys](keys.md#words).

## Config

The record of functions the editor runs on: its keymaps, its settings and its hooks, made by `emacs.Config`. See
[Changing Cemacs](customising.md#the-config).

## Cursor

The place between two characters where typing inserts text, a line and a column in Cemacs. Emacs calls it the point. See
[Editing](editing.md#the-cursor).

## Debug adapter and language server

A language server is a program that knows one language and tells any editor the errors, completions and definitions of its
code, over the Language Server Protocol; a debug adapter does the same for a debugger, over the Debug Adapter Protocol.
Cemacs uses neither: see [Cemacs and other editors](comparison.md#in-features).

## Echo area

Emacs's name for the line at the bottom of the frame where messages show. Cemacs's prompt line does it. See
[Windows and panes](windows.md#the-prompt-line).

## Elm architecture

A way to build an interactive program from one state, a function that makes the next state from an event, and a function
that draws a state; named after the Elm language. Cemacs is built so: see [Inside Cemacs](internals.md#the-state-the-update-and-the-view).

## Encoding

The way the characters of a text become bytes in a file. Cemacs reads and writes UTF-8 only: see
[Files and buffers](files.md#encodings).

## Event loop

The loop at the heart of a program with a window: it waits for an event, a key, the mouse, a change of size, hands it to the
program, draws what changed, and waits again. Waiting well means sleeping in the system until an event comes, which costs no
processor, rather than looking for one again and again. See [Inside Cemacs](internals.md#the-loop-of-events).

## Fiber and channel

A fiber is a task of Cesia that runs beside the others in one program, taking turns with them; a channel is a queue that
fibers send values through. Cemacs waits for a check and for a program's output in fibers, so that typing never waits. See
[Inside Cemacs](internals.md#the-loop-of-events).

## Frame

In Emacs, a window of the system, which holds Emacs's windows; Cemacs calls it the window. Also, an image drawn on the
screen at once, as in frames per second: Cemacs makes one from its state at each event. See
[Windows and panes](windows.md) and [Inside Cemacs](internals.md#the-frame).

## Gap buffer

A text in one block of memory with a hole at the place of the last edit, so that typing there costs nothing and an edit
far away first moves the hole. GNU Emacs keeps its buffers so; Cemacs uses a rope. See
[Inside Cemacs](internals.md#why-a-rope).

## Goal column

The column that moves by lines try to keep through shorter lines. See [Editing](editing.md#moving).

## Group

In Cemacs, a prefix key under `C-c` whose binding is a name, as `C-c f`, files: the band of hints shows it as `+files`, as
the leader keys of Doom Emacs do. See [Keys](keys.md#the-global-keymap).

## Hook

A function that an app gives the core, which calls it at a moment: Cemacs has `Idle`, `Saved` and `Moving`. Emacs has many,
under the same name. See [Changing Cemacs](customising.md#hooks).

## Hot reload

New code loaded into a program while it runs, so that it keeps its state. `cesia do dev` reloads Cemacs so at each save of
one of its files. See [Changing Cemacs](customising.md#reloading-cemacs-while-it-runs).

## Immediate mode

A way of drawing an interface where the program makes the whole frame again from its state each time, and no widget keeps a
state of its own. Cemacs draws so: see [Inside Cemacs](internals.md#the-frame).

## Incremental search

A search that finds the next match as each letter is typed, `C-s` in Emacs. Cemacs has none yet: see [Search](search.md).

## Key binding and keymap

A key binding links a key sequence to what it runs; a keymap is a set of them. Cemacs's keymaps are dictionaries from a text,
as `"C-x C-s"`, to a function. See [Keys](keys.md#words).

## Key sequence and prefix key

A key sequence is one or more chords typed one after the other, as `C-x C-s`. A prefix key is the start of a longer one,
which waits for the next key. See [Keys](keys.md#how-a-key-sequence-is-read).

## Kill ring

Emacs's list of the last texts cut, which `M-y` goes through after `C-y`. Cemacs has none: see
[Editing](editing.md#cutting-copying-and-pasting).

## Lexer

The first step of reading code, which cuts it into words, its tokens. Cemacs's colours come from a lexer of its own, which
reads one line at a time and never stops on an error. See [Inside Cemacs](internals.md#the-colours).

## Line end

The character or the two that end a line: `\n` or `\r\n`. Cemacs keeps each line's own. See
[Files and buffers](files.md#line-ends).

## List

In Cemacs, a read-only buffer of rows that it makes for you, the buffers or the files of a folder, which typing filters and
where Enter acts on a row. See [Search](search.md#lists).

## Major mode

In Emacs, what gives a buffer its keys, its colours and its behaviour for one kind of text. Cemacs has no modes: every buffer
of text is Cesia, and a list has keys of its own over the global ones, the nearest thing to a major mode. See
[Windows and panes](windows.md#the-mode-line).

## Mark and region

The mark is a second place in a buffer, which you set; the text between it and the cursor is the region, which Cemacs calls
the selection. See [Editing](editing.md#the-mark-and-the-selection).

## Median and its interval

The median of n measures is the middle one once they are sorted; its 95 % interval is a range between two of the sorted
measures that holds the true median with a probability of at least 95 %. See [Speed](performance.md#how-it-was-measured).

## Minibuffer

Emacs's buffer at the bottom of the frame where you type the answer to a question. Cemacs's prompt line does it, and is no
buffer. See [Windows and panes](windows.md#the-prompt-line).

## Mode line

The line at the bottom of each pane that tells the state of its buffer: its name, a star when not saved, the place of the
cursor, the count of errors. See [Windows and panes](windows.md#the-mode-line).

## O(log n)

A cost that grows with the logarithm of the size n: doubling the size adds about one step. An edit of Cemacs's rope costs
O(log n) visits of nodes. See [Inside Cemacs](internals.md#the-rope).

## Pane

A part of the window that shows a buffer, with its own mode line; Emacs calls it a window. See
[Windows and panes](windows.md#the-panes).

## Persistent data structure and structural sharing

A persistent data structure keeps its old versions whole when it changes, by making new parts and sharing the others with
the old version: that sharing is structural sharing. Every value of Cesia is persistent, which makes the undo history and the
copies of a buffer cheap. See [Inside Cemacs](internals.md#the-state-the-update-and-the-view).

## Prompt line

Cemacs's line at the bottom of the window, which shows messages and asks questions: Emacs's echo area and minibuffer. See
[Windows and panes](windows.md#the-prompt-line).

## Pure function

A function whose result depends only on its arguments, and that changes nothing outside. Most of Cemacs's core is pure: see
[Inside Cemacs](internals.md#the-state-the-update-and-the-view).

## RSS and PSS

Two measures of a program's memory: RSS, the resident set size, is what of it is in RAM, shared libraries counted whole;
PSS, the proportional set size, divides each shared page between the programs that share it. See
[Speed](performance.md#at-rest).

## Rope

A text held as a balanced tree of pieces, so that an edit anywhere costs O(log n) and a copy shares everything. Cemacs's
buffers are ropes: see [Inside Cemacs](internals.md#the-rope).

## Shift selection

A selection made by holding Shift while moving, which the next move without Shift ends. See
[Editing](editing.md#the-mark-and-the-selection).

## Subsequence matching

A filter that matches when its characters come in a text in the same order, side by side or not: `cmd` matches
`commands.ce`. A kind of fuzzy matching; Emacs's completion calls it `flex`. See [Search](search.md#how-a-filter-matches).

## Task

A program of `cesia.toml` to run with its permissions, run by `cesia do NAME`. `C-c c r` runs the task that names the file
of the buffer: see [Running and debugging](running.md#the-task-that-runs-a-file).

## Tick

An event that Cemacs makes itself at each pass of its loop while something needs time counted, as the wait for the band of
hints, or a check. See [Inside Cemacs](internals.md#the-loop-of-events).

## Undo history

The states of a buffer's text that undo goes back through and redo forward. Cemacs's is linear and keeps 1,000 states. See
[Editing](editing.md#undo-and-redo).

## UTF-8

The encoding of Unicode where a character takes one to four bytes, ASCII one. RFC 3629 defines it. See
[Files and buffers](files.md#encodings).

## Visit

Emacs's word for opening a file in a buffer. See [Files and buffers](files.md#opening-a-file).

## Vsync

Drawing in step with the refresh of the screen, so that no frame is drawn that the screen can't show. See
[Inside Cemacs](internals.md#the-frame).

## Yank

Emacs's word for pasting, `C-y`. See [Editing](editing.md#cutting-copying-and-pasting).
