-- The frame: from a state to an array of commands for sdl. Everything here is pure and knows no window. The look of the state gives
-- the theme and the widths of the proportional fonts; cell is the size of one character of the code font.
use rope
use ui
use color
use text

-- The width of the line numbers and the space around them, before the first column of text.
Gutter = 62

-- Pixels added under the height of the code font to space the lines: JetBrains Mono at 13 is 18 high, and the 19 of ui.Code reads less tight.
LineGap = 1

tabsHeight = 36
modeHeight = 24
promptHeight = 22

-- The state of the editor with its buffers, before any key: the first buffer is current, there is no pending key, no prompt, no run and no window yet.
-- The editor adds its own fields: clip, the clipboard when there is no window; chorded, true right after a key with Ctrl or Alt, whose text event
-- is ignored; chain, true while the last command was C-k; dragging, true while the mouse selects; ending, true when the editor must stop; and title.
--
--   Start([], ui.Look(ui.Dark, (w, f) -> 8, 19), {Width: 8, Height: 19}, 800, 600).Current --> 1
Start(buffers, look, cell, width, height) = {Buffers: buffers, Current: 1, Pending: "", Prompt: missing, Message: "", Run: missing, Window: missing, Width: width, Height: height, Cell: cell, Look: look,
  Clip: "", Chorded: false, Chain: false, Dragging: false, Ending: false, Title: ""}

-- The rectangles of the screen {Tabs, Code, Output, Mode, Prompt}, and rows and columns, the lines and the characters that fit in code.
-- With showing_output false, output is empty. No size goes below zero, so a tiny window still has a layout.
--
--   Layout(800, 600, {Width: 8, Height: 19}, false).Output.Height --> 0
defn Layout(width, height, cell, showingOutput)
  whole = {X: 0, Y: 0, Width: width, Height: height}
  tabs = ui.Top(tabsHeight, whole)
  prompt = ui.Bottom(promptHeight, tabs.Rest)
  mode = ui.Bottom(modeHeight, prompt.Rest)
  outputHeight = if showingOutput Max(0, Div(mode.Rest.Height, 3)) else 0 end
  output = ui.Bottom(outputHeight, mode.Rest)
  code = output.Rest
  {Tabs: tabs.Part, Code: code, Output: output.Part, Mode: mode.Part, Prompt: prompt.Part,
    Rows: Max(0, Div(code.Height - 8, cell.Height)), Columns: Max(0, Div(code.Width - Gutter - 8, cell.Width))}
end

-- The name of a buffer in its tab: the last part of its path, or untitled.
bufferName(b) = if IsMissing(b.Path) "untitled" else Last(Split("/", b.Path)) end

-- The name of a buffer, as its tab and the title of the window show it.
--
--   BufferName(text.Of("", "src/a.k")) --> "a.k"
BufferName(b) = bufferName(b)

-- Is the text of a buffer modified since it was saved?
modified(b) = b.Version != b.Saved

-- The label of the mode line: the name, and a star if the text isn't saved. Tabs show the plain name and a dot instead.
label(b) = if modified(b) "$(bufferName(b)) *" else bufferName(b) end

-- A buffer whose top and left keep the cursor on the screen of rows lines and columns characters, and whose colors are known up to the last line on the screen.
-- It is the only place that moves the screen: view only reads. A buffer that is free, after the wheel, keeps its top and left: the cursor may be off the screen.
--
--   Follow(2, 10, {Rope: rope.Of("a\nb\nc"), Cursor: {Line: 3, Column: 0}, Top: 1, Left: 0, Free: false, Colors: color.BlankColors()}).Top --> 2
defn Follow(rows, columns, b)
  line = b.Cursor.Line
  column = b.Cursor.Column
  seenRows = Max(1, rows)
  seenColumns = Max(1, columns)
  top = if b.Free
    b.Top
  else if line < b.Top
    line
  else if line >= b.Top + seenRows
    line - seenRows + 1
  else
    b.Top
  end
  left = if b.Free
    b.Left
  else if column < b.Left
    column
  else if column >= b.Left + seenColumns
    column - seenColumns + 1
  else
    b.Left
  end
  lastLine = Min(rope.LineCount(b.Rope), top + seenRows)
  out = b
  out.Top = top
  out.Left = left
  out.Colors = color.ColoredTo(lastLine, n -> rope.Line(n, b.Rope), b.Colors)
  out
