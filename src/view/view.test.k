-- Tests of view.Kp and text.Of: run with kepler test .
use color
use text
use view
use rope
use history
use ui

cell = {Width: 8, Height: 19}
look = ui.Look(ui.Dark, (words, font) -> Len(words) * 8, 19)

stateOf(buffers, width, height) = view.Start(buffers, look, cell, width, height)

-- A text of count lines, each one "word".
manyLines(count) = Join("\n", Map(n -> "word", Range(1, count)))

textsOf(commands) = Map(c -> c.Text, Filter(c -> c.Kind == "text", commands))

isOnlyVisibleLines() = isOnlyVisible(stateOf([text.Of(manyLines(20000), "a.k")], 800, 600))

defn isOnlyVisible(state)
  layout = view.Layout(state.Width, state.Height, state.Cell, false)
  b = view.Follow(layout.Rows, layout.Columns, state.Buffers[1])
  s = state
  s.Buffers = [b]
  shown = Len(Filter(t -> t == "word", textsOf(view.View(s))))
  shown > 0 and shown <= layout.Rows
end

defn isLongLineFollows()
  b = text.Of(Join("", Map(n -> "x", Range(1, 600))), "a.k")
  b.Cursor = {Line: 1, Column: 500}
  f = view.Follow(10, 80, b)
  f.Left <= 500 and 500 < f.Left + 80
end

defn isFollowScrollsDown()
  b = text.Of(manyLines(100), "a.k")
  b.Cursor = {Line: 50, Column: 0}
  f = view.Follow(10, 80, b)
  f.Top <= 50 and 50 < f.Top + 10 and f.Colors.Known >= 50
end

defn isFollowKeepsTop()
  b = text.Of(manyLines(100), "a.k")
  b.Cursor = {Line: 3, Column: 2}
  f = view.Follow(10, 80, b)
  f.Top == 1 and f.Left == 0
end

defn isTinyWindow()
  s = stateOf([text.Of("a\nb", "a.k")], 10, 10)
  lay = view.Layout(s.Width, s.Height, s.Cell, false)
  s.Buffers = [view.Follow(lay.Rows, lay.Columns, s.Buffers[1])]
  IsArray(view.View(s))
end

defn isTabs()
  a = text.Of("a", "/x/a.k")
  b = text.Of("b", "/x/b.k")
  b.Version = 3
  commands = view.View(stateOf([a, b], 800, 600))
  shown = textsOf(commands)
  dots = Filter(c -> c.Kind == "box" and c.Width == 7, commands)
  "a.k" in shown and "b.k" in shown and not ("b.k *" in shown) and Len(dots) == 1
end

isNoDotWhenSaved() = Len(Filter(c -> c.Kind == "box" and c.Width == 7, view.View(stateOf([text.Of("a", "/x/a.k")], 800, 600)))) == 0

isNoOutputPane() = view.Layout(800, 600, cell, false).Output.Height == 0
isOutputPane() = view.Layout(800, 600, cell, true).Output.Height > 0
isRowsFit() = view.Layout(800, 600, cell, false).Rows * 19 <= view.Layout(800, 600, cell, false).Code.Height
defn isOfFields()
  b = text.Of("a", "a.k")
  IsMissing(b.Mark) and IsMissing(b.Disk) and b.Version == 0 and b.Saved == 0 and b.Top == 1 and b.Left == 0 and b.Path == "a.k" and b.Colors.Known == 1 and b.Cursor.Line == 1 and b.Cursor.Column == 0 and history.CanUndo(b.History) == false
end
isOfRope() = rope.Text(text.Of("ab\ncd", "a.k").Rope) == "ab\ncd"

-- The commands of a one-buffer window 102 pixels wide, so that 4 columns of code fit, showing words from column left.
defn shownFrom(words, left)
  b = text.Of(words, "a.k")
  b.Left = left
  view.View(stateOf([b], 102, 600))
end

-- Is this command a text of the code area? Tabs, mode line and prompt are not: the window is 600 high, and the first line is at 32.
inCode(c) = c.Kind == "text" and c.Y >= 28 and c.Y < 100

-- The texts in the code area, the line number first.
codeTexts(commands) = Map(c -> c.Text, Filter(c -> inCode(c), commands))

isFourColumns() = view.Layout(102, 600, cell, false).Columns == 4
isCutToColumns() = Equal(codeTexts(shownFrom("abcdefghij", 3)), ["1", "defg"])

defn isCutX()
  first = Filter(c -> inCode(c) and c.Text == "defg", shownFrom("abcdefghij", 3))[1]
  first.X == view.Gutter
end

defn isTokenStraddlingLeft()
  commands = Filter(c -> inCode(c) and c.Text != "1", shownFrom("defn x", 2))
  Equal(Map(c -> c.Text, commands), ["fn", " x"]) and commands[2].X == view.Gutter + 16 and commands[1].Color == ui.Dark.Syntax[color.Keyword]
end

