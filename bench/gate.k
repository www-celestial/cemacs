-- The speed gate of Kemacs: a text of 20,000 lines in a real window of 1920 by 1080, without vsync.
-- Run from the root of kemacs: kepler run --allow read,ffi=SDL3,ffi=SDL3_ttf bench/gate.k
-- It prints the median and the worst of 300 passes for one typed character, and for one scrolled line, and the time to build the rope.
use rope
use sdl
use sys
use ui
use color
use text
use view

-- The number of passes measured for each goal.
passes = 300
-- The number of lines of the text of the gate.
wantedLines = 20000
-- The folder of the files that make the text, read from the root of kemacs.
stdFolder = "../kepler/src/std"

-- The text of every file of the Kepler std, one after the other.
defn stdText()
  names = Filter(n -> EndsWith(".k", n), sys.List(stdFolder)?)
  Ok(Join("\n", Map(n -> sys.Read("$stdFolder/$n")?, names)))
end

-- The text of the std read four times, as a file of about 22,000 lines would be read.
defn readFourTimes()
  Ok(Join("\n", Map(n -> stdText()?, Range(1, 4))))
end

-- The text with wantedLines lines: the std, repeated until it is long enough, and cut.
defn longText(words)
  once = Lines(words)
  copies = Div(wantedLines, Len(once)) + 1
  Join("\n", Take(wantedLines, Flatten(Map(n -> once, Range(1, copies)))))
end

defn opened()
  first = sdl.Open("Kemacs speed gate", 1920, 1080, "fonts/AdwaitaSans-Regular.ttf", size = 13, vsync = false, light = true)?
  second = sdl.AddFont("strong", "fonts/NotoSans-Medium.ttf", 13, first, light = true)?
  sdl.AddFont("code", "fonts/JetBrainsMono-Regular.ttf", 13, second)
end

-- The state: a buffer with its cursor at line, column 0.
defn stateAt(words, line, look, cell)
  b = text.Of(words, "std.k")
  b.Cursor = {Line: line, Column: 0}
  view.Start([b], look, cell, 1920, 1080)
end

-- Shows the state of a pass and times its three parts in milliseconds: follow, view and frame.
defn shown(state, window)
  t0 = sys.Now()
  s = view.FollowState(state)
  t1 = sys.Now()
  commands = view.View(s)
  t2 = sys.Now()
  w = sdl.Frame(commands, window)
  t3 = sys.Now()
  {State: s, Window: w, Parts: [(t1 - t0) * 1000.0, (t2 - t1) * 1000.0, (t3 - t2) * 1000.0]}
end

-- One typed character: insert, forget the colors from that line, then follow, view and frame.
defn typed(state, window)
  b = state.Buffers[1]
  at = rope.LineStart(b.Cursor.Line, b.Rope) + b.Cursor.Column
  b.Rope = rope.Insert(at, "x", b.Rope)
  b.Cursor = {Line: b.Cursor.Line, Column: b.Cursor.Column + 1}
  b.Version = b.Version + 1
  b.Colors = color.ForgetFrom(b.Cursor.Line, b.Colors)
  s = state
  s.Buffers[1] = b
  shown(s, window)
end

-- One scrolled line: the screen moves down one line, and the cursor with it.
defn scrolled(state, window)
  b = state.Buffers[1]
  b.Cursor = {Line: b.Cursor.Line + 1, Column: 0}
  b.Top = b.Top + 1
  s = state
  s.Buffers[1] = b
  shown(s, window)
end

-- The time of each pass in milliseconds, and of its parts.
defn measure(step, state, window)
  s = state
  w = window
  times = []
  parts = []
  for n in 1:passes
    start = sys.Now()
    r = step(s, w)
    s = r.State
    w = r.Window
    times = Append((sys.Now() - start) * 1000.0, times)
    parts = Append(r.Parts, parts)
  end
  {Times: times, Parts: parts, Window: w}
end

-- A number with one decimal.
round1(x) = Floor(x * 10.0) / 10.0

-- The middle value of the times.
medianOf(times) = Sort(times)[Div(Len(times), 2)]

-- Prints the median and the worst pass, and the median of follow, view and frame.
defn report(name, run)
  median = medianOf(run.Times)
  splitUp = Map(k -> round1(medianOf(Map(p -> p[k], run.Parts))), [1, 2, 3])
  Print("$name: median $(round1(median)) ms, worst $(round1(Last(Sort(run.Times)))) ms; medians of the parts: follow $(splitUp[1]) ms, view $(splitUp[2]) ms, frame $(splitUp[3]) ms")
end

-- The word that tells whether a goal is met.
verdict(met) = if met "ok" else "FAIL" end

-- A real opening, end to end: read the files, make the buffer, follow the cursor, build the first frame and show it. Gives the time in milliseconds.
defn opening(look, cell, window)
  start = sys.Now()
  words = readFourTimes()?
  state = view.Start([text.Of(words, "std.k")], look, cell, 1920, 1080)
  state = view.FollowState(state)
  sdl.Frame(view.View(state), window)
  Ok((sys.Now() - start) * 1000.0)
end

defn main()
  words = longText(stdText()?)
  window = opened()?
  measured = sdl.Measure(window)
  look = ui.Look(ui.Dark, measured.Width, measured.Height)
  cell = {Width: look.Width("M", "code"), Height: sdl.TextSize("Ag", window, font = "code").Height + view.LineGap}
  Print("text: $(wantedLines) lines, cell $(cell.Width) x $(cell.Height)")
  start = sys.Now()
  whole = rope.Of(words)
  Print("rope.of on the whole text: $(round1((sys.Now() - start) * 1000.0)) ms ($(rope.LineCount(whole)) lines)")
  openMs = opening(look, cell, window)?
  state = stateAt(words, 19000, look, cell)
  start = sys.Now()
  state = view.FollowState(state)
  jumpMs = (sys.Now() - start) * 1000.0
  window = sdl.Frame(view.View(state), window)
  typing = measure(typed, state, window)
  scrolling = measure(scrolled, state, typing.Window)
  report("one typed character at line 19,000", typing)
  report("one scrolled line", scrolling)
  Print("jump to line 19,000, colors read from the start: $(round1(jumpMs)) ms")
  key = medianOf(typing.Times)
  scroll = medianOf(scrolling.Times)
  Print("one key under 16 ms at the median: $(verdict(key < 16.0)) ($(round1(key)) ms)")
  Print("scrolling at 60 per second or more: $(verdict(1000.0 / scroll >= 60.0)) ($(Floor(1000.0 / scroll)) per second)")
  Print("opening under 300 ms: $(verdict(openMs < 300.0)) ($(round1(openMs)) ms)")
  sdl.Close(scrolling.Window)
  Ok(missing)
end

Print(main())