end

-- The state with the screen of its current buffer kept on the cursor, as follow does.
defn FollowState(state)
  lay = Layout(state.Width, state.Height, state.Cell, not IsMissing(state.Run))
  s = state
  s.Buffers[state.Current] = Follow(lay.Rows, lay.Columns, state.Buffers[state.Current])
  s
end

-- A text command in the font code, or in the font of the theme if none.
textCommand(x, y, words, color) = {Kind: "text", X: x, Y: y, Text: words, Color: color}
inside(font, x, y, words, color) = {Kind: "text", X: x, Y: y, Text: words, Color: color, Font: font}
rectCommand(x, y, w, h, color) = {Kind: "rect", X: x, Y: y, Width: Max(0, w), Height: Max(0, h), Color: color}
box(x, y, w, h, color, radius) = {Kind: "box", X: x, Y: y, Width: Max(0, w), Height: Max(0, h), Color: color, Radius: radius}

-- The tokens [role, text] of a line that are in the columns from left on, as [role, text, column], cutting the first one that straddles left.
defn visible(tokens, left)
  out = []
  column = 0
  for token in tokens
    size = Len(token[2])
    if column + size > left
      skipped = Max(0, left - column)
      words = if skipped > 0 Join("", Skip(skipped, Chars(token[2]))) else token[2] end
      out = Append([token[1], words, column + skipped], out)
    end
    column = column + size
  end
  out
end

-- The state at the start of line n, or the first one if the colors don't reach it yet.
startOf(n, colors) = if n <= colors.Known colors.Starts[n] else color.FirstState end

-- The commands of line n of a buffer: its number, then one text per token. The line is cut to the columns on the screen before
-- it is read, since sdl has no clipping and the tail would not be seen.
defn line(b, n, y, columns, rect, look)
  th = look.Theme
  cw = look.Width("M", "code")
  cs = Chars(rope.Line(n, b.Rope))
  words = if Len(cs) > b.Left + columns Join("", Take(b.Left + columns, cs)) else Join("", cs) end
  read = color.Tokens(words, startOf(n, b.Colors))
  x0 = rect.X + Gutter
  numbered = inside("code", rect.X + Gutter - 16 - Len("$n") * cw, y, "$n", th.Faint)
  out = [numbered]
  for token in visible(read.Tokens, b.Left)
    out = Append(inside("code", x0 + (token[3] - b.Left) * cw, y, token[2], th.Syntax[token[1]]), out)
  end
  out
end

-- The space between the top of the code area and its first line.
inset = 4

-- The y of the row of the code area (0 is the first one) and the x of a column of the screen, in pixels. Drawing and the mouse both use them.
rowY(row, rect, cell) = rect.Y + inset + row * cell.Height
columnX(column, rect, cell) = rect.X + Gutter + column * cell.Width

-- The division of two whole numbers rounded down, also when the first is negative.
defn floorDiv(a, b)
  if a >= 0
    Div(a, b)
  else
    0 - Div(b - 1 - a, b)
  end
end

-- The row and the column of the screen under a point, rounding the column to the nearest edge between two characters. They may be
-- outside the text, even negative.
defn cellAt(x, y, rect, cell)
  dy = y - rect.Y - inset
  dx = x - rect.X - Gutter + Div(cell.Width, 2)
  {Row: floorDiv(dy, cell.Height), Column: floorDiv(dx, cell.Width)}
end