isLineShorterThanLeft() = Equal(codeTexts(shownFrom("ab", 5)), ["1"])
isMultibyteCutLikeAscii() = Equal(Map(t -> Len(t), codeTexts(shownFrom("ééééé", 2))), Map(t -> Len(t), codeTexts(shownFrom("eeeee", 2))))
isMultibyteText() = Equal(codeTexts(shownFrom("ééééé", 2)), ["1", "ééé"])

defn isEmptyFile()
  s = stateOf([text.Of("", "a.k")], 800, 600)
  lay = view.Layout(s.Width, s.Height, s.Cell, false)
  s.Buffers = [view.Follow(lay.Rows, lay.Columns, s.Buffers[1])]
  IsArray(view.View(s)) and s.Buffers[1].Top == 1
end

defn isCursorOnLastLine()
  b = text.Of(manyLines(3), "a.k")
  b.Cursor = {Line: 3, Column: 0}
  s = stateOf([b], 800, 600)
  lay = view.Layout(s.Width, s.Height, s.Cell, false)
  s.Buffers = [view.Follow(lay.Rows, lay.Columns, b)]
  bars = Filter(c -> c.Kind == "rect" and c.Width == 2, view.View(s))
  Len(bars) == 1 and Len(Filter(t -> t == "word", textsOf(view.View(s)))) == 3
end

defn isFollowWithoutRows()
  b = text.Of(manyLines(10), "a.k")
  b.Cursor = {Line: 5, Column: 3}
  f = view.Follow(0, 0, b)
  f.Top <= 5 and f.Left <= 3
end

defn isCursorBarInsideColumns()
  b = text.Of("abcd", "a.k")
  b.Cursor = {Line: 1, Column: 4}
  s = stateOf([b], 102, 600)
  s.Buffers = [view.Follow(4, 4, b)]
  bars = Filter(c -> c.Kind == "rect" and c.Width == 2, view.View(s))
  Len(bars) == 1 and bars[1].X < 102
end

-- The rectangles of the theme fill color: the selection.
fills(commands) = Filter(c -> c.Kind == "rect" and c.Color == ui.Dark.Fill, commands)

defn selectedState(words, mark, cursor)
  b = text.Of(words, "a.k")
  b.Mark = mark
  b.Cursor = cursor
  stateOf([b], 800, 600)
end

defn isSelectionOneLine()
  s = selectedState("abcdef", {Line: 1, Column: 1}, {Line: 1, Column: 4})
  f = fills(view.View(s))
  Len(f) == 1 and f[1].X == view.Gutter + 8 and f[1].Width == 24 and f[1].Height == 19
end

defn isSelectionBackwards()
  s = selectedState("abcdef", {Line: 1, Column: 4}, {Line: 1, Column: 1})
  f = fills(view.View(s))
  Len(f) == 1 and f[1].X == view.Gutter + 8 and f[1].Width == 24
end

defn isSelectionLines()
  s = selectedState("abc\ndef\nghi", {Line: 1, Column: 2}, {Line: 3, Column: 1})
  f = fills(view.View(s))
  Len(f) == 3 and f[1].Width == 16 and f[2].Width == 32 and f[3].Width == 8 and f[2].Y == f[1].Y + 19
end

isNoSelectionNoFill() = Len(fills(view.View(selectedState("abc", missing, {Line: 1, Column: 1})))) == 0
isEmptySelectionNoFill() = Len(fills(view.View(selectedState("abc", {Line: 1, Column: 1}, {Line: 1, Column: 1})))) == 0

defn isSelectionUnderText()
  commands = view.View(selectedState("abc", {Line: 1, Column: 0}, {Line: 1, Column: 2}))
  firstFill = IndexOf(fills(commands)[1], commands)
  firstText = IndexOf(Filter(c -> c.Kind == "text" and c.Text == "abc", commands)[1], commands)
  firstFill < firstText
end

defn isSelectionCutToScreen()
  b = text.Of("abcdefghij", "a.k")
  b.Mark = {Line: 1, Column: 0}
  b.Cursor = {Line: 1, Column: 10}
  b.Left = 3
  f = fills(view.View(stateOf([b], 102, 600)))
  Len(f) == 1 and f[1].X == view.Gutter and f[1].Width == 32
end

defn isPromptDrawn()
  s = stateOf([text.Of("a", "a.k")], 800, 600)
  s.Prompt = {Label: "Find file: ", Answer: "a.k", Done: (a, t) -> t, Choice: false}
  commands = view.View(s)
  bars = Filter(c -> c.Kind == "rect" and c.Width == 2 and c.Y > 500, commands)
  "Find file: a.k" in textsOf(commands) and Len(bars) == 1 and bars[1].X == 12 + Len("Find file: a.k") * 8
end

defn isMessageDrawn()
  s = stateOf([text.Of("a", "a.k")], 800, 600)
  s.Message = "Saved a.k"
  commands = view.View(s)
  "Saved a.k" in textsOf(commands) and Len(Filter(c -> c.Kind == "rect" and c.Width == 2 and c.Y > 500, commands)) == 0
