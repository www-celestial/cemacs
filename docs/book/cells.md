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
| `C-c e f` | [notebook.FocusControl] | gives the keys to the first input of the cursor's cell, a slider or another, to the bar of its animation, to its 3D graph or to its table: see Sliders, Inputs, Animations, 3D graphs and Tables |
| `C-c e c` | [notebook.CopyTable] | copies a table as CSV: the one that has the keys, or had them last, or the first of the cursor's cell |

In `*repl*`, Enter runs what was typed, and `M-p` and `M-n` go back and on through what was typed before; anywhere else,
Enter is a new line, as always.

## Results under a cell

A result is drawn under the last line of its cell that isn't blank, after a thin bar: what the cell printed, then its value,
or its error in red with its line, as `cesia run` shows it. A graph of
[std/plot](https://www-celestial.github.io/cesia-lang/graphs.html) is drawn as wide as the pane, or as its own width when that is less, and with
the shape of its own size: 640 by 400 by default, a polar graph square. A frame, a matrix, a list of maps or structs and a
struct show as a table, as [Tables](#tables) tells, a list as its first values, any other value as its text. A cell that runs shows `running…` and the
seconds so far; the cells after it in the queue show `waiting`. A cell that printed nothing and gives no value draws
nothing. Each part is cut at 40 lines, the last one saying how many more there are.

Each result starts with its label, as in Jupyter: `Out[3]:` on its first row, in grey, the lines of the result after it and
aligned under it, so that what a cell gave stands apart from its code. The number counts the runs of the session, this one
included, and starts again at 1 with a new session; a result that starts with a graph has the label on a row of its own,
above the graph. A status as `running…` stays above the label, and `*repl*` writes its answers without one.

A cell shows more than its last value with `cells.Show` of
[std/cells](https://www-celestial.github.io/cesia-lang/cells.html), as `display` does in Jupyter: each value it shows comes
at its place among what the cell prints, a graph, a table, a matrix or a text, then the value of the last expression comes
last. Two graphs and a line between them:

```cesia norun
use std/cells
use std/io
use std/plot

(* %% Two graphs *)
cells.Show(plot.Line([1, 2, 3], [1, 4, 9]))
io.Print("then the other")
plot.Line([1, 2, 3], [9, 4, 1])
```

Each graph is drawn at the width of the pane and again when it changes, an animation has its own bar and a 3D graph turns
on its own; `C-c e f` gives the keys to the first of the cell. `*repl*` draws them in the same order, and so does the page
of `C-c e h`.

A result is no text: the cursor never goes into it, it is never saved, and an edit can't touch it. It moves with the lines
of its cell as you type above it or in it, and half a second after the last key, it goes back under the last line of its
cell. The screen, the mouse and the cursor count its rows: a page shows fewer lines when results take room in it.

## Graphs

A cell whose last expression is a graph, as `plot.Line(t, y)` or `plot.Of([...])`, shows it under its code. The session
computes its *scene*, the shapes of the graph in pixels at the width of the pane, never past the graph's own width, and as
high as the shape of its own size asks, `size = [w, h]` of `plot.Of` or 640 by 400, and Cemacs draws the scene: its lines with
soft edges, its areas, bars, marks and cells, and its texts in JetBrains Mono, the font of the code, which std/plot
measured them with, without kerning, the adjustment of the space between two letters, and without hinting, so that each
text takes the width std/plot gave it; a character JetBrains Mono lacks, as the superscript minus of `10⁻³`, is drawn in
Noto Sans Medium. The graph is drawn as part of the page, not pasted on it: the axes, the grid, the texts and the layers
without a colour of their own take the colours of the theme, black on white in the light one, as the SVG of `plot.Save`;
a layer given a colour keeps it, and so do heatmaps and surfaces. When the pane
changes its width, the session draws the scene again at the new one, its height following; the graph keeps its size until
it comes, and a graph narrower than the pane, at its own width, stays as it is. `*repl*`
draws a graph under its answer in the same way, and the page of `C-c e h` holds each graph as SVG. The screen slides over a
graph a row at a time, its lower part showing when the screen starts inside it: see
[The screen of a pane](windows.md#the-screen-of-a-pane).

## Tables

A frame, a matrix, a list of maps or structs and a struct show as a *table* under their cell, drawn as the page of
SunEarthTools draws its tables: thin borders, a header row in the strong font, numbers on the right of their column,
each decimal point under those of the others, texts on the left, in the font of the code, the ink of the theme on its
paper. The frame of the table and the rule under its header are in ink, the lines between rows and columns in the color
of lines; a line under the table says its rows, `rows 21–40 of 1000000`, the words of its filter and its sort.

A table shows 20 rows at most. A longer one scrolls inside its block: the wheel over it moves it three rows a notch,
and at its first or its last row the wheel moves the screen again. Its rows come from the session a hundred at a time,
around those shown, by `cells.Rows` of [std/cells](https://www-celestial.github.io/cesia-lang/cells.html): the value
never leaves the session, so a frame of a million rows opens as one of twenty, and a screen of it costs a screen. A
cell's text is cut at 40 characters, the last one `…`; a table wider than the pane shows the columns that fit, from the
one of the cursor.

`C-c e f` in its cell, Tab from another table of the cell, or a click on it gives the table the keys, as an input has
them: a ring of the accent color goes round it, the cell of the cursor has a box of that color, and the row chosen is in
reverse, ink and paper swapped.

| Keys | What they do |
|---|---|
| `←` `→` `↑` `↓` | the cursor a cell; the row of the cursor is the row chosen |
| `PgUp` `PgDn` | a screen, 20 rows, the cursor where it was on the screen |
| `Home` `End` | the first row, the last |
| `s` | sorts by the column of the cursor, increasing; again, decreasing; again, as given. A click on a header does the same |
| `/` | a filter: the words typed keep the rows that hold each of them, in any column, in any order, its ASCII letters in either case; it applies as you type, Enter keeps it, Escape takes it back |
| `M-w` | copies the text of the cell of the cursor |
| `C-u M-w` | copies the row of the cursor, its cells apart by tabs |
| `C-c e c` | copies the whole table as CSV, as std/csv writes it: its header, then its rows as it shows them, sorted and filtered, at most 100,000 |
| `Tab` `S-Tab` | the next table of the cell, the previous one |
| `Escape` `C-g` | leaves the table |

The sort and the filter happen in the session, which keeps the order for the next screen: numbers sort as numbers, NaN
and missing last both ways, and rows of equal values keep their order. A row chosen stays chosen when the table is
sorted again or filtered, at its new place, as long as the filter keeps it. While no table has the keys, every key does
what it did: `s` and `/` are typed in the buffer, `M-w` copies the region.

### A row and its point

Within the results of one cell, a table of $n$ rows and each line, points or texts of a graph with $n$ points are linked
by position, row $i$ to point $i$, as [std/cells](https://www-celestial.github.io/cesia-lang/cells.html) says:

```cesia norun
use std/cells
use std/frame
use std/plot

(* %% Day *)
hours = frame.Of({hour: [7, 8, 9, 10, 11, 12], elevation: [0.48, 9.99, 18.14, 24.35, 28.02, 28.66]})
cells.Show(hours)
plot.Points(frame.Column("hour", hours), frame.Column("elevation", hours))
```

A row chosen, by a click or the arrows, marks its point on each graph of the cell of as many points: a ring at the
point, at its exact place, even one that the graph thinned out of a long line, and a box of its values beside it,
`x = 9  y = 18.14`, which the session draws, one question for each mark. A click on a point of a marked graph, within 12
pixels, chooses its row: the table scrolls to it, sorted and filtered as it is, and shows it in reverse. A table and a
graph of other lengths are not linked, and nothing is linked across cells.

## Sliders

A *slider* is a bar with a knob that you drag to change a number. A cell of sliders holds only lines
`name = cells.Slider(value, min, max)`, each with its numbers written there, as [std/cells](https://www-celestial.github.io/cesia-lang/cells.html)
asks:

```cesia norun
use std/cells
use std/ode
use std/result

(* %% Parameters *)
rho = cells.Slider(28.0, 0.0, 50.0, step = 0.5)

(* %% Lorenz *)
lorenz(t, y) = [10.0 * (y[2] - y[1]), y[1] * (rho - y[3]) - y[2], y[1] * y[2] - 8.0 / 3.0 * y[3]]
s = result.Unwrap(ode.Solve(lorenz, [0.0, 50.0], [1.0, 1.0, 1.0]))
```

Under each such line, Cemacs draws its slider, from the text alone, before anything runs: the name, a track, a thumb, and
the number as the file writes it. A move writes the new number in the buffer, in place of the old one: the file says what
the window shows, and once it is saved, `cesia run` and the page of `C-c e h` read the same number. The number moves by
steps, from the min to the max, and is written with the decimals of the min and the step, `0.3` and never
`0.30000000000000004`.

- **The mouse.** A press on the track puts the thumb there, so one press is enough; a drag follows the pointer. The wheel
  scrolls the buffer, as anywhere, and never moves a slider.
- **The keys.** `C-c e f` gives the keys to the first slider of the cell of the cursor, drawn with a ring, and the band of
  hints lists its keys, as the slider pattern of WAI-ARIA has them: `right` and `up` move it a step, `left` and `down` a step
  back, `pageup` and `pagedown` ten steps, `home` and `end` to its min and its max; `tab` and `S-tab` go to the next slider of
  the cell and the previous one, round. `C-g`, a click in the text, a letter typed or any other key leaves it, and that key
  does what it always does.
- **Undo.** A drag, from the press to the release, is one step of undo, and so are the keys pressed in a row on one slider,
  as typing is.

A move runs again only the cells that read the slider's name, directly or through other cells: the session of the file
gets the new number with [cells.Set](https://www-celestial.github.io/cesia-lang/cells.html), *in place*, so that a function
of another cell that reads it sees it at once, and the slider's own cell, which holds nothing else, doesn't run. Without a
session yet, the number is written and nothing runs, and the prompt line says that `C-c e a` runs the cells with it: the
code of a file, which may come from elsewhere, runs only when you ask, never from a press of the mouse. The thumb and the number follow the pointer at once; the
results follow as fast as the cells run, and keep showing until the new ones come, with `waiting` or `running…` above
them. After the slider, the time of its last rerun shows, as `rerun 104 ms`, so that you see why a graph lags.

**The latest number wins.** While the cells of a move run, the slider keeps only the last number it was moved to; once
they end, that number is set and they run once more. Two reruns of a slider never wait in line, nothing is cancelled,
and a result never comes from two numbers.

**Stale results.** A result computed with another number than the one the file writes now says so, on a line above it:
`stale: computed with rho = 28.0`. This happens after `C-c e s` stopped a rerun, which drops the number that waited,
after an undo of a move, and after you type another number by hand; the line goes once the cell runs again. A number
typed by hand runs nothing by itself, as any edit: `C-c e e` runs it.

## Inputs

The other inputs of a form are written as a slider is, one a line in a cell of inputs, each with its value written
there: a list to choose from, a check box, a field to type in, and a day, as
[std/cells](https://www-celestial.github.io/cesia-lang/cells.html) gives them. Sliders and the others share a cell:

```cesia norun
use std/cells

(* %% Place and day *)
year  = cells.Choice(2026, [2025, 2026, 2027])
zone  = cells.Choice("GMT-5", ["GMT-6", "GMT-5", "GMT-4"])
day   = cells.Date("2026-11-23")
place = cells.Field("40.76, -73.984")
high  = cells.Field(50)
rho   = cells.Slider(28.0, 0.0, 50.0, step = 0.5)
bold  = cells.Check(false, label = "Bold line")
```

Under each line, Cemacs draws the input from the text alone, before anything runs, in the font of the code, in the ink
and on the paper of the theme, black on white in the light one: its name, then its box, its edges one pixel wide, with
its value as the file writes it, and a `v` at the right of a list and of a day; a check box is `[ ]` or `[x]` and its
label. Their names line up, and so do their boxes and the tracks of the sliders.

```
year   [ 2026        v ]
zone   [ GMT-5       v ]
day    [ 2026-11-23  v ]
place  [ 40.76, -73.984           ]
high   [ 50                       ]
rho    ----------o--------  28.0
[ ] Bold line
```

`C-c e f` gives the keys to the first input of the cell of the cursor, and a click to the input under it: its box takes
the accent color, and the band of hints lists its keys.

| Input | Keys | Mouse |
|---|---|---|
| a choice | `enter` opens the list, `up` and `down` move in it, `home` and `end` to the first option and the last, `pageup` and `pagedown` 8, `enter` chooses, `C-g` shuts it | a click opens the list, a click on an option chooses it |
| a check box | `space` checks it, or not | a click checks it, or not |
| a field | what you type goes in the box, `backspace` and `delete` erase, `left`, `right`, `home` and `end` move the cursor, `enter` sets it; a field of a number takes only a number | a click puts the cursor there |
| a date | `left` and `right` pick the year, the month or the day, `up` and `down` change it, the month round the year and the day within its month, `enter` sets it | a click picks the part under it |

`tab` and `S-tab` go to the next input of the cell and the previous one, sliders among them, round; `C-g` leaves, and so
does any other key, which then does what it always does. No key is taken while no input has them: Enter on the line of a
choice is a new line, Space a space, as everywhere.

A change writes the new value in the buffer in place of the old one, its bytes alone, one step of undo, then runs again
only the cells that read its name, at once, as a slider's move: no button to press. A field waits for `enter`, so
nothing runs at each letter typed, and so does a date. A text is written in quotes, its `"`, `\`, ends of line, tabs and
`$` escaped as Cesia reads them, by [cells.Snap](https://www-celestial.github.io/cesia-lang/cells.html): what you type
reaches the session as that text, and never runs, even `$(...)`. While the cells run, a heavy one shows `running…` and
`C-c e s` stops it, as for a slider; the latest value wins, and a result computed with another value than the file's
says `stale: computed with zone = GMT-5`. Without a session yet, the value is written and nothing runs, and the
prompt line says that `C-c e a` runs the cells with it.

## Animations

A cell whose last expression is an animation, as `plot.Frames([plot.Line(x, math.Sin(x - t)) for t in ts], fps = 30)`
of [std/plot](https://www-celestial.github.io/cesia-lang/graphs.html), shows its first frame, paused, over a bar:

```
  ▶ 12 / 120  ───────●──────────────────  30/s
```

`▶` while it is paused, `‖` while it plays, the frame shown and their number, a track with a thumb at the frame, and the
rate. It starts paused, at each run of its cell too, as WCAG 2.2 asks of what moves for more than 5 seconds.

- **The keys.** `C-c e f` in its cell gives the keys to the bar, drawn with a ring, and the band lists them: `space` plays it
  or pauses it, `right` and `up` go a frame on, `left` and `down` a frame back, `pageup` and `pagedown` ten, `home` and `end`
  to the first frame and the last; each of these pauses it first. `C-g`, a click in the text or any other key leaves it.
- **The mouse.** A press on `▶` plays it or pauses it; a press on the track goes to the frame under the pointer, and a drag
  follows it. A press on the graph does nothing.

**One frame at a time.** The frames stay in the session: Cemacs asks for each with
[cells.Scene](https://www-celestial.github.io/cesia-lang/cells.html), `frame = k`, at the width of the pane, while the frame
before shows, and keeps it until its time comes. So at most two frames are in Cemacs's memory, and an animation of 300
frames never crosses whole. No frame is skipped: each is a state of what you computed, and one late to come shows late,
while the bar says the rate it plays at, as `24/s of 30`. After the last frame comes the first, until you pause it.

**Only on the screen.** It plays while its graph is on the screen: scrolled away, or with its buffer in no pane, it waits
where it is, and Cemacs takes no tick for it; a paused animation takes none either. A cell that runs, or a slider's number
being set, comes before the next frame, which waits.

## 3D graphs

A cell whose last expression is a 3D graph, a surface of `plot.Surface` or lines of `plot.Line3` of
[std/plot](https://www-celestial.github.io/cesia-lang/graphs.html#3d), shows it at the view its code gives, `view = [az,
el]` or MATLAB's `[-37.5, 30]`, with a line under it that says the view:

```
  view −62.5°, 20° (code −37.5°, 30°)
```

The first angle is the *azimuth*, the turn around the vertical axis, and the second the *elevation*, the angle of the eye
above the plane of x and y; the line says the view of the code too while the graph shows another.

- **The mouse.** A drag on the graph turns it as if you held it, 0.5° a pixel: to the right, its front goes right; down,
  its top comes toward you. A press on the graph gives it the keys too.
- **The keys.** `C-c e f` in its cell gives it the keys, drawn with a ring around it, and the band lists them: the arrows
  move your eye 10°, `right` and `left` round the graph, `up` and `down` higher and lower, to straight above or below at
  most; `home` goes back to the view of the code. `C-g`, a click in the text or any other key leaves it.

**Each view is drawn by the session.** Cemacs asks for it with
[cells.Scene](https://www-celestial.github.io/cesia-lang/cells.html), `view = [az, el]`: std/plot projects the surface
there, as it does for the page, and only the places of its points on the screen cross back, with the order to draw its
quads; the colors of the quads stay in Cemacs while only the view changes. One question at a time: while one is asked,
a drag or a key only changes the view wanted, which the line shows at once, and once the answer comes, the latest view
wanted is asked, so the graph follows the mouse without a queue of old views. Nothing is written in the file: the code
keeps its view, the page shows it, and a run of the cell shows it again. To keep the view you found, write the two numbers
of the line as the cell's `view`.

A 3D graph in `*repl*` turns the same way, with the session of its file. A 3D graph in a grid or in an animation doesn't
turn.

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
such a name in its cell, or under another name. An animation shows its first frame, without a bar, and says that a cell
plays it. A 3D graph turns there as under a cell.

## The page

`C-c e h` runs every cell of the file, as saved, in a new session, and writes `name.html` beside it, as a save writes a file,
through a new file and a rename [files.Replace]; a file there already is asked about first, `name.html exists. Replace it?
(y or n)`, and a symbolic link there, which a folder from elsewhere can bring, is replaced by the page, never written
through, so the file it points to stays as it was. The page holds each cell's title, its
code coloured as Cesia's docs colour it, what it printed and its value, as a table or a text, or its error. The page needs
no other file and no script, and shows what `cesia run` computes, not the state of the window. An animation starts paused
on its first frame under a box *Play*, which plays it by CSS alone. A 3D graph shows at the view of its code, not at the
view it was turned to in the window.

## Security

A slider runs code only in a session that `C-c e e` or `C-c e a` started: a press on a slider of a file just opened writes
its number and runs nothing. A slider writes only the number of its own value, on its own line: before the edit, Cemacs checks that this line still lies
in the slider's cell and still holds the number it read there, and refuses the move otherwise; the text is read again at
the next key. The number written is one of the slider's steps, between its min and its max, made by
[cells.Snap](https://www-celestial.github.io/cesia-lang/cells.html), and the session takes it only for a name that holds a
number already. The file itself is written when you save it, as any buffer: through a new file beside it that a rename
puts in its place, and never over a file that changed on disk since it was read.

A choice, a check box, a field and a date are written the same way: only their value, over the columns where the
analysis read it, once Cemacs checked that these columns still lie in the input's cell and still hold a value of its
kind, a text in quotes, `true` or `false`, its number or its day. The value written is the one
[cells.Snap](https://www-celestial.github.io/cesia-lang/cells.html) makes, a text in quotes with its `"`, `\`, ends of
line and `$` escaped, so that nothing typed in a field can end the text, start another line or run as code, and the
session reads it as a value, never runs it, and gives it only to a name that holds a value of the same kind.

A scene comes from the session, another process, and Cemacs reads it as input: before anything is made of it, its size,
the kind and the fields of each item, and the vertices all of them would make are checked against [notebook.SceneLimits],
four million vertices and twenty thousand items at most; a scene past them, or of a shape std/plot never gives, is
refused, and the cell says why in red. A frame of an animation says its number of frames, from 1 to 300, and its rate,
from 1 to 60 a second, and is refused otherwise or when its count differs from the animation's: the animation pauses and
says why. The quads of a surface come as counts, from 1 to 200 a side, the places of exactly their points, each a number
from -1,000,000 to 1,000,000, a palette of 1 to 256 colors `#rrggbb`, a color of it or -1 for each quad, and an order of
1 or -1 for its rows and its columns; a 3D graph's view is two numbers, the elevation from -90 to 90: anything else is
refused, and a view refused leaves the graph at the one it shows, and says why. Cemacs asks the session one question at
a time, a frame, a slider's number, a view, a scene, the rows of a table or a mark, so that no answer goes to another
question. The rows of a table are input too: at most 1,000 rows and 256 columns, a text of at most 200 characters for
each column of each row, and a position for each from 1 to the rows of the value; rows that are not are refused, and the
table keeps what it shows and asks no more. The places of the points of a marked graph are at most 100,000 a layer, of
64 layers, each a number from -1,000,000 to 1,000,000. The words of a filter go to the session as a text, which finds
them as they are and never reads them as a pattern or as code. The check reads each number once: 16 ms for 100,000 marks, 25 ms for a heatmap of
a million cells. The memory the shapes take is written by `c.Write`, which checks its whole length against the block
before it writes.

## Speed

A table of a million rows: `PgDn` takes 0.48 ms, the median of 63 screens from the top, from the key to its block drawn
again; when its rows are asked of the session, every other screen, 4.0 ms from the key to the rows drawn, 11.3 ms at
most, under the 16.7 ms of one refresh at 60 Hz (three runs, the median of their medians). A cell that shows a frame of
1,000 rows appears in 2.62 ms, from `C-c e e` to its table drawn, against 2.74 when it showed the frame as text, the
medians of 21 runs taking turns: its table is drawn at the tick its result lands, and the names of `*variables*` come at
a later tick. Cemacs reaches its first frame in 30.84 ms, as before tables (30.86).

Typing in a file of cells costs what typing in any file costs: the cells are read again only when a cell runs, and half a
second after the last key to put the results back under their cells, never at each key. Measured in a window of 1920 by
1080 drawn by SDL's dummy driver, 21 samples of 50 keys each, taking turns: a typed character with the screen of a file of
50 cells with their results, 9.5 ms, the median of the samples; the same file without cells or results, 10.0 ms, as the
results take rows that lines would take. A frame with eight results on the screen takes 9.4 ms, the median of 21, under
the 16.7 ms of one refresh of a screen at 60 Hz.

A graph of 100,000 points, which std/plot's scene brings down to four points per pixel column, under a cell of a pane 1,800
pixels wide, with marks, a band, a title, a legend and its axes: drawn by SDL's OpenGL renderer in an offscreen window, 21
frames taking turns with a new scene, a frame takes 2.2 ms. The first frame of a new scene, after a change of width,
makes the arrays of its 29,000 vertices and gives each to C in one `c.Write`, and takes 12.7 ms, within one refresh; the
scene itself takes 6.6 ms in the session. A still graph costs a call a shape: what is written stays until the scene
changes. 100,000 marks take 249 ms for the first frame of their scene and 53 ms for the next ones, as SDL sends their
900,000 vertices again at each frame; a heatmap of 1,000 by 1,000, one image of a pixel a cell, 116 ms and 3.0 ms.

An animation of the Lorenz curve seen turning, 120 frames of 5,000 points at 30 a second, in a pane 1,834 pixels wide,
drawn by SDL's OpenGL renderer in an offscreen window: it plays at 29 to 30 frames a second, 115 to 119 frames shown in
each 4 seconds, of 119 at most. A frame takes about 10 ms from the question to the session to its answer in Cemacs, drawn by the session while
Cemacs draws the frame before, and the frame that shows it about 20 ms, most of it making the triangles of a line of 5,000
points. Under SDL's dummy driver, which draws its triangles in software, a still frame of this graph takes 38 ms, and the
animation plays at 6 frames a second.

A surface of 100 by 100 quads turned with the keys, in a pane 1,834 pixels wide, drawn by SDL's OpenGL renderer in an
offscreen window: from the key to the frame that shows the new view takes 30 ms, the median of 63 steps, under the
33 ms of 30 frames a second. Of it, the session projects the surface and writes its scene in 6.3 ms, Cemacs reads
its 192 KB of JSON in 3.5 ms and checks it in 1.3 ms, and the frame takes 8.2 ms, most of it picking the
places of the 40,000 vertices of the quads from those of the 10,201 points. When the order of the quads changes, as the
eye passes an axis, Cemacs makes their colors and their order again, about 10 ms more for that step.
