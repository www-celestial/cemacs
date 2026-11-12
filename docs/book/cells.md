# Cells and results

A file of Cesia cut into *cells* runs as a notebook: each cell runs on its own, and its result shows under it, in the
buffer. A cell starts at a line that holds only a comment starting with `%%`, as `(* %% Data *)`; the lines before the first
one are the first cell, usually the uses. The file stays a program: `cesia run` runs it from the top and computes what the
cells show. The engine is Cesia's [std/cells](https://www-celestial.github.io/cesia-lang/cells.html), whose chapter tells
its rules; this chapter tells what Cemacs does with it. The cells are an app of Cemacs, [src/notebook].

```cesia norun
use std/io
use std/list

(* %% Data *)
n = 1000
xs = [i * i for i in 1..n]

(* %% Mean *)
io.Print("mean of $n squares")
list.Mean(xs)
```

## Keys

The keys of the cells are a group of `C-c`, `e` for *execute*, which the band of hints shows as it shows the others:

| Keys | Command | What it does |
|---|---|---|
| `C-c e e` | [notebook.RunCell] | runs the cell of the cursor, then each cell that reads, directly or through others, a name it defines |
| `C-c e a` | [notebook.RunAll] | runs every cell, from the top |
| `C-c e i` | [notebook.InsertCell] | writes a marker, `(* %%  *)`, above the line of the cursor, the cursor where its title goes |
| `C-c e v` | [notebook.ShowVariables] | opens `*variables*` beside: the names the cells defined |
| `C-c e r` | [notebook.OpenRepl] | opens `*repl*` below: a prompt in the same session as the cells |
| `C-c e s` | [notebook.StopCell] | stops the cell that runs; the cells waiting after it don't run |
| `C-c e h` | [notebook.WriteHtml] | writes the page of the file beside it, `name.html` |
| `C-c e k` | [notebook.ClearResults] | clears the results drawn; the names of the session stay |

In `*repl*`, Enter runs what was typed, and `M-p` and `M-n` go back and on through what was typed before; anywhere else,
Enter is a new line, as always.

## Results under a cell

A result is drawn under the last line of its cell that isn't blank, after a thin bar: what the cell printed, then its value,
or its error in red with its line, as `cesia run` shows it. A graph of
[std/plot](https://www-celestial.github.io/cesia-lang/graphs.html) is drawn, 400 pixels high and as wide as the pane. A frame shows as a table of its first 20 rows and its count, a
matrix as its shape and its first 10 × 10 values, any other value as its text. A cell that runs shows `running…` and the
seconds so far; the cells after it in the queue show `waiting`. A cell that printed nothing and gives no value draws
nothing. Each part is cut at 40 lines, the last one saying how many more there are.

A result is no text: the cursor never goes into it, it is never saved, and an edit can't touch it. It moves with the lines
of its cell as you type above it or in it, and half a second after the last key, it goes back under the last line of its
cell. The screen, the mouse and the cursor count its rows: a page shows fewer lines when results take room in it.

## Graphs

A cell whose last expression is a graph, as `plot.Line(t, y)` or `plot.Of([...])`, shows it under its code. The session
computes its *scene*, the shapes of the graph in pixels at the width of the pane, and Cemacs draws the scene: its lines with
soft edges, its areas, bars, marks and cells, and its texts in Noto Sans Medium, the font std/plot measured them with,
without kerning, the adjustment of the space between two letters, and without hinting, so that each text takes the width
std/plot gave it. The axes, the grid and the texts take the colours of the theme; the data keep their own. When the pane
changes its width, the session draws the scene again at the new one; the graph keeps its shape until it comes. `*repl*`
draws a graph under its answer in the same way, and the page of `C-c e h` holds each graph as SVG.

## What runs again

`C-c e e` reads the cells of the buffer as it is, its unsaved changes too, and runs the cell of the cursor and those that
depend on it, in the order of the file: a cell that changed and the cells that use what it computes. The other cells keep
their results. The first cell, the uses, runs them all. A cell that breaks a rule of the cells, as a name defined in two
cells or a name read before its cell, shows that error in place of a result, and doesn't run. A cell that runs again does
again what it does besides its value: it prints again, and writes its files again.

## The session

Each file of cells has a *session*: one Cesia process, `cesia run --cells`, that keeps the names its cells defined, so that
a cell runs without the ones before it running again. It starts at the first cell run, with the permissions of the task of
`cesia.toml` that runs the file, as `C-c c r` gives them, or none; Cemacs starts it with the same `cesia` that runs
Cemacs, which `bin/cemacs` allows. The code of a cell runs as fast there as under `cesia run`.

`C-c e s` stops the cell that runs at its next wait or checkpoint, and the session keeps the names defined before it. A
cell that doesn't stop within 2 seconds, as one inside a single long call to native code, ends the session: a new one
starts, and every cell runs again from the top, which the prompt line says.

## \*variables\*

`C-c e v` splits the pane and lists in the new one the names of the session, one a row: its name, its type, its size or
shape, and the start of its value, which the session gives as a few words: a large array never comes whole. The list is
read again after each run. Typing filters it, as any list. Enter on a row opens a viewer of that value, a frame or a matrix
in full, each row under its number: the rows come from the session 200 at a time, as the cursor nears the last one shown.

## \*repl\*

`C-c e r` splits the pane and opens `*repl*` under it: a prompt, `> `, in the session of the file. Enter runs the code after
the last prompt, and its output and its value show under it, then a new prompt. A line that doesn't end the code, as `if
x`, goes on with `. ` on the next one. `*repl*` reads every name the cells defined, but a definition of a name a cell
defines is refused, with the title of that cell: the file would no longer say what the session holds. Try a new value of
such a name in its cell, or under another name.

## The page

`C-c e h` runs every cell of the file, as saved, in a new session, and writes `name.html` beside it: each cell's title, its
code coloured as Cesia's docs colour it, what it printed and its value, as a table or a text, or its error. The page needs
no other file and no script, and shows what `cesia run` computes, not the state of the window.

## Speed

Typing in a file of cells costs what typing in any file costs: the cells are read again only when a cell runs, and half a
second after the last key to put the results back under their cells, never at each key. Measured in a window of 1920 by
1080 drawn by SDL's dummy driver, 21 samples of 50 keys each, taking turns: a typed character with the screen of a file of
50 cells with their results, 9.5 ms, the median of the samples; the same file without cells or results, 10.0 ms, as the
results take rows that lines would take. A frame with eight results on the screen takes 9.4 ms, the median of 21, under
the 16.7 ms of one refresh of a screen at 60 Hz.

A graph of 100,000 points, which std/plot's scene brings down to four points per pixel column, under a cell of a pane 1,800
pixels wide, with marks, a band, a title, a legend and its axes: drawn by SDL's OpenGL renderer in an offscreen window, 21
frames taking turns with the same screen without it, a frame takes 2.7 ms, against 1.3 ms without the graph. The first frame
of a new scene, after a change of width, writes its 29,000 vertices from Cesia, one number at a time, and takes 21.8 ms,
over one refresh; the scene itself takes 6.6 ms in the session. A still graph costs a call a shape: what is written stays
until the scene changes.