end

defn isPositionAt()
  s = stateOf([text.Of("abcd\nefgh", "a.k")], 800, 600)
  p = view.PositionAt(view.Gutter + 17, 36 + 4 + 19 + 3, s)
  p == {Line: 2, Column: 2}
end

isPositionClamped() = view.PositionAt(790, 590, stateOf([text.Of("abcd\nefgh", "a.k")], 800, 600)) == {Line: 2, Column: 4}
isPositionBeforeText() = view.PositionAt(0, 0, stateOf([text.Of("abcd\nefgh", "a.k")], 800, 600)) == {Line: 1, Column: 0}

defn isPositionWithScroll()
  b = text.Of(manyLines(50), "a.k")
  b.Top = 10
  b.Left = 0
  view.PositionAt(view.Gutter, 40, stateOf([b], 800, 600)).Line == 10
end

defn isPositionOnCursorBar()
  b = text.Of("abcdef", "a.k")
  b.Cursor = {Line: 1, Column: 3}
  s = stateOf([b], 800, 600)
  bar = Filter(c -> c.Kind == "rect" and c.Width == 2 and c.Y < 100, view.View(s))[1]
  view.PositionAt(bar.X + 1, bar.Y + 1, s).Column == 3
end

defn isTabAt()
  s = stateOf([text.Of("a", "x.k"), text.Of("b", "y.k")], 800, 600)
  view.TabAt(8, 10, s) == 1 and view.TabAt(59, 10, s) == 1 and view.TabAt(60, 10, s) == 2 and view.TabAt(500, 10, s) == 0 and view.TabAt(10, 50, s) == 0
end

defn isInCode()
  s = stateOf([text.Of("a", "x.k")], 800, 600)
  view.IsInCode(10, 100, s) and not view.IsInCode(10, 10, s) and not view.IsInCode(10, 580, s)
end

defn isFollowFreeKeepsTop()
  b = text.Of(manyLines(100), "a.k")
  b.Top = 60
  b.Free = true
  f = view.Follow(10, 80, b)
  f.Top == 60 and f.Colors.Known >= 60
end

defn isFollowStateMoves()
  b = text.Of(manyLines(100), "a.k")
  b.Cursor = {Line: 80, Column: 0}
  s = view.FollowState(stateOf([b], 800, 600))
  s.Buffers[1].Top > 1
end

-- M5 and M6: a click in the margins of the code area is on the nearest cell of the screen. A drag isn't kept there, so that the screen can follow it.
defn scrolledSide()
  b = text.Of(Join("", Map(n -> "x", Range(1, 100))), "a.k")
  b.Left = 40
  stateOf([b], 800, 600)
end
isClickInGutterScrolled() = view.ClickAt(10, 40, scrolledSide()) == {Line: 1, Column: 40}
isDragInGutterScrolled() = view.PositionAt(10, 40, scrolledSide()) == {Line: 1, Column: 34}
isClickUnderLastRow() = view.ClickAt(view.Gutter, 540, stateOf([text.Of(manyLines(100), "a.k")], 800, 600)).Line == 26
isDragUnderLastRow() = view.PositionAt(view.Gutter, 540, stateOf([text.Of(manyLines(100), "a.k")], 800, 600)).Line == 27
defn isClickAboveFirstRow()
  b = text.Of(manyLines(100), "a.k")
  b.Top = 10
  view.ClickAt(view.Gutter, 37, stateOf([b], 800, 600)).Line == 10
end
isClickWithNoRows() = view.ClickAt(view.Gutter, 37, stateOf([text.Of(manyLines(3), "a.k")], 800, 60)).Line == 1

-- M12: the one layout of a state.
isLayoutOf() = view.LayoutOf(stateOf([text.Of("", "a.k")], 800, 600)).Rows == 26 and view.LayoutOf(stateOf([text.Of("", "a.k")], 800, 600)).Code.Height == 518

-- A window 800 wide shows 91 columns, from 0 to 90: a click past the last one stays on it, and a drag is not kept there, so that the screen can follow it.
defn longLine(left)
  b = text.Of(Repeat(200, "x"), "a.k")
  b.Left = left
  stateOf([b], 800, 600)
end
isClickPastLastColumn() = view.ClickAt(799, 40, longLine(0)) == {Line: 1, Column: 90}
isClickPastLastColumnScrolled() = view.ClickAt(799, 40, longLine(40)) == {Line: 1, Column: 130}
isClickOnLastColumn() = view.ClickAt(view.Gutter + 90 * 8, 40, longLine(0)) == {Line: 1, Column: 90}
isDragPastLastColumn() = view.PositionAt(799, 40, longLine(0)) == {Line: 1, Column: 92}
isClickWithNoColumns() = view.ClickAt(50, 40, stateOf([text.Of(Repeat(200, "x"), "a.k")], 60, 600)) == {Line: 1, Column: 0}