-- The layout of a state.
layoutOf(state) = Layout(state.Width, state.Height, state.Cell, not IsMissing(state.Run))

-- Is a point inside the code area?
--
--   IsInCode(10, 100, Start([], ui.Look(ui.Dark, (w, f) -> 8, 19), {Width: 8, Height: 19}, 800, 600)) --> true
defn IsInCode(x, y, state)
  r = layoutOf(state).Code
  x >= r.X and x < r.X + r.Width and y >= r.Y and y < r.Y + r.Height
end

-- The position {Line, Column} of the current buffer under a point of the code area, brought inside the text.
--
--   PositionAt(0, 0, Start([text.Of("ab", missing)], ui.Look(ui.Dark, (w, f) -> 8, 19), {Width: 8, Height: 19}, 800, 600)).Line --> 1
defn PositionAt(x, y, state)
  lay = layoutOf(state)
  b = state.Buffers[state.Current]
  at = cellAt(x, y, lay.Code, state.Cell)
  text.Place(b.Top + at.Row, b.Left + at.Column, b).Cursor
end

-- The selection of a buffer on the lines from first to last: one rectangle per line, from the mark to the cursor. A line that the selection
-- crosses is filled one character past its end, to show that its line end is selected.
defn selection(b, first, last, lay, look)
  ends = text.Selection(b)
  if IsMissing(ends)
    return []
  end
  rect = lay.Code
  cell = lay.Cell
  out = []
  for n in Max(first, ends.First.Line):Min(last, ends.Last.Line)
    from = if n == ends.First.Line ends.First.Column else 0 end
    to = if n == ends.Last.Line ends.Last.Column else text.LineWidth(n, b) + 1 end
    a = Max(from, b.Left)
    z = Min(to, b.Left + lay.Columns)
    if z > a
      out = Append(rectCommand(columnX(a - b.Left, rect, cell), rowY(n - b.Top, rect, cell), (z - a) * cell.Width, cell.Height, look.Theme.Fill), out)
    end
  end
  out
end

-- The code area of a buffer: the band of the current line, the lines on the screen and the cursor bar.
defn code(b, lay, look)
  th = look.Theme
  cell = lay.Cell
  rect = lay.Code
  out = [box(rect.X, rect.Y, rect.Width, rect.Height, th.Code, 0)]
  first = b.Top
  last = Min(rope.LineCount(b.Rope), b.Top + lay.Rows - 1)
  lineY(n) = rowY(n - b.Top, rect, cell)
  here = b.Cursor.Line
  if here >= first and here <= last
    out = Append(box(rect.X + 4, lineY(here), rect.Width - 8, cell.Height, th.Hover, 4), out)
  end
  out = Concat(out, selection(b, first, last, lay, look))
  for n in first:last
    out = Concat(out, line(b, n, lineY(n), lay.Columns, rect, look))
  end
  if here >= first and here <= last and b.Cursor.Column >= b.Left and b.Cursor.Column - b.Left < lay.Columns
    out = Append(rectCommand(columnX(b.Cursor.Column - b.Left, rect, cell), lineY(here), 2, cell.Height, th.Bright), out)
  end
  out
end

-- A dot, for a file that isn't saved.
dotCommand(x, y, color) = box(x, y, 7, 7, color, 3)

-- The width of the tab of a buffer: its name, the space around it, and room for the dot of a text that isn't saved.
tabSize(b, look) = look.Width(bufferName(b), "body") + 28 + if modified(b) 13 else 0 end

-- The index of the tab under a point, or 0 if it is not on a tab.
--
--   TabAt(0, 100, Start([], ui.Look(ui.Dark, (w, f) -> 8, 19), {Width: 8, Height: 19}, 800, 600)) --> 0
defn TabAt(x, y, state)
  rect = layoutOf(state).Tabs
  if y < rect.Y or y >= rect.Y + rect.Height
    return 0
  end
  left = rect.X + 8
  for k in 1:Len(state.Buffers)
    size = tabSize(state.Buffers[k], state.Look)
    if x >= left and x < left + size
      return k
    end
    left = left + size
  end
  0
