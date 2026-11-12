# Glossary

The words of editors that this book uses, in alphabetical order. Each says what the word means in general, then how Cemacs
does it, and leads to the chapter that tells it. Where Emacs has another word for the same thing, both are given.

## Alignment

Setting the letters of one sequence under those of another, letting either skip letters, the gaps, so that as many letters
as possible match; a score adds points for each match and takes some away for each gap, and the best alignment has the
best score. Smith and Waterman found it for DNA in 1981. A query of a few letters aligned with a file's path is what fuzzy
finders score. See [A case](finding.md#4-research-how-this-kind-of-problem-is-solved).

## Anchor

The line from which Cemacs reads the code above a line of Cesia to give it its place: the nearest line above it at the left
margin, in code, that starts a statement, after a run of lines that each end their statement. From there, the reading is
sure to start out of any block and bracket, as `cesia fmt`'s reading from the start of the file would be. See
[Inside Cemacs](internals.md#the-indent).

## Atomic rename

A rename that the system makes in one step: at every instant the name leads to the old file or to the new one, never to a
part of either. POSIX asks it of `rename`. Cemacs saves by writing a new file and renaming it over the old one: see
[Files and buffers](files.md#never-losing-the-text).

## AVL tree

A binary tree kept balanced: at every node, the heights of the two sides differ by at most one, so that the tree stays about
$1.44 \log_2 n$ deep for $n$ leaves. Named after Adelson-Velsky and Landis, who described it in 1962. Cemacs's rope is balanced so:
see [Inside Cemacs](internals.md#the-rope).

## Band of hints

The band that opens above the prompt line when a prefix key waits for half a second, listing the keys that can follow. Emacs
has it with `which-key-mode`. See [Windows and panes](windows.md#the-band-of-hints).

## Baseline

A measure taken before a change, on the same machine and in the same way as the measure after it, without which no "better"
can be shown. See [A case](finding.md#2-measure-before-changing-anything).

## Breakpoint

A line where a debugger stops the program each time it reaches it, to show its variables. `C-c d b` in Cemacs: see
[Running and debugging](running.md#breakpoints).

## Buffer

A text that the editor holds in memory, most often the text of a file: you edit the buffer, and saving writes it to the
file. Each buffer of Cemacs has its own cursor, mark, undo history and errors. See [Files and buffers](files.md).

## Case folding

Matching a capital and a small letter as the same letter, as a search does when its words hold no capital, in Emacs and in
Cemacs: `two` finds `Two`. See [Search](search.md#searching-a-buffer).

## Chord

One key pressed with the modifiers held with it, written as `C-x`, `M-<` or `S-right`. See [Keys](keys.md#how-a-key-becomes-a-chord).

## Chunk

A part of fixed size of a long list, kept as one element of a shorter list, so that cutting or extending the long list
copies one part and the short list, not everything before the place. Cemacs keeps the states of its colours in chunks of
1,024 lines. See [Inside Cemacs](internals.md#the-colours).

## Clipboard

The place where a cut or copied text waits to be pasted, shared by the programs of the desktop. Cemacs uses the system's,
and keeps one text in it: it has no kill ring. See [Editing](editing.md#cutting-copying-and-pasting).

## Command

What a key runs. In Cemacs, any function from the state of the editor to a new state; Emacs asks a command to be marked as
interactive. See [Keys](keys.md#words).

## Completion

Typing the start of a word and letting the editor write the rest, from the words it knows. In a file of Cesia, Tab
completes from the words around the cursor, the other buffers and the names of Cesia, and lists them under the cursor when
there are several. Emacs does it with `completion-at-point` and `dabbrev-expand`, Vim with `Ctrl-N`. See
[Editing](editing.md#completion).

## Config

The record of functions the editor runs on: its keymaps, its settings and its hooks, made by `emacs.Config`. See
[Changing Cemacs](customising.md#the-config).

## Continuation line

A line that goes on with a statement begun on a line above it: inside brackets, after a token that asks for more such as `,`
or `+`, or inside a comment. `cesia fmt` moves it with the line that starts the statement, and Cemacs's Tab too. See
[Editing](editing.md#indentation-in-a-file-of-cesia).

## Cursor

The place between two characters where typing inserts text, a line and a column in Cemacs. Emacs calls it the point. See
[Editing](editing.md#the-cursor).

## Debug adapter and language server

A language server is a program that knows one language and tells any editor the errors, completions and definitions of its
code, over the Language Server Protocol; a debug adapter does the same for a debugger, over the Debug Adapter Protocol.
Cemacs uses neither: see [Cemacs and other editors](comparison.md#in-features).

## Delta debugging

A way to find the cause of a failure by shrinking the input that fails: take pieces out, keep the smaller input while it
still fails, and go on with smaller pieces until nothing more can go. Zeller and Hildebrandt's `ddmin` (2002). It shrank each
query that found nothing to a single space. See [A case](finding.md#3-a-hypothesis-that-could-be-proved-wrong).

## Differential test

A test that runs two programs that solve the same problem on the same inputs and compares their answers, so that each
checks the other. Cemacs's ranks of the files are checked against Vim's `matchfuzzy()`. See
[A case](finding.md#quality-the-file-you-mean-comes-first).

## Dynamic programming

Solving a problem from the answers of its smaller parts, each kept in a table and computed once, instead of trying every
possibility: the best alignment of two texts, cell by cell, each from the cells before it. See
[A case](finding.md#alignment-and-its-table).

## Echo area

Emacs's name for the line at the bottom of the frame where messages show. Cemacs's prompt line does it. See
[Windows and panes](windows.md#the-prompt-line).

## Electric indentation

Indenting a line again when a character or a word typed changes its place, as a closing `end`. Emacs has it with
`electric-indent-mode`, Vim and Neovim with `'indentkeys'`. In a file of Cesia, Cemacs does it at `end`, `else`, `then` and
the closing brackets typed at the start of a line. See [Editing](editing.md#indentation-in-a-file-of-cesia).

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

## Gap and gap penalty

In an alignment, letters of one text that the other skips; the penalty is what the score loses for them. fzy charges 0.01 a
letter skipped between two matched letters, and 0.005 a letter before the first or after the last; Gotoh's affine gap costs
a price to open and a smaller one per letter. See [A case](finding.md#fzys-score).

## Gap buffer

A text in one block of memory with a hole at the place of the last edit, so that typing there costs nothing and an edit
far away first moves the hole. GNU Emacs keeps its buffers so; Cemacs uses a rope. See
[Inside Cemacs](internals.md#why-a-rope).

## Garbage collector

The part of a runtime that frees the memory of the values no longer reachable, the garbage. OCaml's, under Cesia, makes the
values in a small minor heap and frees those that die young at its next minor collection, at no cost for each dead value;
the others it frees little by little, at a pace set by what the program allocates: what an open of a large file leaves behind
can stay in memory for a while after it. See [Speed](performance.md#at-rest).

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

A search that finds the next match as each letter is typed, instead of waiting for the whole words: `C-s` forward and `C-r`
backward, in Emacs and in Cemacs. The match shows selected, `C-s` again goes to the next one, and round the end of the file
once none is left. See [Search](search.md#searching-a-buffer).

## Indent

The spaces at the start of a line, which show how deep in blocks its code is; to indent a line is to give it those spaces.
In a file of Cesia, Cemacs gives each line the indent that `cesia fmt` gives it, two spaces a block. See
[Editing](editing.md#indentation-in-a-file-of-cesia).

## Just-in-time colouring

Colouring the code of a buffer when a part of it is shown, not all of it at its opening: Emacs's jit-lock. Cemacs colours
the lines on the screen from the states of the lines above, and when those are far, shows the screen at once with its states
guessed, and makes them exact over the ticks after. See [Inside Cemacs](internals.md#a-far-place-first-its-exact-colours-after).

## Key binding and keymap

A key binding links a key sequence to what it runs; a keymap is a set of them. Cemacs's keymaps are dictionaries from a text,
as `"C-x C-s"`, to a function. See [Keys](keys.md#words).

## Key sequence and prefix key

A key sequence is one or more chords typed one after the other, as `C-x C-s`. A prefix key is the start of a longer one,
which waits for the next key. See [Keys](keys.md#how-a-key-sequence-is-read).

## Kill ring

Emacs's list of the last texts cut, which `M-y` goes through after `C-y`. Cemacs has none: see
[Editing](editing.md#cutting-copying-and-pasting).

## Lazy view

A part of a view made again only when what it is made from changed; else the one made before is used. Elm calls it
`Html.Lazy`. Cemacs keeps the tokens of each line on the screen under its text, its width and the state at its start. Keeping
a result under the arguments it was made from is called memoization. See [Inside Cemacs](internals.md#the-frame).

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

## Mean reciprocal rank

A measure of a ranking: each query scores 1 divided by the rank of its right answer, 1 when it is first, 1/2 second, 0
when it isn't there, and the mean is taken over the queries. From TREC-8, in 1999. The list of a project's files scores
0.898 on 41 queries, against 0.597 before it ranked. See [A case](finding.md#how-ranking-is-measured).

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

A cost that grows with the logarithm of the size $n$: doubling the size adds about one step. An edit of Cemacs's rope costs
$O(\log n)$ visits of nodes. See [Inside Cemacs](internals.md#the-rope).

## Pane

A part of the window that shows a buffer, with its own mode line; Emacs calls it a window. See
[Windows and panes](windows.md#the-panes).

## Persistent data structure and structural sharing

A persistent data structure keeps its old versions whole when it changes, by making new parts and sharing the others with
the old version: that sharing is structural sharing. Every value of Cesia is persistent, which makes the undo history and the
copies of a buffer cheap. See [Inside Cemacs](internals.md#the-state-the-update-and-the-view).

## Piece table

A way to hold the text of an editor: the file read stays as it was, never copied, and the text is a sequence of pieces,
each a span of the file or of a text of the edits. Crowley compared it with five others in 1998 and found it the best;
Visual Studio Code holds its text in a piece tree, the pieces in a balanced tree. Cemacs's rope is one: its leaves are views of
the texts. See [Inside Cemacs](internals.md#the-rope).

## Project

The files you work on together. In Cemacs, as in Emacs's `project.el`, a Git repository: its root is the folder that holds
`.git`, and its files are those Git lists. `C-x p f` lists them: see [Files and buffers](files.md#the-files-of-a-project).

## Prompt line

Cemacs's line at the bottom of the window, which shows messages and asks questions: Emacs's echo area and minibuffer. See
[Windows and panes](windows.md#the-prompt-line).

## Property-based test

A test that states a rule that must hold for every input, then tries it on hundreds of inputs made at random, the smallest
first, and shrinks a failing one to the smallest that still fails. QuickCheck, by Claessen and Hughes in 2000, made it known;
Cesia has `test.ForAll`. See [A case](finding.md#correct-tests-that-fail-before-and-pass-after).

## Pure function

A function whose result depends only on its arguments, and that changes nothing outside. Most of Cemacs's core is pure: see
[Inside Cemacs](internals.md#the-state-the-update-and-the-view).

## Ranking and score

A score is a number given to each row that a filter keeps, saying how well the filter fits it; ranking puts the rows in the
order of their scores, the best first. The list of a project's files ranks by fzy's score, [lists.Score]; the other lists
keep their order. See [Search](search.md#how-a-filter-matches).

## Response time

The time from an action, a key, to what the screen shows of it. Miller (1968) asks 0.1 second for a key's effect, and Card,
Robertson and Mackinlay (1991) give 0.1 second as the time constant of perceptual processing, the most a screen may wait
between two repaints for a movement to look smooth. See
[A case](finding.md#1-the-problem-stated-precisely).

## Rope

A text held as a balanced tree of pieces, so that an edit anywhere costs $O(\log n)$ and a copy shares everything. Cemacs's
buffers are ropes: see [Inside Cemacs](internals.md#the-rope).

## RSS and PSS

Two measures of a program's memory: RSS, the resident set size, is what of it is in RAM, shared libraries counted whole;
PSS, the proportional set size, divides each shared page between the programs that share it. See
[Speed](performance.md#at-rest).

## Shaping

Turning the characters of a text into the glyphs of a font and their places, kerning and ligatures included: the work of
HarfBuzz, which SDL3_ttf calls for each text. Cemacs keeps each shaped text by its words, so that a line that moves on the
screen is not shaped again. See [Inside Cemacs](internals.md#the-frame).

## Shift selection

A selection made by holding Shift while moving, which the next move without Shift ends. See
[Editing](editing.md#the-mark-and-the-selection).

## Statement

One step of a program, such as `x = 1`, `io.Print(x)` or `if a`, which can run over several lines, its continuation lines.
`cesia fmt` places the first line of each statement, and moves the others with it. See
[Editing](editing.md#indentation-in-a-file-of-cesia).

## Subsequence matching

A filter that matches when its characters come in a text in the same order, side by side or not: `cmd` matches
`commands.ce`. A kind of fuzzy matching; Emacs's completion calls it `flex`. See [Search](search.md#how-a-filter-matches).

## SWAR

SIMD within a register: work on several small values at once with the plain operations on one large integer. A word of 64
bits holds eight bytes, so one test of `word AND 0x8080808080808080` tells whether all eight are ASCII. SIMD, single
instruction, multiple data, is the name of the processor's own instructions for this. Cesia's [text.IsUtf8] and
[text.Count] work so, which [files.IsText] and the rope use. See [Files and buffers](files.md#encodings).

## Task

A program of `cesia.toml` to run with its permissions, run by `cesia do NAME`. `C-c c r` runs the task that names the file
of the buffer: see [Running and debugging](running.md#the-task-that-runs-a-file).

## Threat to validity

A reason why a proof could be wrong even when every number in it is true: queries chosen by the author, one project only, a
noisy machine. A study names each threat and says how it was ruled out. See [A case](finding.md#threats-to-validity).

## Tick

An event that Cemacs makes itself at each pass of its loop while something needs time counted, as the wait for the band of
hints, or a check. See [Inside Cemacs](internals.md#the-loop-of-events).

## Undo history

The states of a buffer's text that undo goes back through and redo forward. Cemacs's is linear and keeps 1,000 states. See
[Editing](editing.md#undo-and-redo).

## UTF-8

The encoding of Unicode where a character takes one to four bytes, ASCII one. RFC 3629 defines it, and what is valid:
no overlong form, a character written in more bytes than it needs, as `C0 AF` for `/`; no surrogate, the codes U+D800 to
U+DFFF that UTF-16 keeps for its pairs; nothing above U+10FFFF, the last code of Unicode. See
[Files and buffers](files.md#encodings).

## View of a text

A part of a text named by where it starts and its size, without a copy of its bytes. The leaves of Cemacs's rope are views,
`{Text, Start, Size, Lines}`, of the file read and of the texts typed. See [Inside Cemacs](internals.md#the-rope).

## Visit

Emacs's word for opening a file in a buffer. See [Files and buffers](files.md#opening-a-file).

## Vsync

Drawing in step with the refresh of the screen, so that no frame is drawn that the screen can't show. See
[Inside Cemacs](internals.md#the-frame).

## Yank

Emacs's word for pasting, `C-y`. See [Editing](editing.md#cutting-copying-and-pasting).
