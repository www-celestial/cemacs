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
| `C-c e f` | [notebook.FocusControl] | gives the keys to the first slider of the cursor's cell, to the bar of its animation, or to its 3D graph: see Sliders, Animations and 3D graphs |

In `*repl*`, Enter runs what was typed, and `M-p` and `M-n` go back and on through what was typed before; anywhere else,
Enter is a new line, as always.

## Results under a cell

A result is drawn under the last line of its cell that isn't blank, after a thin bar: what the cell printed, then its value,
or its error in red with its line, as `cesia run` shows it. A graph of
[std/plot](https://www-celestial.github.io/cesia-lang/graphs.html) is drawn, 400 pixels high and as wide as the pane. A frame shows as a table of its first 20 rows and its count, a
matrix as its shape and its first 10 × 10 values, any other value as its text. A cell that runs shows `running…` and the
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
computes its *scene*, the shapes of the graph in pixels at the width of the pane, and Cemacs draws the scene: its lines with
soft edges, its areas, bars, marks and cells, and its texts in Noto Sans Medium, the font std/plot measured them with,
without kerning, the adjustment of the space between two letters, and without hinting, so that each text takes the width
std/plot gave it. The axes, the grid and the texts take the colours of the theme; the data keep their own. When the pane
changes its width, the session draws the scene again at the new one; the graph keeps its shape until it comes. `*repl*`
draws a graph under its answer in the same way, and the page of `C-c e h` holds each graph as SVG. The screen slides over a
graph a row at a time, its lower part showing when the screen starts inside it: see
[The screen of a pane](windows.md#the-screen-of-a-pane).

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
session yet, one starts and every cell runs, from the top. The thumb and the number follow the pointer at once; the
results follow as fast as the cells run, and keep showing until the new ones come, with `waiting` or `running…` above
them. After the slider, the time of its last rerun shows, as `rerun 104 ms`, so that you see why a graph lags.

**The latest number wins.** While the cells of a move run, the slider keeps only the last number it was moved to; once
they end, that number is set and they run once more. Two reruns of a slider never wait in line, nothing is cancelled,
and a result never comes from two numbers.

**Stale results.** A result computed with another number than the one the file writes now says so, on a line above it:
`stale: computed with rho = 28.0`. This happens after `C-c e s` stopped a rerun, which drops the number that waited,
after an undo of a move, and after you type another number by hand; the line goes once the cell runs again. A number
typed by hand runs nothing by itself, as any edit: `C-c e e` runs it.

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

`C-c e h` runs every cell of the file, as saved, in a new session, and writes `name.html` beside it: each cell's title, its
code coloured as Cesia's docs colour it, what it printed and its value, as a table or a text, or its error. The page needs
no other file and no script, and shows what `cesia run` computes, not the state of the window. An animation starts paused
on its first frame under a box *Play*, which plays it by CSS alone. A 3D graph shows at the view of its code, not at the
view it was turned to in the window.

## Security

A slider writes only the number of its own value, on its own line: before the edit, Cemacs checks that this line still lies
in the slider's cell and still holds the number it read there, and refuses the move otherwise; the text is read again at
the next key. The number written is one of the slider's steps, between its min and its max, made by
[cells.Snap](https://www-celestial.github.io/cesia-lang/cells.html), and the session takes it only for a name that holds a
number already. The file itself is written when you save it, as any buffer: through a new file beside it that a rename
puts in its place, and never over a file that changed on disk since it was read.

A scene comes from the session, another process, and Cemacs reads it as input: before anything is made of it, its size,
the kind and the fields of each item, and the vertices all of them would make are checked against [notebook.SceneLimits],
four million vertices and twenty thousand items at most; a scene past them, or of a shape std/plot never gives, is
refused, and the cell says why in red. A frame of an animation says its number of frames, from 1 to 300, and its rate,
from 1 to 60 a second, and is refused otherwise or when its count differs from the animation's: the animation pauses and
says why. The quads of a surface come as counts, from 1 to 200 a side, the places of exactly their points, each a number
from -1,000,000 to 1,000,000, a palette of 1 to 256 colors `#rrggbb`, a color of it or -1 for each quad, and an order of
1 or -1 for its rows and its columns; a 3D graph's view is two numbers, the elevation from -90 to 90: anything else is
refused, and a view refused leaves the graph at the one it shows, and says why. Cemacs asks the session one question at
a time, a frame, a slider's number, a view or a scene, so that no answer goes to another question. The check reads each number once: 16 ms for 100,000 marks, 25 ms for a heatmap of
a million cells. The memory the shapes take is written by `c.Write`, which checks its whole length against the block
before it writes.

## Speed

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