end

-- The tabs: one per buffer, flat on the bar. The current one has a blue line under it, and a blue dot marks a file that isn't saved.
defn tabs(state, lay, look)
  th = look.Theme
  rect = lay.Tabs
  out = [rectCommand(rect.X, rect.Y, rect.Width, rect.Height, th.Code), rectCommand(rect.X, rect.Y + rect.Height - 1, rect.Width, 1, th.Line)]
  x = rect.X + 8
  y = rect.Y + Div(rect.Height - look.Height, 2)
  for k in 1:Len(state.Buffers)
    b = state.Buffers[k]
    name = bufferName(b)
    dot = if modified(b) 13 else 0 end
    size = tabSize(b, look)
    if k == state.Current
      out = Concat(out, [inside("strong", x + 14, y, name, th.Bright), box(x + 8, rect.Y + rect.Height - 3, size - 16, 3, th.Accent, 1)])
    else
      out = Append(textCommand(x + 14, y, name, th.Muted), out)
    end
    if dot > 0
      out = Append(dotCommand(x + 14 + look.Width(name, "body") + 7, y + 6, th.Accent), out)
    end
    x = x + size
  end
  out
end

-- The mode line: the tab name, the position of the cursor, and the language.
defn mode(b, lay, look)
  th = look.Theme
  rect = lay.Mode
  y = rect.Y + Div(rect.Height - look.Height, 2)
  position = "$(b.Cursor.Line):$(b.Cursor.Column)"
  language = "Kepler"
  right = rect.X + rect.Width - 12
  [rectCommand(rect.X, rect.Y, rect.Width, rect.Height, th.Header), textCommand(rect.X + 12, y, label(b), th.Ink),
    textCommand(right - look.Width(language, "body"), y, language, th.Muted),
    textCommand(right - look.Width(language, "body") - 24 - look.Width(position, "body"), y, position, th.Muted)]
end

-- The prompt line: the question and the answer being typed, or else the last message.
defn prompt(state, lay, look)
  th = look.Theme
  rect = lay.Prompt
  y = rect.Y + Div(rect.Height - look.Height, 2)
  words = if IsMissing(state.Prompt) state.Message else "$(state.Prompt.Label)$(state.Prompt.Answer)" end
  bar = if IsMissing(state.Prompt) [] else [rectCommand(rect.X + 12 + look.Width(words, "body"), y, 2, look.Height, th.Bright)] end
  Concat([rectCommand(rect.X, rect.Y, rect.Width, rect.Height, th.Panel), textCommand(rect.X + 12, y, words, th.Ink)], bar)
end

-- The output pane, when there is room for it: its title and the status of the program.
defn output(state, lay, look)
  th = look.Theme
  rect = lay.Output
  if rect.Height == 0 or IsMissing(state.Run)
    []
  else
    y = rect.Y + 4
    [rectCommand(rect.X, rect.Y, rect.Width, rect.Height, th.Well), rectCommand(rect.X, rect.Y, rect.Width, 1, th.Line), inside("strong", rect.X + 12, y, "Output", th.Ink),
      textCommand(rect.X + 24 + look.Width("Output", "strong"), y, state.Run.Status, th.Muted)]
  end
end

-- The frame of a state: an array of commands for sdl. Only the lines on the screen are read, so a large file costs no more than a small one.
-- The screen of the buffer (top, left and colors) is what follow gave it.
defn View(state)
  look = state.Look
  lay = Layout(state.Width, state.Height, state.Cell, not IsMissing(state.Run))
  lay.Cell = state.Cell
  b = state.Buffers[state.Current]
  Flatten([[{Kind: "clear", Color: look.Theme.Ground}], code(b, lay, look), tabs(state, lay, look), output(state, lay, look), mode(b, lay, look), prompt(state, lay, look)])
end
